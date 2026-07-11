class Bookmark {
  final String id;
  final String bookId;
  final double positionSeconds;
  final int chapterIndex;
  final String chapterTitle;
  final String? note;
  final DateTime createdAt;

  Bookmark({
    required this.id,
    required this.bookId,
    required this.positionSeconds,
    required this.chapterIndex,
    required this.chapterTitle,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookId': bookId,
        'positionSeconds': positionSeconds,
        'chapterIndex': chapterIndex,
        'chapterTitle': chapterTitle,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
        id: json['id'] as String,
        bookId: json['bookId'] as String,
        positionSeconds: (json['positionSeconds'] as num?)?.toDouble() ?? 0.0,
        chapterIndex: json['chapterIndex'] as int? ?? 0,
        chapterTitle: json['chapterTitle'] as String? ?? '',
        note: json['note'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
      );
}
