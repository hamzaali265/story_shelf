import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/book_model.dart';
import '../utils/m4b_parser.dart';

class MediaStoreService {
  static const MethodChannel _channel = MethodChannel(
    'com.storyshelf.app/mediastore',
  );

  /// Request appropriate storage/audio permissions for Android
  static Future<bool> requestStoragePermissions() async {
    if (!Platform.isAndroid) return true;

    try {
      final statuses = await [
        Permission.audio,
        Permission.storage,
        Permission.manageExternalStorage,
        Permission.notification,
      ].request();
      debugPrint('StoryShelfScan: Permission statuses = $statuses');
    } catch (e) {
      debugPrint('StoryShelfScan: Permission request error = $e');
    }

    return true;
  }

  /// Instant Pass: Perform fast MediaStore query for audiobooks without blocking
  static Future<List<Book>> scanDeviceAudiobooks() async {
    final books = <Book>[];
    debugPrint('StoryShelfScan: Fast scanDeviceAudiobooks initiated');

    if (Platform.isAndroid) {
      try {
        final List<dynamic>? rawList = await _channel.invokeMethod(
          'scanAudiobooks',
        );
        debugPrint(
          'StoryShelfScan: MethodChannel returned ${rawList?.length ?? 0} raw items',
        );

        if (rawList != null) {
          for (final item in rawList) {
            final map = Map<String, dynamic>.from(item as Map);
            final path = map['path'] as String? ?? '';
            if (path.isEmpty) continue;

            final rawDurationMillis =
                (map['duration'] as num?)?.toDouble() ?? 0.0;
            final durationSeconds = rawDurationMillis / 1000.0;

            final filename = path.contains('/')
                ? path.substring(path.lastIndexOf('/') + 1)
                : path;
            final nameWithoutExt = filename.contains('.')
                ? filename.substring(0, filename.lastIndexOf('.'))
                : filename;

            final rawTitle = map['title'] as String?;
            final title = (rawTitle != null && rawTitle.isNotEmpty)
                ? rawTitle
                : nameWithoutExt;
            final rawArtist = map['artist'] as String?;
            final author =
                (rawArtist != null &&
                    rawArtist.isNotEmpty &&
                    rawArtist != '<unknown>')
                ? rawArtist
                : 'Unknown Author';

            final sizeBytes = (map['size'] as num?)?.toInt() ?? 0;
            final lastMod =
                (map['dateModified'] as num?)?.toInt() ??
                (DateTime.now().millisecondsSinceEpoch ~/ 1000);

            books.add(
              Book(
                id: map['id']?.toString() ?? path.hashCode.toString(),
                filePath: path,
                title: title.isNotEmpty ? title : nameWithoutExt,
                author: author,
                album: map['album'] as String?,
                durationSeconds: durationSeconds,
                fileSizeBytes: sizeBytes,
                lastModified: lastMod,
                coverPath: null,
                chapters: [],
                addedDate: DateTime.now(),
              ),
            );
          }
        }
      } catch (e, stack) {
        debugPrint(
          'StoryShelfScan: Error during scanDeviceAudiobooks: $e\n$stack',
        );
      }
    }

    debugPrint(
      'StoryShelfScan: Returning ${books.length} initial Book objects',
    );
    return books;
  }

  /// Background Pass: Asynchronously extract embedded M4B chapters and cover art for a book
  static Future<Book> enrichBookMetadata(Book book) async {
    try {
      var durationSec = book.durationSeconds;
      final m4bMeta = await M4bParser.parseFileInIsolate(
        book.filePath,
        durationSec,
      );

      if (durationSec <= 0 && m4bMeta.chapters.isNotEmpty) {
        durationSec = m4bMeta.chapters.last.endSeconds;
      }

      String? coverPath;
      try {
        coverPath = await _channel.invokeMethod<String>('extractCoverArt', {
          'path': book.filePath,
        });
      } catch (_) {}

      final title = (m4bMeta.title != null && m4bMeta.title!.isNotEmpty)
          ? m4bMeta.title!
          : book.title;
      final author = (m4bMeta.author != null && m4bMeta.author!.isNotEmpty)
          ? m4bMeta.author!
          : book.author;

      return book.copyWith(
        title: title,
        author: author,
        album: m4bMeta.album ?? book.album,
        durationSeconds: durationSec,
        coverPath: coverPath,
        chapters: m4bMeta.chapters,
      );
    } catch (_) {
      return book;
    }
  }
}
