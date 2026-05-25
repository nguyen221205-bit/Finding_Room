import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:room_finder_app/core/utils/hive_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:room_finder_app/main.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tempDir = await Directory.systemTemp.createTemp('room_finder_widget_test');
    Hive.init(tempDir.path);
    await HiveStorageService.openBoxes();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('shows login screen on startup', (WidgetTester tester) async {
    await tester.pumpWidget(const RoomFinderApp());
    await tester.pumpAndSettle();

    expect(find.text('Room Rental Finder'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
