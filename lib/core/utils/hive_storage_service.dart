import 'package:hive_flutter/hive_flutter.dart';

import '../constants/storage_keys.dart';

class HiveStorageService {
  static Future<void> initialize() async {
    await Hive.initFlutter();
    await openBoxes();
  }

  static Future<void> openBoxes() async {
    await Future.wait(<Future<Box<dynamic>>>[
      Hive.openBox<dynamic>(HiveBoxes.users),
      Hive.openBox<dynamic>(HiveBoxes.rooms),
      Hive.openBox<dynamic>(HiveBoxes.landlordRequests),
      Hive.openBox<dynamic>(HiveBoxes.conversations),
      Hive.openBox<dynamic>(HiveBoxes.messages),
      Hive.openBox<dynamic>(HiveBoxes.notifications),
      Hive.openBox<dynamic>(HiveBoxes.appointments),
      Hive.openBox<dynamic>(HiveBoxes.settings),
    ]);
  }
}
