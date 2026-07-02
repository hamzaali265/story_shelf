import 'package:hive_flutter/hive_flutter.dart';
import '../models/book_model.dart';
import '../models/bookmark_model.dart';
import '../models/playback_state_model.dart';
import '../models/app_settings_model.dart';

class HiveDatabase {
  static const String _booksBoxName = 'story_shelf_books';
  static const String _progressBoxName = 'story_shelf_progress';
  static const String _bookmarksBoxName = 'story_shelf_bookmarks';
  static const String _settingsBoxName = 'story_shelf_settings';

  static late Box _booksBox;
  static late Box _progressBox;
  static late Box _bookmarksBox;
  static late Box _settingsBox;

  static Future<void> init([String? path]) async {
    if (path != null) {
      Hive.init(path);
    } else {
      await Hive.initFlutter();
    }
    _booksBox = await Hive.openBox(_booksBoxName);
    _progressBox = await Hive.openBox(_progressBoxName);
    _bookmarksBox = await Hive.openBox(_bookmarksBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }

  // --- Books ---
  static List<Book> getAllBooks() {
    final books = <Book>[];
    for (final key in _booksBox.keys) {
      final jsonMap = Map<String, dynamic>.from(_booksBox.get(key) as Map);
      books.add(Book.fromJson(jsonMap));
    }
    return books;
  }

  static Future<void> saveBook(Book book) async {
    await _booksBox.put(book.id, book.toJson());
  }

  static Future<void> saveBooks(List<Book> books) async {
    final map = {for (final b in books) b.id: b.toJson()};
    await _booksBox.putAll(map);
  }

  static Future<void> deleteBook(String bookId) async {
    await _booksBox.delete(bookId);
    await _progressBox.delete(bookId);
  }

  // --- Playback State / Progress ---
  static BookPlaybackState getPlaybackState(String bookId) {
    final raw = _progressBox.get(bookId);
    if (raw == null) return BookPlaybackState.initial(bookId);
    final jsonMap = Map<String, dynamic>.from(raw as Map);
    return BookPlaybackState.fromJson(jsonMap);
  }

  static Future<void> savePlaybackState(BookPlaybackState state) async {
    await _progressBox.put(state.bookId, state.toJson());
  }

  static Map<String, BookPlaybackState> getAllPlaybackStates() {
    final map = <String, BookPlaybackState>{};
    for (final key in _progressBox.keys) {
      final jsonMap = Map<String, dynamic>.from(_progressBox.get(key) as Map);
      final state = BookPlaybackState.fromJson(jsonMap);
      map[state.bookId] = state;
    }
    return map;
  }

  // --- Bookmarks ---
  static List<Bookmark> getBookmarksForBook(String bookId) {
    final bookmarks = <Bookmark>[];
    for (final key in _bookmarksBox.keys) {
      final raw = _bookmarksBox.get(key);
      if (raw != null) {
        final jsonMap = Map<String, dynamic>.from(raw as Map);
        final bookmark = Bookmark.fromJson(jsonMap);
        if (bookmark.bookId == bookId) {
          bookmarks.add(bookmark);
        }
      }
    }
    bookmarks.sort((a, b) => a.positionSeconds.compareTo(b.positionSeconds));
    return bookmarks;
  }

  static Future<void> saveBookmark(Bookmark bookmark) async {
    await _bookmarksBox.put(bookmark.id, bookmark.toJson());
  }

  static Future<void> deleteBookmark(String bookmarkId) async {
    await _bookmarksBox.delete(bookmarkId);
  }

  // --- App Settings ---
  static AppSettings getSettings() {
    final raw = _settingsBox.get('settings');
    if (raw == null) return AppSettings();
    final jsonMap = Map<String, dynamic>.from(raw as Map);
    return AppSettings.fromJson(jsonMap);
  }

  static Future<void> saveSettings(AppSettings settings) async {
    await _settingsBox.put('settings', settings.toJson());
  }
}
