import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import 'dart:io';
import '../../../core/database/hive_database.dart';
import '../../../core/models/book_model.dart';
import '../../../core/models/chapter_model.dart';
import '../../../core/models/playback_state_model.dart';
import '../../../core/native_bridge/mediastore_service.dart';
import '../../../core/services/audiobook_audio_handler.dart';
import '../../library/providers/library_provider.dart';
import '../../settings/providers/settings_provider.dart';

final audioHandlerProvider = Provider<AudiobookAudioHandler>((ref) {
  return AudiobookAudioHandler();
});

final dynamicAccentProvider = StateProvider<Color?>((ref) => null);

class PlayerState {
  final Book? currentBook;
  final double positionSeconds;
  final bool isPlaying;
  final bool isLoading;
  final double speed;
  final Chapter? currentChapter;
  final String? sleepTimerText;
  final Color? dominantColor;

  PlayerState({
    this.currentBook,
    this.positionSeconds = 0.0,
    this.isPlaying = false,
    this.isLoading = false,
    this.speed = 1.0,
    this.currentChapter,
    this.sleepTimerText,
    this.dominantColor,
  });

  PlayerState copyWith({
    Book? currentBook,
    double? positionSeconds,
    bool? isPlaying,
    bool? isLoading,
    double? speed,
    Chapter? currentChapter,
    String? sleepTimerText,
    Color? dominantColor,
  }) {
    return PlayerState(
      currentBook: currentBook ?? this.currentBook,
      positionSeconds: positionSeconds ?? this.positionSeconds,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      speed: speed ?? this.speed,
      currentChapter: currentChapter ?? this.currentChapter,
      sleepTimerText: sleepTimerText ?? this.sleepTimerText,
      dominantColor: dominantColor ?? this.dominantColor,
    );
  }
}

class PlayerNotifier extends StateNotifier<PlayerState> {
  final Ref ref;
  final AudiobookAudioHandler _handler;
  StreamSubscription? _positionSub;
  StreamSubscription? _playbackStateSub;
  Timer? _sleepTimerCheckTimer;

  PlayerNotifier(this.ref, this._handler) : super(PlayerState()) {
    _listenToHandler();
  }

