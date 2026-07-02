class BookPlaybackState {
  final String bookId;
  final double positionSeconds;
  final int currentChapterIndex;
  final double speed;
  final bool isFinished;
  final DateTime lastListened;

  BookPlaybackState({
    required this.bookId,
    required this.positionSeconds,
    required this.currentChapterIndex,
    required this.speed,
    required this.isFinished,
    required this.lastListened,
  });

  BookPlaybackState copyWith({
    String? bookId,
    double? positionSeconds,
    int? currentChapterIndex,
    double? speed,
    bool? isFinished,
    DateTime? lastListened,
  }) {
    return BookPlaybackState(
      bookId: bookId ?? this.bookId,
      positionSeconds: positionSeconds ?? this.positionSeconds,
      currentChapterIndex: currentChapterIndex ?? this.currentChapterIndex,
      speed: speed ?? this.speed,
      isFinished: isFinished ?? this.isFinished,
      lastListened: lastListened ?? this.lastListened,
    );
  }

  Map<String, dynamic> toJson() => {
        'bookId': bookId,
        'positionSeconds': positionSeconds,
        'currentChapterIndex': currentChapterIndex,
        'speed': speed,
        'isFinished': isFinished,
        'lastListened': lastListened.toIso8601String(),
      };

  factory BookPlaybackState.fromJson(Map<String, dynamic> json) => BookPlaybackState(
        bookId: json['bookId'] as String,
        positionSeconds: (json['positionSeconds'] as num?)?.toDouble() ?? 0.0,
        currentChapterIndex: json['currentChapterIndex'] as int? ?? 0,
        speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
        isFinished: json['isFinished'] as bool? ?? false,
        lastListened: json['lastListened'] != null
            ? DateTime.parse(json['lastListened'] as String)
            : DateTime.now(),
      );

  factory BookPlaybackState.initial(String bookId) => BookPlaybackState(
        bookId: bookId,
        positionSeconds: 0.0,
        currentChapterIndex: 0,
        speed: 1.0,
        isFinished: false,
        lastListened: DateTime.now(),
      );
}
