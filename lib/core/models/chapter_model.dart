class Chapter {
  final int index;
  final String title;
  final double startSeconds;
  final double endSeconds;

  Chapter({
    required this.index,
    required this.title,
    required this.startSeconds,
    required this.endSeconds,
  });

  double get durationSeconds => (endSeconds - startSeconds).clamp(0, double.infinity);

  Map<String, dynamic> toJson() => {
        'index': index,
        'title': title,
        'startSeconds': startSeconds,
        'endSeconds': endSeconds,
      };

  factory Chapter.fromJson(Map<String, dynamic> json) => Chapter(
        index: json['index'] as int? ?? 0,
        title: json['title'] as String? ?? 'Chapter',
        startSeconds: (json['startSeconds'] as num?)?.toDouble() ?? 0.0,
        endSeconds: (json['endSeconds'] as num?)?.toDouble() ?? 0.0,
      );
}
