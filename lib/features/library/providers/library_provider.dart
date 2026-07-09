import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/hive_database.dart';
import '../../../core/models/book_model.dart';
import '../../../core/models/playback_state_model.dart';
import '../../../core/native_bridge/mediastore_service.dart';

enum SortOption {
  recentlyAdded,
  recentlyPlayed,
  titleAZ,
  titleZA,
  author,
  duration,
}

enum FilterOption { all, inProgress, notStarted, finished }

class LibraryState {
  final List<Book> books;
  final Map<String, BookPlaybackState> playbackStates;
  final bool isScanning;
  final String searchQuery;
  final SortOption sortBy;
  final FilterOption filterBy;

  LibraryState({
    required this.books,
    required this.playbackStates,
    this.isScanning = false,
    this.searchQuery = '',
    this.sortBy = SortOption.recentlyPlayed,
    this.filterBy = FilterOption.all,
  });

  LibraryState copyWith({
    List<Book>? books,
    Map<String, BookPlaybackState>? playbackStates,
    bool? isScanning,
    String? searchQuery,
    SortOption? sortBy,
    FilterOption? filterBy,
  }) {
    return LibraryState(
      books: books ?? this.books,
      playbackStates: playbackStates ?? this.playbackStates,
      isScanning: isScanning ?? this.isScanning,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      filterBy: filterBy ?? this.filterBy,
    );
  }

  /// Get filtered and sorted list of books
  List<Book> get displayedBooks {
    var list = books.where((book) {
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchesTitle = book.title.toLowerCase().contains(query);
        final matchesAuthor = book.author.toLowerCase().contains(query);
        final matchesFile = book.filePath.toLowerCase().contains(query);
        if (!matchesTitle && !matchesAuthor && !matchesFile) return false;
      }

      final progress = playbackStates[book.id];
      final isFinished = progress?.isFinished ?? false;
      final pos = progress?.positionSeconds ?? 0.0;

      switch (filterBy) {
        case FilterOption.inProgress:
          return pos > 0 && !isFinished;
        case FilterOption.notStarted:
          return pos == 0 && !isFinished;
        case FilterOption.finished:
          return isFinished;
        case FilterOption.all:
          return true;
      }
    }).toList();

    switch (sortBy) {
      case SortOption.recentlyAdded:
        list.sort((a, b) => b.addedDate.compareTo(a.addedDate));
        break;
      case SortOption.recentlyPlayed:
        list.sort((a, b) {
          final timeA =
              playbackStates[a.id]?.lastListened ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final timeB =
              playbackStates[b.id]?.lastListened ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return timeB.compareTo(timeA);
        });
        break;
      case SortOption.titleAZ:
        list.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case SortOption.titleZA:
        list.sort(
          (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()),
        );
        break;
      case SortOption.author:
        list.sort(
          (a, b) => a.author.toLowerCase().compareTo(b.author.toLowerCase()),
        );
        break;
      case SortOption.duration:
        list.sort((a, b) => b.durationSeconds.compareTo(a.durationSeconds));
        break;
    }

    return list;
  }

  /// Get recently listened books for "Continue Listening" section
  List<Book> get recentlyPlayedBooks {
    final list = books.where((b) {
      final p = playbackStates[b.id];
      return p != null && p.lastListened.millisecondsSinceEpoch > 0;
    }).toList();
    list.sort((a, b) {
      final timeA =
          playbackStates[a.id]?.lastListened ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final timeB =
          playbackStates[b.id]?.lastListened ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return timeB.compareTo(timeA);
    });
    return list;
  }
}

class LibraryNotifier extends StateNotifier<LibraryState> {
  LibraryNotifier()
    : super(
        LibraryState(
          books: HiveDatabase.getAllBooks(),
          playbackStates: HiveDatabase.getAllPlaybackStates(),
        ),
      );

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSortOption(SortOption option) {
    state = state.copyWith(sortBy: option);
  }

  void setFilterOption(FilterOption option) {
    state = state.copyWith(filterBy: option);
  }

  void updatePlaybackState(BookPlaybackState playbackState) {
    final updatedStates = Map<String, BookPlaybackState>.from(
      state.playbackStates,
    );
    updatedStates[playbackState.bookId] = playbackState;
    state = state.copyWith(playbackStates: updatedStates);
    HiveDatabase.savePlaybackState(playbackState);
  }

  Future<void> scanDevice() async {
    state = state.copyWith(isScanning: true);
    try {
      await MediaStoreService.requestStoragePermissions();
      final scannedBooks = await MediaStoreService.scanDeviceAudiobooks();

      if (scannedBooks.isNotEmpty) {
        await HiveDatabase.saveBooks(scannedBooks);

        state = state.copyWith(
          books: scannedBooks,
          playbackStates: HiveDatabase.getAllPlaybackStates(),
          isScanning: false,
        );

        // Run background enrichment for cover art and chapters asynchronously
        _enrichBooksInBackground(scannedBooks);
      } else {
        state = state.copyWith(books: [], isScanning: false);
      }
    } catch (_) {
      state = state.copyWith(isScanning: false);
    }
  }

  Future<void> _enrichBooksInBackground(List<Book> booksToEnrich) async {
    final targets = booksToEnrich.where((b) => b.coverPath == null || b.chapters.isEmpty).toList();
    if (targets.isEmpty) return;

    final batchSize = 3;
    for (var i = 0; i < targets.length; i += batchSize) {
      final chunk = targets.sublist(i, (i + batchSize > targets.length) ? targets.length : i + batchSize);
      final enrichedChunk = await Future.wait(chunk.map((b) => MediaStoreService.enrichBookMetadata(b)));

      var hasChanges = false;
      final updatedMap = {for (final b in state.books) b.id: b};

      for (final enriched in enrichedChunk) {
        final original = updatedMap[enriched.id];
        if (original != null && (original.coverPath != enriched.coverPath || original.chapters.length != enriched.chapters.length)) {
          updatedMap[enriched.id] = enriched;
          await HiveDatabase.saveBook(enriched);
          hasChanges = true;
        }
      }

      if (hasChanges) {
        state = state.copyWith(books: updatedMap.values.toList());
      }
    }
  }

  void reloadFromDatabase() {
    state = state.copyWith(
      books: HiveDatabase.getAllBooks(),
      playbackStates: HiveDatabase.getAllPlaybackStates(),
    );
  }
}

final libraryProvider = StateNotifierProvider<LibraryNotifier, LibraryState>((
  ref,
) {
  return LibraryNotifier();
});
