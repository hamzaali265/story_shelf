import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/database/hive_database.dart';
import 'core/theme/app_theme.dart';
import 'features/library/screens/library_screen.dart';
import 'features/player/providers/player_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveDatabase.init();

  runApp(
    const ProviderScope(
      child: StoryShelfApp(),
    ),
  );
}

class StoryShelfApp extends ConsumerWidget {
  const StoryShelfApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dynamicAccent = ref.watch(dynamicAccentProvider);

    return MaterialApp(
      title: 'StoryShelf',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.darkTheme(dynamicAccent),
      home: const LibraryScreen(),
    );
  }
}
