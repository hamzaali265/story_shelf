import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../library/providers/library_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final libraryState = ref.watch(libraryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _buildSectionHeader('PLAYBACK PREFERENCES'),
          ListTile(
            title: const Text('Default Playback Speed'),
            subtitle: Text('${settings.defaultSpeed}x'),
            trailing: const Icon(Icons.speed_rounded),
            onTap: () => _showDefaultSpeedDialog(context, ref, settings.defaultSpeed),
          ),
          ListTile(
            title: const Text('Skip Backward Duration'),
            subtitle: Text('${settings.skipBackwardSeconds} seconds'),
            trailing: const Icon(Icons.replay_10_rounded),
            onTap: () => _showSkipDialog(context, ref, isForward: false, currentValue: settings.skipBackwardSeconds),
          ),
          ListTile(
            title: const Text('Skip Forward Duration'),
            subtitle: Text('${settings.skipForwardSeconds} seconds'),
            trailing: const Icon(Icons.forward_30_rounded),
            onTap: () => _showSkipDialog(context, ref, isForward: true, currentValue: settings.skipForwardSeconds),
          ),
          SwitchListTile(
            title: const Text('Auto Resume'),
            subtitle: const Text('Automatically resume playback when app opens'),
            value: settings.autoResume,
            activeTrackColor: AppTheme.primaryAccent,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).updateSettings(autoResume: val);
            },
          ),
          const Divider(height: 32),
          _buildSectionHeader('LIBRARY MANAGEMENT'),
          ListTile(
            title: const Text('Refresh Library'),
            subtitle: const Text('Scan device for newly added .m4b audiobooks'),
            trailing: libraryState.isScanning
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.sync_rounded),
            onTap: libraryState.isScanning
                ? null
                : () async {
                    await ref.read(libraryProvider.notifier).scanDevice();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Library scan completed')),
                      );
                    }
                  },
          ),
          const Divider(height: 32),
          _buildSectionHeader('ABOUT'),
          const ListTile(
            title: Text('StoryShelf'),
            subtitle: Text('Offline M4B Audiobook Player v1.0.0'),
            trailing: Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.secondaryAccent,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  void _showDefaultSpeedDialog(BuildContext context, WidgetRef ref, double current) {
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Default Speed'),
        children: [0.75, 1.0, 1.25, 1.5, 1.75, 2.0].map((s) {
          return SimpleDialogOption(
            child: Text('${s}x', style: TextStyle(fontWeight: (s == current) ? FontWeight.bold : FontWeight.normal)),
            onPressed: () {
              ref.read(settingsProvider.notifier).updateSettings(defaultSpeed: s);
              Navigator.of(context).pop();
            },
          );
        }).toList(),
      ),
    );
  }

  void _showSkipDialog(BuildContext context, WidgetRef ref, {required bool isForward, required int currentValue}) {
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text(isForward ? 'Skip Forward Duration' : 'Skip Backward Duration'),
        children: [5, 10, 15, 30, 45, 60].map((sec) {
          return SimpleDialogOption(
            child: Text('$sec seconds', style: TextStyle(fontWeight: (sec == currentValue) ? FontWeight.bold : FontWeight.normal)),
            onPressed: () {
              if (isForward) {
                ref.read(settingsProvider.notifier).updateSettings(skipForwardSeconds: sec);
              } else {
                ref.read(settingsProvider.notifier).updateSettings(skipBackwardSeconds: sec);
              }
              Navigator.of(context).pop();
            },
          );
        }).toList(),
      ),
    );
  }
}
