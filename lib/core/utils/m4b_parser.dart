import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:convert';
import '../models/chapter_model.dart';

class M4bMetadata {
  final String? title;
  final String? author;
  final String? album;
  final List<Chapter> chapters;

  M4bMetadata({this.title, this.author, this.album, required this.chapters});
}

class M4bParser {
  /// Parse M4B binary file in a background Isolate off the UI main thread
  static Future<M4bMetadata> parseFileInIsolate(
    String filePath,
    double fileDurationSeconds,
  ) async {
    return Isolate.run(() => parseFile(filePath, fileDurationSeconds));
  }

  /// Parse M4B binary file to extract chapters and metadata
  static Future<M4bMetadata> parseFile(
    String filePath,
    double fileDurationSeconds,
  ) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return M4bMetadata(
        chapters: _generateDefaultChapters(fileDurationSeconds),
      );
    }

    RandomAccessFile? raf;
    try {
      raf = await file.open(mode: FileMode.read);
      final fileSize = await raf.length();
      final chapters = <Chapter>[];
      String? extractedTitle;
      String? extractedAuthor;
      String? extractedAlbum;

      // Scan MP4 atoms in top level and inner moov box
      await _scanAtoms(raf, 0, fileSize, (type, offset, size) async {
        if (type == 'moov') {
          await _scanAtoms(raf!, offset + 8, size - 8, (
            mType,
            mOffset,
            mSize,
          ) async {
            if (mType == 'udta') {
              await _scanAtoms(raf!, mOffset + 8, mSize - 8, (
                uType,
                uOffset,
                uSize,
              ) async {
                if (uType == 'chpl') {
                  final chplChapters = await _parseChplAtom(
                    raf!,
                    uOffset + 8,
                    uSize - 8,
                    fileDurationSeconds,
                  );
                  if (chplChapters.isNotEmpty) {
                    chapters.addAll(chplChapters);
                  }
                } else if (uType == 'meta') {
                  final metaHeaderSize = 12;
                  if (uSize > metaHeaderSize) {
                    await _scanAtoms(
                      raf!,
                      uOffset + metaHeaderSize,
                      uSize - metaHeaderSize,
                      (metaType, metaOffset, metaSize) async {
                        if (metaType == 'ilst') {
                          final metaData = await _parseIlstAtom(
                            raf!,
                            metaOffset + 8,
                            metaSize - 8,
                          );
                          extractedTitle = metaData['title'];
                          extractedAuthor = metaData['author'];
                          extractedAlbum = metaData['album'];
                        }
                      },
                    );
                  }
                }
              });
            } else if (mType == 'chpl') {
              final chplChapters = await _parseChplAtom(
                raf!,
                mOffset + 8,
                mSize - 8,
                fileDurationSeconds,
              );
              if (chplChapters.isNotEmpty && chapters.isEmpty) {
                chapters.addAll(chplChapters);
              }
            } else if (mType == 'trak') {
              // Check if this is a chapter text track
              final textChapters = await _parseTextTrack(
                raf!,
                mOffset + 8,
                mSize - 8,
                fileDurationSeconds,
              );
              if (textChapters.isNotEmpty && chapters.isEmpty) {
                chapters.addAll(textChapters);
              }
            }
          });
        }
      });

      if (chapters.isEmpty) {
        chapters.addAll(_generateDefaultChapters(fileDurationSeconds));
      }

      return M4bMetadata(
        title: extractedTitle,
        author: extractedAuthor,
        album: extractedAlbum,
        chapters: chapters,
      );
    } catch (e) {
      return M4bMetadata(
        chapters: _generateDefaultChapters(fileDurationSeconds),
      );
    } finally {
      await raf?.close();
    }
  }

  static Future<void> _scanAtoms(
    RandomAccessFile raf,
    int offset,
    int length,
    Future<void> Function(String type, int atomOffset, int atomSize) onAtom,
  ) async {
    var pos = offset;
    final end = offset + length;

    while (pos + 8 <= end) {
      await raf.setPosition(pos);
      final header = await raf.read(8);
      if (header.length < 8) break;

      final bd = ByteData.sublistView(header);
      var size = bd.getUint32(0);
      final type = utf8.decode(header.sublist(4, 8), allowMalformed: true);

      if (size == 1) {
        final extHeader = await raf.read(8);
        if (extHeader.length < 8) break;
        final bd64 = ByteData.sublistView(extHeader);
        size = bd64.getUint64(0).toInt();
      } else if (size == 0) {
        size = end - pos;
      }

      if (size < 8 || pos + size > end) break;

      await onAtom(type, pos, size);
      pos += size;
    }
  }

  /// Robust Nero 'chpl' atom parser with smart offset & count detection
  static Future<List<Chapter>> _parseChplAtom(
    RandomAccessFile raf,
    int offset,
    int size,
    double fileDurationSeconds,
  ) async {
    final chapters = <Chapter>[];
    try {
      await raf.setPosition(offset);
      final data = await raf.read(size.clamp(0, 2 * 1024 * 1024)); // cap to 2MB
      if (data.length < 9) return chapters;

      final bd = ByteData.sublistView(data);

      int count = 0;
      int pos = 8;

      // Try reading uint32 at offset 4, uint32 at offset 8, or uint8 at offset 8/4
      final c4 = bd.getUint32(4);
      final c8 = bd.getUint32(8);
      final c8b = bd.getUint8(8);
      final c4b = bd.getUint8(4);

      if (c4 > 0 && c4 < 1000) {
        count = c4;
        pos = 8;
      } else if (c8 > 0 && c8 < 1000) {
        count = c8;
        pos = 12;
      } else if (c8b > 0 && c8b < 250) {
        count = c8b;
        pos = 9;
      } else if (c4b > 0 && c4b < 250) {
        count = c4b;
        pos = 5;
      }

      if (count <= 0) return chapters;

      final rawTimestamps = <double>[];
      final titles = <String>[];

      for (var i = 0; i < count; i++) {
        if (pos + 9 > data.length) break;
        final timestamp100ns = bd.getUint64(pos);
        pos += 8;
        final titleLen = bd.getUint8(pos);
        pos += 1;

        if (pos + titleLen > data.length) break;
        final titleBytes = data.sublist(pos, pos + titleLen);
        pos += titleLen;

        final titleStr = utf8.decode(titleBytes, allowMalformed: true).trim();
        final startSec = timestamp100ns / 10000000.0;

        rawTimestamps.add(startSec);
        titles.add(sanitizeChapterTitle(titleStr, i + 1));
      }

      for (var i = 0; i < rawTimestamps.length; i++) {
        final startSec = rawTimestamps[i];
        final endSec = (i + 1 < rawTimestamps.length)
            ? rawTimestamps[i + 1]
            : (fileDurationSeconds > startSec
                  ? fileDurationSeconds
                  : startSec + 60.0);

        chapters.add(
          Chapter(
            index: i + 1,
            title: titles[i],
            startSeconds: startSec,
            endSeconds: endSec,
          ),
        );
      }
    } catch (_) {}

    return chapters;
  }

  static String sanitizeChapterTitle(String rawTitle, int index) {
    final trimmed = rawTitle.trim();
    final lower = trimmed.toLowerCase();
    if (lower.contains('opening credit') ||
        lower == 'intro' ||
        lower.contains('publisher\'s summary') ||
        lower.contains('title & opening credits') ||
        lower.contains('title and opening credits')) {
      return 'Chapter $index';
    }
    return trimmed.isNotEmpty ? trimmed : 'Chapter $index';
  }

  /// Parse QuickTime Chapter Text Track (`trak -> mdia -> minf -> stbl`)
  static Future<List<Chapter>> _parseTextTrack(
    RandomAccessFile raf,
    int offset,
    int size,
    double fileDurationSeconds,
  ) async {
    final chapters = <Chapter>[];
    try {
      var isTextTrack = false;
      int? stcoOffset;
      int? stcoSize;
      int? stszOffset;
      int? stszSize;
      int? sttsOffset;
      int? sttsSize;
      int timeScale = 1000;

      await _scanAtoms(raf, offset, size, (tType, tOffset, tSize) async {
        if (tType == 'mdia') {
          await _scanAtoms(raf, tOffset + 8, tSize - 8, (
            mType,
            mOffset,
            mSize,
          ) async {
            if (mType == 'mdhd' && mSize >= 24) {
              await raf.setPosition(mOffset + 20);
              final tsBytes = await raf.read(4);
              if (tsBytes.length == 4) {
                timeScale = ByteData.sublistView(tsBytes).getUint32(0);
                if (timeScale <= 0) timeScale = 1000;
              }
            } else if (mType == 'hdlr' && mSize >= 16) {
              await raf.setPosition(mOffset + 16);
              final hdlrType = await raf.read(4);
              if (hdlrType.length == 4) {
                final typeStr = utf8.decode(hdlrType, allowMalformed: true);
                if (typeStr == 'text' ||
                    typeStr == 'sbtl' ||
                    typeStr == 'subt') {
                  isTextTrack = true;
                }
              }
            } else if (mType == 'minf') {
              await _scanAtoms(raf, mOffset + 8, mSize - 8, (
                fType,
                fOffset,
                fSize,
              ) async {
                if (fType == 'stbl') {
                  await _scanAtoms(raf, fOffset + 8, fSize - 8, (
                    sType,
                    sOffset,
                    sSize,
                  ) async {
                    if (sType == 'stco' || sType == 'co64') {
                      stcoOffset = sOffset + 8;
                      stcoSize = sSize - 8;
                    } else if (sType == 'stsz') {
                      stszOffset = sOffset + 8;
                      stszSize = sSize - 8;
                    } else if (sType == 'stts') {
                      sttsOffset = sOffset + 8;
                      sttsSize = sSize - 8;
                    }
                  });
                }
              });
            }
          });
        }
      });

      if (!isTextTrack || stcoOffset == null || stszOffset == null) {
        return chapters;
      }

      // Read sample offsets from stco box
      await raf.setPosition(stcoOffset!);
      final stcoData = await raf.read(stcoSize!.clamp(0, 100000));
      if (stcoData.length < 8) return chapters;
      final stcoBd = ByteData.sublistView(stcoData);
      final sampleCount = stcoBd.getUint32(4);

      if (sampleCount <= 0 || sampleCount > 500) return chapters;

      final chunkOffsets = <int>[];
      var p = 8;
      for (var i = 0; i < sampleCount; i++) {
        if (p + 4 > stcoData.length) break;
        chunkOffsets.add(stcoBd.getUint32(p));
        p += 4;
      }

      // Read sample durations from stts box
      final sampleDurations = <double>[];
      if (sttsOffset != null && sttsSize! >= 8) {
        await raf.setPosition(sttsOffset!);
        final sttsData = await raf.read(sttsSize!.clamp(0, 100000));
        if (sttsData.length >= 8) {
          final sttsBd = ByteData.sublistView(sttsData);
          final entryCount = sttsBd.getUint32(4);
          var sp = 8;
          for (var i = 0; i < entryCount; i++) {
            if (sp + 8 > sttsData.length) break;
            final count = sttsBd.getUint32(sp);
            final delta = sttsBd.getUint32(sp + 4);
            sp += 8;
            for (var c = 0; c < count; c++) {
              sampleDurations.add(delta / timeScale.toDouble());
            }
          }
        }
      }

      // Read text samples for chapter titles
      var currentTime = 0.0;
      for (var i = 0; i < chunkOffsets.length; i++) {
        final sampleOffset = chunkOffsets[i];
        await raf.setPosition(sampleOffset);
        final sampleHeader = await raf.read(2);
        if (sampleHeader.length < 2) break;
        final textLen = ByteData.sublistView(sampleHeader).getUint16(0);

        String titleStr = 'Chapter ${i + 1}';
        if (textLen > 0 && textLen < 500) {
          final textData = await raf.read(textLen);
          if (textData.length == textLen) {
            final str = utf8.decode(textData, allowMalformed: true).trim();
            if (str.isNotEmpty) titleStr = sanitizeChapterTitle(str, i + 1);
          }
        }

        final duration = (i < sampleDurations.length)
            ? sampleDurations[i]
            : 1800.0;
        final endSec = currentTime + duration;

        chapters.add(
          Chapter(
            index: i + 1,
            title: titleStr,
            startSeconds: currentTime,
            endSeconds: endSec,
          ),
        );

        currentTime = endSec;
      }
    } catch (_) {}

    return chapters;
  }

  static Future<Map<String, String?>> _parseIlstAtom(
    RandomAccessFile raf,
    int offset,
    int size,
  ) async {
    final metaMap = <String, String?>{};
    try {
      await _scanAtoms(raf, offset, size, (
        atomType,
        atomOffset,
        atomSize,
      ) async {
        await _scanAtoms(raf, atomOffset + 8, atomSize - 8, (
          dataType,
          dataOffset,
          dataSize,
        ) async {
          if (dataType == 'data' && dataSize > 16) {
            await raf.setPosition(dataOffset + 16);
            final textBytes = await raf.read(dataSize - 16);
            final val = utf8.decode(textBytes, allowMalformed: true).trim();
            if (atomType.contains('nam')) {
              metaMap['title'] = val;
            } else if (atomType.contains('ART')) {
              metaMap['author'] = val;
            } else if (atomType.contains('alb')) {
              metaMap['album'] = val;
            }
          }
        });
      });
    } catch (_) {}

    return metaMap;
  }

  /// Generate smart chapter divisions (30 minutes each) if no embedded chapters exist
  static List<Chapter> _generateDefaultChapters(double fileDurationSeconds) {
    if (fileDurationSeconds <= 0) {
      return [
        Chapter(
          index: 1,
          title: 'Chapter 1',
          startSeconds: 0,
          endSeconds: 3600,
        ),
      ];
    }

    // Default chapter duration: 30 minutes (1800 seconds)
    const chapterInterval = 1800.0;
    if (fileDurationSeconds <= chapterInterval) {
      return [
        Chapter(
          index: 1,
          title: 'Full Audiobook',
          startSeconds: 0,
          endSeconds: fileDurationSeconds,
        ),
      ];
    }

    final chapters = <Chapter>[];
    var currentStart = 0.0;
    var chapterNumber = 1;

    while (currentStart < fileDurationSeconds) {
      final currentEnd = (currentStart + chapterInterval > fileDurationSeconds)
          ? fileDurationSeconds
          : currentStart + chapterInterval;

      chapters.add(
        Chapter(
          index: chapterNumber,
          title: 'Chapter $chapterNumber',
          startSeconds: currentStart,
          endSeconds: currentEnd,
        ),
      );

      currentStart = currentEnd;
      chapterNumber++;
    }

    return chapters;
  }
}
