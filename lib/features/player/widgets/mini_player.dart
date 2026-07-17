import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/page_transitions.dart';
import '../providers/player_provider.dart';
import '../screens/player_screen.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final book = playerState.currentBook;

    final isVisible = book != null;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      offset: isVisible ? Offset.zero : const Offset(0, 1.2),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isVisible ? 1.0 : 0.0,
        child: isVisible ? _buildMiniPlayerContent(context, ref, playerState, book) : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildMiniPlayerContent(
      BuildContext context, WidgetRef ref, dynamic playerState, dynamic book) {
    final pos = playerState.positionSeconds as double;
    final total = book.durationSeconds as double;
    final progress = total > 0 ? (pos / total).clamp(0.0, 1.0) : 0.0;
    final isPlaying = playerState.isPlaying as bool;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              SmoothPageRoute(
                page: PlayerScreen(heroTag: 'hero_mini_${book.id}'),
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 46,
                        height: 46,
                        child: Hero(
                          tag: 'hero_mini_${book.id}',
                          child: _buildCover(book.coverPath, book.title),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            playerState.currentChapter?.title ?? book.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.forward_30_rounded),
                      iconSize: 26,
                      onPressed: () {
                        ref.read(playerProvider.notifier).skipForward();
                      },
                    ),
                    IconButton(
                      icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
                      iconSize: 34,
                      color: AppTheme.primaryAccent,
                      onPressed: () {
                        ref.read(playerProvider.notifier).togglePlayPause();
                      },
                    ),
                  ],
                ),
              ),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryAccent),
                minHeight: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover(String? coverPath, String title) {
    if (coverPath != null && File(coverPath).existsSync()) {
      return Image.file(
        File(coverPath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(title),
      );
    }
    return _buildPlaceholder(title);
  }

  Widget _buildPlaceholder(String title) {
    final firstLetter = title.isNotEmpty ? title[0].toUpperCase() : 'B';
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
