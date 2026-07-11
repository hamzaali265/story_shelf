import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/time_formatter.dart';
import '../providers/bookmarks_provider.dart';
import '../../player/providers/player_provider.dart';

class BookmarksSheet extends ConsumerWidget {
  const BookmarksSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(bookmarksProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bookmark_rounded, color: AppTheme.secondaryAccent),
                    const SizedBox(width: 10),
                    Text(
                      'Bookmarks (${bookmarks.length})',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: bookmarks.isEmpty
                ? const Center(
                    child: Text(
                      'No bookmarks created yet.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  )
                : ListView.builder(
                    itemCount: bookmarks.length,
                    itemBuilder: (context, index) {
                      final bm = bookmarks[index];
                      return Dismissible(
                        key: Key(bm.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.redAccent,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          ref.read(bookmarksProvider.notifier).deleteBookmark(bm.id);
                        },
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              TimeFormatter.formatDuration(bm.positionSeconds),
                              style: const TextStyle(
                                color: AppTheme.secondaryAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          title: Text(
                            bm.chapterTitle.isNotEmpty ? bm.chapterTitle : 'Bookmark',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: bm.note != null && bm.note!.isNotEmpty
                              ? Text(
                                  bm.note!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                )
                              : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            onPressed: () {
                              ref.read(bookmarksProvider.notifier).deleteBookmark(bm.id);
                            },
                          ),
                          onTap: () {
                            ref.read(playerProvider.notifier).seek(bm.positionSeconds);
                            Navigator.of(context).pop();
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
