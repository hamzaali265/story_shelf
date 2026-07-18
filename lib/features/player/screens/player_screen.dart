import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../bookmarks/widgets/add_bookmark_dialog.dart';
import '../../bookmarks/widgets/bookmarks_sheet.dart';
import '../../chapters/widgets/chapters_sheet.dart';
import '../providers/player_provider.dart';
import '../widgets/scrubber_bar.dart';
import '../widgets/sleep_timer_dialog.dart';
import '../widgets/speed_selector_dialog.dart';

class PlayerScreen extends ConsumerWidget {
  final String? heroTag;
  const PlayerScreen({super.key, this.heroTag});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final book = playerState.currentBook;

    if (book == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No book selected')),
      );
    }

    final dominantColor = playerState.dominantColor ?? AppTheme.primaryAccent;
    final isPlaying = playerState.isPlaying;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              dominantColor.withValues(alpha: 0.4),
              AppTheme.darkBackground,
              AppTheme.darkBackground,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 32,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        book.album ?? 'NOW PLAYING',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert_rounded),
                      onPressed: () {
                        // Options menu
                      },
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Cover Art
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: dominantColor.withValues(alpha: 0.4),
                          blurRadius: 30,
                          spreadRadius: 2,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Hero(
                        tag: heroTag ?? 'hero_player_${book.id}',
                        child: _buildCover(book.coverPath, book.title),
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Title and Author
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    Text(
                      book.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      book.author,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Chapter Title Badge
                    GestureDetector(
                      onTap: () {
                        _showChaptersSheet(context, ref);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.darkCard.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.format_list_bulleted_rounded,
                              size: 14,
                              color: AppTheme.secondaryAccent,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                playerState.currentChapter?.title ??
                                    'Chapter 1',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.secondaryAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: AppTheme.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Scrubber
              ScrubberBar(
                positionSeconds: playerState.positionSeconds,
                durationSeconds: book.durationSeconds,
                onSeek: (val) {
                  ref.read(playerProvider.notifier).seek(val);
                },
              ),

              const SizedBox(height: 8),

              // Main Playback Controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded),
                      iconSize: 36,
                      onPressed: () {
                        ref.read(playerProvider.notifier).previousChapter();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.replay_10_rounded),
                      iconSize: 36,
                      onPressed: () {
                        ref.read(playerProvider.notifier).skipBackward();
                      },
                    ),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dominantColor,
                        boxShadow: [
                          BoxShadow(
                            color: dominantColor.withOpacity(0.6),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        iconSize: 48,
                        color: Colors.white,
                        onPressed: () {
                          ref.read(playerProvider.notifier).togglePlayPause();
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.forward_30_rounded),
                      iconSize: 36,
                      onPressed: () {
                        ref.read(playerProvider.notifier).skipForward();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded),
                      iconSize: 36,
                      onPressed: () {
                        ref.read(playerProvider.notifier).nextChapter();
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Bottom Action Bar: Speed, Sleep Timer, Bookmarks, Chapters
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Speed Chip
                    ActionChip(
                      avatar: const Icon(Icons.speed_rounded, size: 16),
                      label: Text('${playerState.speed}x'),
                      backgroundColor: AppTheme.darkCard,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => SpeedSelectorDialog(
                            currentSpeed: playerState.speed,
                            onSpeedSelected: (speed) {
                              ref.read(playerProvider.notifier).setSpeed(speed);
                            },
                          ),
                        );
                      },
                    ),

                    // Sleep Timer
                    Stack(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.bedtime_rounded,
                            color: playerState.sleepTimerText != null
                                ? AppTheme.secondaryAccent
                                : AppTheme.textSecondary,
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => SleepTimerDialog(
                                activeTimerText: playerState.sleepTimerText,
                                onSelectTimerMinutes: (m) {
                                  ref
                                      .read(playerProvider.notifier)
                                      .setSleepTimerMinutes(m);
                                },
                                onSelectEndOfChapter: () {
                                  ref
                                      .read(playerProvider.notifier)
                                      .setSleepTimerEndOfChapter();
                                },
                                onCancelTimer: () {
                                  ref
                                      .read(playerProvider.notifier)
                                      .cancelSleepTimer();
                                },
                              ),
                            );
                          },
                        ),
                        if (playerState.sleepTimerText != null)
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.secondaryAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Bookmark Button
                    IconButton(
                      icon: const Icon(Icons.bookmark_add_rounded),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AddBookmarkDialog(
                            positionSeconds: playerState.positionSeconds,
                            chapterTitle:
                                playerState.currentChapter?.title ??
                                'Chapter 1',
                            onSave: (note) {
                              ref.read(playerProvider.notifier);
                              // call bookmark save
                            },
                          ),
                        );
                      },
                    ),

                    // Bookmarks List
                    IconButton(
                      icon: const Icon(Icons.bookmark_border_rounded),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => const BookmarksSheet(),
                        );
                      },
                    ),

                    // Chapters List
                    IconButton(
                      icon: const Icon(Icons.format_list_bulleted_rounded),
                      onPressed: () {
                        _showChaptersSheet(context, ref);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChaptersSheet(BuildContext context, WidgetRef ref) {
    final playerState = ref.read(playerProvider);
    final book = playerState.currentBook;
    if (book == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChaptersSheet(
        chapters: book.chapters,
        currentChapter: playerState.currentChapter,
        onChapterSelect: (ch) {
          ref.read(playerProvider.notifier).jumpToChapter(ch);
        },
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
    final letter = title.isNotEmpty ? title[0].toUpperCase() : 'B';
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryAccent, AppTheme.secondaryAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
