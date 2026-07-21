import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../library/providers/library_provider.dart';
import '../../library/widgets/book_card.dart';
import '../../player/providers/player_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref.read(libraryProvider.notifier).setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryProvider);
    final displayedBooks = libraryState.displayedBooks;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Search by title, author, filename...',
            hintStyle: const TextStyle(color: AppTheme.textSecondary),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
          ),
        ),
      ),
      body: displayedBooks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    _searchController.text.isEmpty
                        ? 'Type to search your library'
                        : 'No books match "${_searchController.text}"',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: displayedBooks.length,
              itemBuilder: (context, index) {
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
              },
            ),
    );
  }
}
