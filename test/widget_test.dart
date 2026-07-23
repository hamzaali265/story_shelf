import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:story_shelf/core/database/hive_database.dart';
import 'package:story_shelf/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await HiveDatabase.init('./test_hive_temp');
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
    await tester.pumpAndSettle();

    expect(find.text('StoryShelf'), findsWidgets);
  });
}
