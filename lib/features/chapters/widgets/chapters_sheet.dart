import 'package:flutter/material.dart';
import '../../../core/models/chapter_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/time_formatter.dart';

class ChaptersSheet extends StatelessWidget {
  final List<Chapter> chapters;
  final Chapter? currentChapter;
  final ValueChanged<Chapter> onChapterSelect;

  const ChaptersSheet({
    super.key,
    required this.chapters,
    this.currentChapter,
    required this.onChapterSelect,
  });

  @override
  Widget build(BuildContext context) {
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
                    const Icon(Icons.format_list_bulleted_rounded, color: AppTheme.secondaryAccent),
                    const SizedBox(width: 10),
                    Text(
                      'Chapters (${chapters.length})',
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
            child: chapters.isEmpty
                ? const Center(
                    child: Text(
                      'No embedded chapters found.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  )
                : ListView.builder(
                    itemCount: chapters.length,
                    itemBuilder: (context, index) {
                      final ch = chapters[index];
                      final isSelected = currentChapter?.index == ch.index;

                      return Container(
                        color: isSelected ? AppTheme.primaryAccent.withOpacity(0.15) : null,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isSelected ? AppTheme.primaryAccent : AppTheme.darkCard,
                            foregroundColor: isSelected ? Colors.white : AppTheme.textSecondary,
                            radius: 16,
                            child: Text(
                              '${ch.index}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            ch.title,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppTheme.secondaryAccent : AppTheme.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            TimeFormatter.formatDuration(ch.startSeconds),
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                          trailing: Text(
                            TimeFormatter.formatDuration(ch.durationSeconds),
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                          onTap: () {
                            onChapterSelect(ch);
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
