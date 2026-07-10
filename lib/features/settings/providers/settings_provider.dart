import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/hive_database.dart';
import '../../../core/models/app_settings_model.dart';

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(HiveDatabase.getSettings());

  void updateSettings({
    String? themeMode,
    double? defaultSpeed,
    int? skipBackwardSeconds,
    int? skipForwardSeconds,
    bool? autoResume,
    bool? keepScreenAwake,
  }) {
    state = state.copyWith(
      themeMode: themeMode,
      defaultSpeed: defaultSpeed,
      skipBackwardSeconds: skipBackwardSeconds,
      skipForwardSeconds: skipForwardSeconds,
      autoResume: autoResume,
      keepScreenAwake: keepScreenAwake,
    );
    HiveDatabase.saveSettings(state);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});
