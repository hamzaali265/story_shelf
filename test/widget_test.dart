import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:story_shelf/core/database/hive_database.dart';
import 'package:story_shelf/features/player/providers/player_provider.dart';
import 'package:story_shelf/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => '.',
    );
    await HiveDatabase.init('./test_hive_temp');
    await initAudioService();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  testWidgets('StoryShelf App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: StoryShelfApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('StoryShelf'), findsWidgets);
  });
}