  void _listenToHandler() {
    _positionSub = _handler.positionStream.listen((pos) {
      final currentBook = state.currentBook;
      if (currentBook != null) {
        final posSec = pos.inSeconds.toDouble();
        final chapter = _handler.getCurrentChapter(posSec);
        state = state.copyWith(
          positionSeconds: posSec,
          currentChapter: chapter,
        );
        _persistProgress();
      }
    });

    _playbackStateSub = _handler.playbackState.listen((ps) {
      state = state.copyWith(
        isPlaying: ps.playing,
        speed: ps.speed,
        isLoading: false,
      );
      _persistProgress();
    });

    _sleepTimerCheckTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final endTime = _handler.sleepTimerEndTime;
      if (endTime != null) {
        final remaining = endTime.difference(DateTime.now());
        if (remaining.isNegative) {
          state = state.copyWith(sleepTimerText: null);
        } else {
          final m = remaining.inMinutes;
          final s = remaining.inSeconds.remainder(60);
          state = state.copyWith(
            sleepTimerText:
                '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
          );
        }
      } else {
        if (state.sleepTimerText != null) {
          state = state.copyWith(sleepTimerText: null);
        }
      }
    });
  }

  Future<void> playBook(Book book, {double? seekToSeconds}) async {
    final settings = ref.read(settingsProvider);
    final storedState = HiveDatabase.getPlaybackState(book.id);
    final initialPos = seekToSeconds ?? storedState.positionSeconds;
    final initialSpeed = storedState.speed != 1.0
        ? storedState.speed
        : settings.defaultSpeed;

    final initialChapter = _handler.getCurrentChapter(initialPos) ??
        (book.chapters.isNotEmpty ? book.chapters.first : null);

    state = state.copyWith(
      currentBook: book,
      positionSeconds: initialPos,
      speed: initialSpeed,
      currentChapter: initialChapter,
      isLoading: true,
    );

    _extractPalette(book.coverPath);

    // Start audio playback IMMEDIATELY (< 50ms)
    await _handler.loadBook(
      book,
      startPositionSeconds: initialPos,
      speed: initialSpeed,
    );

    await _handler.play();
    state = state.copyWith(isLoading: false);

    // Asynchronously enrich metadata in background without blocking playback start
    if (book.chapters.isEmpty) {
      _enrichBookInBackground(book, initialPos);
    }
  }

  Future<void> _enrichBookInBackground(Book book, double currentPos) async {
    try {
      final enriched = await MediaStoreService.enrichBookMetadata(book);
      if (enriched.chapters.isNotEmpty && state.currentBook?.id == book.id) {
        await HiveDatabase.saveBook(enriched);
        final ch = _handler.getCurrentChapter(currentPos) ??
            (enriched.chapters.isNotEmpty ? enriched.chapters.first : null);
        state = state.copyWith(
          currentBook: enriched,
          currentChapter: ch,
        );
      }
    } catch (_) {}
  }

  Future<void> _extractPalette(String? coverPath) async {
    if (coverPath != null && File(coverPath).existsSync()) {
      try {
        final palette = await PaletteGenerator.fromImageProvider(
          FileImage(File(coverPath)),
          maximumColorCount: 16,
        );
        final color =
            palette.dominantColor?.color ?? palette.vibrantColor?.color;
        state = state.copyWith(dominantColor: color);
        ref.read(dynamicAccentProvider.notifier).state = color;
      } catch (_) {}
    } else {
      state = state.copyWith(dominantColor: null);
      ref.read(dynamicAccentProvider.notifier).state = null;
    }
  }

  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await _handler.pause();
    } else {
      await _handler.play();
    }
  }

  Future<void> seek(double positionSeconds) async {
    final duration = state.currentBook?.durationSeconds ?? 0;
    final clamped = positionSeconds.clamp(
      0.0,
      duration > 0 ? duration : double.infinity,
    );
    await _handler.seek(Duration(seconds: clamped.round()));
    state = state.copyWith(positionSeconds: clamped);
    _persistProgress();
  }

  Future<void> skipForward() async {
    final skipSec = ref.read(settingsProvider).skipForwardSeconds;
    await seek(state.positionSeconds + skipSec);
  }

  Future<void> skipBackward() async {
    final skipSec = ref.read(settingsProvider).skipBackwardSeconds;
    await seek(state.positionSeconds - skipSec);
  }

  Future<void> nextChapter() async {
    await _handler.skipToNext();
  }

  Future<void> previousChapter() async {
    await _handler.skipToPrevious();
  }

  Future<void> jumpToChapter(Chapter chapter) async {
    await seek(chapter.startSeconds);
  }

  Future<void> setSpeed(double speed) async {
    await _handler.setSpeed(speed);
    state = state.copyWith(speed: speed);
    _persistProgress();
  }

  void setSleepTimerMinutes(int minutes) {
    _handler.setSleepTimerMinutes(minutes);
  }

  void setSleepTimerEndOfChapter() {
    _handler.setSleepTimerEndOfChapter();
    state = state.copyWith(sleepTimerText: 'End of Chapter');
  }

  void cancelSleepTimer() {
    _handler.cancelSleepTimer();
    state = state.copyWith(sleepTimerText: null);
  }

  void _persistProgress() {
    final book = state.currentBook;
    if (book == null) return;

    final chIndex = state.currentChapter?.index ?? 0;
    final isFinished =
        (book.durationSeconds > 0 &&
        state.positionSeconds >= book.durationSeconds - 5);

    final pbState = BookPlaybackState(
      bookId: book.id,
      positionSeconds: state.positionSeconds,
      currentChapterIndex: chIndex,
      speed: state.speed,
      isFinished: isFinished,
      lastListened: DateTime.now(),
    );

    ref.read(libraryProvider.notifier).updatePlaybackState(pbState);
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _playbackStateSub?.cancel();
    _sleepTimerCheckTimer?.cancel();
    super.dispose();
  }
}

final playerProvider = StateNotifierProvider<PlayerNotifier, PlayerState>((
  ref,
) {
  final handler = ref.watch(audioHandlerProvider);
  return PlayerNotifier(ref, handler);
});
