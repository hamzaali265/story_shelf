import 'package:flutter_test/flutter_test.dart';
import 'package:story_shelf/core/models/book_model.dart';
import 'package:story_shelf/core/models/chapter_model.dart';
import 'package:story_shelf/core/models/playback_state_model.dart';
import 'package:story_shelf/core/utils/time_formatter.dart';

void main() {
  group('StoryShelf Models & Utilities Tests', () {
    test('Chapter duration calculations', () {
      final ch = Chapter(
        index: 1,
        title: 'Chapter 1: The Beginning',
        startSeconds: 0.0,
        endSeconds: 300.0,
      );

      expect(ch.durationSeconds, 300.0);
      expect(ch.toJson()['title'], 'Chapter 1: The Beginning');
    });

    test('Book JSON serialization & fallback values', () {
      final book = Book(
        id: 'test_123',
        filePath: '/storage/emulated/0/Audiobooks/test.m4b',
        title: 'Test Audiobook',
        author: 'John Doe',
        durationSeconds: 3600.0,
        fileSizeBytes: 10485760,
        lastModified: 1700000000,
        chapters: [
          Chapter(index: 1, title: 'Intro', startSeconds: 0.0, endSeconds: 600.0),
          Chapter(index: 2, title: 'Main', startSeconds: 600.0, endSeconds: 3600.0),
        ],
        addedDate: DateTime.parse('2026-01-01T00:00:00.000Z'),
      );

      final json = book.toJson();
      final restored = Book.fromJson(json);

      expect(restored.id, 'test_123');
      expect(restored.title, 'Test Audiobook');
      expect(restored.author, 'John Doe');
      expect(restored.chapters.length, 2);
    });

    test('TimeFormatter formatting tests', () {
      expect(TimeFormatter.formatDuration(3665), '01:01:05');
      expect(TimeFormatter.formatDuration(125), '02:05');
      expect(TimeFormatter.formatRemainingTime(3600, 600), '50:00 left');
      expect(TimeFormatter.formatFileSize(1048576), '1.0 MB');
    });

    test('BookPlaybackState state tracking', () {
      final state = BookPlaybackState.initial('book_1');
      expect(state.positionSeconds, 0.0);
      expect(state.speed, 1.0);
      expect(state.isFinished, false);

      final updated = state.copyWith(
        positionSeconds: 3500.0,
        isFinished: true,
      );

      expect(updated.positionSeconds, 3500.0);
      expect(updated.isFinished, true);
    });
  });
}
