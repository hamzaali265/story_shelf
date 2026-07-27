import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/page_transitions.dart';
import '../providers/library_provider.dart';
import '../widgets/book_card.dart';
import '../widgets/continue_listening_card.dart';
import '../widgets/empty_library_view.dart';
import '../widgets/shimmer_loading.dart';
import '../../player/providers/player_provider.dart';
import '../../player/widgets/mini_player.dart';
import '../../search/screens/search_screen.dart';
import '../../settings/screens/settings_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    // Auto scan on launch if library is empty
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final libraryState = ref.read(libraryProvider);
      if (libraryState.books.isEmpty) {
        ref.read(libraryProvider.notifier).scanDevice();
      }
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryProvider);
    final displayedBooks = libraryState.displayedBooks;
    final recentlyPlayed = libraryState.recentlyPlayedBooks;
    final activeContinueBook = recentlyPlayed.isNotEmpty
        ? recentlyPlayed.first
        : null;

    if (libraryState.isScanning && libraryState.books.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.auto_stories_rounded, color: AppTheme.secondaryAccent),
              SizedBox(width: 10),
              Text('StoryShelf'),
            ],
          ),
        ),
        body: const ShimmerSkeletonLoading(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_stories_rounded, color: AppTheme.secondaryAccent),
            SizedBox(width: 10),
            Text('StoryShelf'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              Navigator.of(
                context,
              ).push(SmoothPageRoute(page: const SearchScreen()));
            },
          ),
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
            ),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          IconButton(
            icon: libraryState.isScanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync_rounded),
            onPressed: libraryState.isScanning
                ? null
                : () {
                    ref.read(libraryProvider.notifier).scanDevice();
                  },
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              Navigator.of(
                context,
              ).push(SmoothPageRoute(page: const SettingsScreen()));
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await ref.read(libraryProvider.notifier).scanDevice();
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // Greeting Header Banner
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      top: 12.0,
                      bottom: 4.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Ready to continue your story?',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Hero Continue Listening Card
                if (activeContinueBook != null &&
                    libraryState.filterBy == FilterOption.all)
                  Builder(
                    builder: (context) {
                      final playerState = ref.watch(playerProvider);
                      final isCurrentActive =
                          playerState.currentBook?.id == activeContinueBook.id;
                      final isBookLoading =
                          isCurrentActive && playerState.isLoading;
                      final isBookPlaying =
                          isCurrentActive && playerState.isPlaying;

                      return SliverToBoxAdapter(
                        child: ContinueListeningCard(
                          book: activeContinueBook,
                          playbackState: libraryState
                              .playbackStates[activeContinueBook.id],
                          isLoading: isBookLoading,
                          isPlaying: isBookPlaying,
                          onResumeTap: () {
                            if (isBookPlaying) {
                              ref
                                  .read(playerProvider.notifier)
                                  .togglePlayPause();
                            } else {
                              ref
                                  .read(playerProvider.notifier)
                                  .playBook(activeContinueBook);
                            }
                          },
                        ),
                      );
                    },
                  ),

                // Filter Chips & Sort Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip(
                                'All',
                                FilterOption.all,
                                libraryState.filterBy,
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                'In Progress',
                                FilterOption.inProgress,
                                libraryState.filterBy,
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                'Not Started',
                                FilterOption.notStarted,
                                libraryState.filterBy,
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                'Finished',
                                FilterOption.finished,
                                libraryState.filterBy,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${displayedBooks.length} ${displayedBooks.length == 1 ? 'AUDIOBOOK' : 'AUDIOBOOKS'}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondary,
                                letterSpacing: 1.0,
                              ),
                            ),
                            PopupMenuButton<SortOption>(
                              initialValue: libraryState.sortBy,
                              onSelected: (option) {
                                ref
                                    .read(libraryProvider.notifier)
                                    .setSortOption(option);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.sort_rounded,
                                      size: 18,
                                      color: AppTheme.secondaryAccent,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getSortLabel(libraryState.sortBy),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.secondaryAccent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: SortOption.recentlyPlayed,
                                  child: Text('Recently Played'),
                                ),
                                const PopupMenuItem(
                                  value: SortOption.recentlyAdded,
                                  child: Text('Recently Added'),
                                ),
                                const PopupMenuItem(
                                  value: SortOption.titleAZ,
                                  child: Text('Title (A-Z)'),
                                ),
                                const PopupMenuItem(
                                  value: SortOption.titleZA,
                                  child: Text('Title (Z-A)'),
                                ),
                                const PopupMenuItem(
                                  value: SortOption.author,
                                  child: Text('Author'),
                                ),
                                const PopupMenuItem(
                                  value: SortOption.duration,
                                  child: Text('Duration'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Library Items / Empty State
                if (displayedBooks.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyLibraryView(
                      isScanning: libraryState.isScanning,
                      onScanTap: () {
                        ref.read(libraryProvider.notifier).scanDevice();
                      },
                    ),
                  )
                else if (_isGridView)
                  SliverPadding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 8,
                      bottom: 90,
                    ),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.65,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final book = displayedBooks[index];
                        final pbState = libraryState.playbackStates[book.id];
                        return BookCard(
                          book: book,
                          playbackState: pbState,
                          isGridView: true,
                          onTap: () {
                            ref.read(playerProvider.notifier).playBook(book);
                          },
                        );
                      }, childCount: displayedBooks.length),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 8, bottom: 90),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final book = displayedBooks[index];
                        final pbState = libraryState.playbackStates[book.id];
                        return BookCard(
                          book: book,
                          playbackState: pbState,
                          isGridView: false,
                          onTap: () {
                            ref.read(playerProvider.notifier).playBook(book);
                          },
                        );
                      }, childCount: displayedBooks.length),
                    ),
                  ),
              ],
            ),
          ),

          // Mini Player overlay at bottom
          const Positioned(left: 0, right: 0, bottom: 0, child: MiniPlayer()),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    FilterOption option,
    FilterOption current,
  ) {
    final isSelected = option == current;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : AppTheme.textPrimary,
        ),
      ),
      selected: isSelected,
      selectedColor: AppTheme.primaryAccent,
      backgroundColor: AppTheme.darkCard,
      onSelected: (_) {
        ref.read(libraryProvider.notifier).setFilterOption(option);
      },
    );
  }

  String _getSortLabel(SortOption option) {
    switch (option) {
      case SortOption.recentlyAdded:
        return 'Recently Added';
      case SortOption.recentlyPlayed:
        return 'Recently Played';
      case SortOption.titleAZ:
        return 'Title A-Z';
      case SortOption.titleZA:
        return 'Title Z-A';
      case SortOption.author:
        return 'Author';
      case SortOption.duration:
        return 'Duration';
    }
  }
}
