import 'chapter_model.dart';

class Book {
  final String id;
  final String filePath;
  final String title;
  final String author;
  final String? album;
  final double durationSeconds;
  final int fileSizeBytes;
  final int lastModified;
  final String? coverPath;
  final List<Chapter> chapters;
  final DateTime addedDate;

  Book({
    required this.id,
    required this.filePath,
    required this.title,
    required this.author,
    this.album,
    required this.durationSeconds,
    required this.fileSizeBytes,
    required this.lastModified,
    this.coverPath,
    required this.chapters,
    required this.addedDate,
  });

  Book copyWith({
    String? id,
    String? filePath,
    String? title,
    String? author,
    String? album,
    double? durationSeconds,
    int? fileSizeBytes,
    int? lastModified,
    String? coverPath,
    List<Chapter>? chapters,
    DateTime? addedDate,
  }) {
    return Book(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      title: title ?? this.title,
      author: author ?? this.author,
      album: album ?? this.album,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      lastModified: lastModified ?? this.lastModified,
      coverPath: coverPath ?? this.coverPath,
      chapters: chapters ?? this.chapters,
      addedDate: addedDate ?? this.addedDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'filePath': filePath,
        'title': title,
        'author': author,
        'album': album,
        'durationSeconds': durationSeconds,
        'fileSizeBytes': fileSizeBytes,
        'lastModified': lastModified,
        'coverPath': coverPath,
        'chapters': chapters.map((c) => c.toJson()).toList(),
        'addedDate': addedDate.toIso8601String(),
      };

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        id: json['id'] as String,
        filePath: json['filePath'] as String,
        title: json['title'] as String,
        author: json['author'] as String? ?? 'Unknown Author',
        album: json['album'] as String?,
        durationSeconds: (json['durationSeconds'] as num?)?.toDouble() ?? 0.0,
        fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
        lastModified: json['lastModified'] as int? ?? 0,
        coverPath: json['coverPath'] as String?,
        chapters: (json['chapters'] as List<dynamic>?)
                ?.map((c) => Chapter.fromJson(Map<String, dynamic>.from(c as Map)))
                .toList() ??
            [],
        addedDate: json['addedDate'] != null
            ? DateTime.parse(json['addedDate'] as String)
            : DateTime.now(),
      );
}
