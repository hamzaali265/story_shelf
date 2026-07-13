import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/models/book_model.dart';
import '../../../core/models/playback_state_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/m4b_parser.dart';
import '../../../core/utils/time_formatter.dart';

class ContinueListeningCard extends StatelessWidget {
  final Book book;
  final BookPlaybackState? playbackState;
  final bool isLoading;
  final bool isPlaying;
  final VoidCallback onResumeTap;

  const ContinueListeningCard({
    super.key,
    required this.book,
    this.playbackState,
    this.isLoading = false,
    this.isPlaying = false,
    required this.onResumeTap,
  });

  @override
  Widget build(BuildContext context) {
    final pos = playbackState?.positionSeconds ?? 0.0;
    final total = book.durationSeconds;
    final progress = total > 0 ? (pos / total).clamp(0.0, 1.0) : 0.0;
    final remainingSec = (total - pos).clamp(0.0, total);

    String currentChapterName = 'Chapter 1';
    if (book.chapters.isNotEmpty && playbackState != null) {
      final chIndex = playbackState!.currentChapterIndex;
      if (chIndex > 0 && chIndex <= book.chapters.length) {
        currentChapterName = M4bParser.sanitizeChapterTitle(book.chapters[chIndex - 1].title, chIndex);
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard,
            AppTheme.primaryAccent.withValues(alpha: 0.28),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppTheme.primaryAccent.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryAccent.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onResumeTap,
          splashColor: AppTheme.primaryAccent.withValues(alpha: 0.2),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.play_circle_fill,
                          color: AppTheme.secondaryAccent,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'CONTINUE LISTENING',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: AppTheme.secondaryAccent,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${TimeFormatter.formatDuration(remainingSec)} left',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    // Cover artwork with Circular Progress Ring
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 74,
                          height: 74,
                          child: CircularProgressIndicator(
                            value: progress > 0 ? progress : 0.02,
                            strokeWidth: 3.5,
                            backgroundColor: Colors.white10,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.secondaryAccent,
                            ),
                          ),
                        ),
                        ClipOval(
                          child: SizedBox(
                            width: 64,
                            height: 64,
                            child: Hero(
                              tag: 'cover_continue_${book.id}',
                              child: _buildCover(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            book.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryAccent.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              currentChapterName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.secondaryAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.primaryAccent,
                            AppTheme.secondaryAccent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryAccent.withValues(
                              alpha: 0.5,
                            ),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Icon(
                                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: isPlaying ? 28 : 32,
                              ),
                        onPressed: onResumeTap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCover() {
    if (book.coverPath != null && File(book.coverPath!).existsSync()) {
      return Image.file(
        File(book.coverPath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    final firstLetter = book.title.isNotEmpty
        ? book.title[0].toUpperCase()
        : 'B';
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryAccent.withValues(alpha: 0.8),
            AppTheme.secondaryAccent.withValues(alpha: 0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          firstLetter,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
