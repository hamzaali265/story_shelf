class AppSettings {
  final String themeMode; // 'dark', 'light', 'system'
  final double defaultSpeed;
  final int skipBackwardSeconds;
  final int skipForwardSeconds;
  final bool autoResume;
  final bool keepScreenAwake;

  AppSettings({
    this.themeMode = 'dark',
    this.defaultSpeed = 1.0,
    this.skipBackwardSeconds = 15,
    this.skipForwardSeconds = 30,
    this.autoResume = true,
    this.keepScreenAwake = false,
  });

  AppSettings copyWith({
    String? themeMode,
    double? defaultSpeed,
    int? skipBackwardSeconds,
    int? skipForwardSeconds,
    bool? autoResume,
    bool? keepScreenAwake,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      defaultSpeed: defaultSpeed ?? this.defaultSpeed,
      skipBackwardSeconds: skipBackwardSeconds ?? this.skipBackwardSeconds,
      skipForwardSeconds: skipForwardSeconds ?? this.skipForwardSeconds,
      autoResume: autoResume ?? this.autoResume,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
    );
  }

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode,
        'defaultSpeed': defaultSpeed,
        'skipBackwardSeconds': skipBackwardSeconds,
        'skipForwardSeconds': skipForwardSeconds,
        'autoResume': autoResume,
        'keepScreenAwake': keepScreenAwake,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        themeMode: json['themeMode'] as String? ?? 'dark',
        defaultSpeed: (json['defaultSpeed'] as num?)?.toDouble() ?? 1.0,
        skipBackwardSeconds: json['skipBackwardSeconds'] as int? ?? 15,
        skipForwardSeconds: json['skipForwardSeconds'] as int? ?? 30,
        autoResume: json['autoResume'] as bool? ?? true,
        keepScreenAwake: json['keepScreenAwake'] as bool? ?? false,
      );
}
