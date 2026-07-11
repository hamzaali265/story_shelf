import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/hive_database.dart';
import '../../../core/models/bookmark_model.dart';
import '../../player/providers/player_provider.dart';

class BookmarksNotifier extends StateNotifier<List<Bookmark>> {
  final Ref ref;

  BookmarksNotifier(this.ref) : super([]) {
    _loadBookmarksForCurrentBook();
  }

  void _loadBookmarksForCurrentBook() {
    final playerState = ref.read(playerProvider);
    final bookId = playerState.currentBook?.id;
    if (bookId != null) {
      state = HiveDatabase.getBookmarksForBook(bookId);
    } else {
      state = [];
    }
  }

  void refreshForBook(String bookId) {
    state = HiveDatabase.getBookmarksForBook(bookId);
  }

  Future<void> addBookmark({String? note}) async {
    final playerState = ref.read(playerProvider);
    final book = playerState.currentBook;
    if (book == null) return;

    final posSec = playerState.positionSeconds;
    final ch = playerState.currentChapter;

    final bookmark = Bookmark(
      id: '${book.id}_${DateTime.now().millisecondsSinceEpoch}',
      bookId: book.id,
      positionSeconds: posSec,
      chapterIndex: ch?.index ?? 0,
      chapterTitle: ch?.title ?? 'Chapter',
      note: note,
      createdAt: DateTime.now(),
    );

    await HiveDatabase.saveBookmark(bookmark);
    refreshForBook(book.id);
  }

  Future<void> deleteBookmark(String bookmarkId) async {
    await HiveDatabase.deleteBookmark(bookmarkId);
    final playerState = ref.read(playerProvider);
    if (playerState.currentBook != null) {
      refreshForBook(playerState.currentBook!.id);
    }
  }
}

final bookmarksProvider = StateNotifierProvider<BookmarksNotifier, List<Bookmark>>((ref) {
  return BookmarksNotifier(ref);
});
