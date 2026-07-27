import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/book_model.dart';
import '../models/chapter_model.dart';

class AudiobookAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  Book? _currentBook;
  List<Chapter> _chapters = [];
  Timer? _sleepTimer;
  DateTime? _sleepTimerEndTime;
  bool _stopAtChapterEnd = false;
  
  Stream<Duration> get positionStream => _player.positionStream;

  AudiobookAudioHandler() {
    _initPlayerListeners();
  }

  AudioPlayer get player => _player;
  Book? get currentBook => _currentBook;
  List<Chapter> get chapters => _chapters;
  DateTime? get sleepTimerEndTime => _sleepTimerEndTime;

  String? _lastChapterTitle;

  void _initPlayerListeners() {
    // Relay playback events from just_audio into audio_service playbackState
    _player.playbackEventStream.listen(_broadcastState);

    _player.playerStateStream.listen((state) {
      _broadcastState(_player.playbackEvent);
      if (state.processingState == ProcessingState.completed) {
        pause();
      }
    });

    // Monitor position for dynamic chapter title notification and end-of-chapter sleep timer
    _player.positionStream.listen((pos) {
      final posSec = pos.inSeconds.toDouble();

      if (_currentBook != null && _chapters.isNotEmpty) {
        final currentChapter = getCurrentChapter(posSec);
        if (currentChapter != null && currentChapter.title != _lastChapterTitle) {
          _lastChapterTitle = currentChapter.title;
          _updateMediaItemWithChapter(currentChapter);
        }

        if (_stopAtChapterEnd && currentChapter != null) {
          final timeRemainingInChapter = currentChapter.endSeconds - posSec;
          if (timeRemainingInChapter <= 1.0) {
            pause();
            _stopAtChapterEnd = false;
            _sleepTimerEndTime = null;
          }
        }
      }
    });
  }

  void _updateMediaItemWithChapter(Chapter chapter) {
    if (_currentBook == null) return;
    final artUri = _currentBook!.coverPath != null ? Uri.file(_currentBook!.coverPath!) : null;
    mediaItem.add(MediaItem(
      id: _currentBook!.id,
      album: _currentBook!.album ?? 'StoryShelf',
      title: '${chapter.title} • ${_currentBook!.title}',
      artist: _currentBook!.author,
      duration: Duration(seconds: _currentBook!.durationSeconds.round()),
      artUri: artUri,
    ));
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.rewind,
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.fastForward,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 2, 4],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    ));
  }

  /// Load an audiobook for playback
  Future<void> loadBook(Book book, {double startPositionSeconds = 0.0, double speed = 1.0}) async {
    _currentBook = book;
    _chapters = book.chapters;

    final artUri = book.coverPath != null ? Uri.file(book.coverPath!) : null;

    mediaItem.add(MediaItem(
      id: book.id,
      album: book.album ?? 'StoryShelf',
      title: book.title,
      artist: book.author,
      duration: Duration(seconds: book.durationSeconds.round()),
      artUri: artUri,
    ));

    await _player.setFilePath(book.filePath);
    await _player.setSpeed(speed);
    if (startPositionSeconds > 0) {
      await _player.seek(Duration(seconds: startPositionSeconds.round()));
    }
  }

  Chapter? getCurrentChapter(double positionSeconds) {
    if (_chapters.isEmpty) return null;
    for (final ch in _chapters) {
      if (positionSeconds >= ch.startSeconds && positionSeconds <= ch.endSeconds) {
        return ch;
      }
    }
    return _chapters.first;
  }

  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  @override
  Future<void> skipToNext() async {
    // Jump to next chapter
    final currentPos = _player.position.inSeconds.toDouble();
    final currentCh = getCurrentChapter(currentPos);
    if (currentCh != null && currentCh.index < _chapters.length) {
      final nextCh = _chapters[currentCh.index]; // 0-indexed next
      await seek(Duration(seconds: nextCh.startSeconds.round()));
    } else {
      await fastForward();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    // Jump to previous chapter or beginning of chapter if past 5 seconds
    final currentPos = _player.position.inSeconds.toDouble();
    final currentCh = getCurrentChapter(currentPos);
    if (currentCh != null) {
      if (currentPos - currentCh.startSeconds > 5.0 || currentCh.index <= 1) {
        await seek(Duration(seconds: currentCh.startSeconds.round()));
      } else {
        final prevCh = _chapters[currentCh.index - 2];
        await seek(Duration(seconds: prevCh.startSeconds.round()));
      }
    } else {
      await rewind();
    }
  }

  @override
  Future<void> fastForward() async {
    final newPos = _player.position + const Duration(seconds: 30);
    await seek(newPos);
  }

  @override
  Future<void> rewind() async {
    final newPos = _player.position - const Duration(seconds: 10);
    await seek(newPos < Duration.zero ? Duration.zero : newPos);
  }

  void skipSeconds(int seconds) {
    final newPos = _player.position + Duration(seconds: seconds);
    seek(newPos < Duration.zero ? Duration.zero : newPos);
  }

  void setSleepTimerMinutes(int minutes) {
    _sleepTimer?.cancel();
    _stopAtChapterEnd = false;

    if (minutes <= 0) {
      _sleepTimerEndTime = null;
      return;
    }

    _sleepTimerEndTime = DateTime.now().add(Duration(minutes: minutes));
    _sleepTimer = Timer(Duration(minutes: minutes), () {
      pause();
      _sleepTimerEndTime = null;
    });
  }

  void setSleepTimerEndOfChapter() {
    _sleepTimer?.cancel();
    _stopAtChapterEnd = true;
    _sleepTimerEndTime = null;
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _stopAtChapterEnd = false;
    _sleepTimerEndTime = null;
  }
}
