import 'package:hive/hive.dart';
import '../../core/constants/storage_keys.dart';
import '../../domain/entities/notification_preferences_entity.dart';
import '../models/local_settings_model.dart';

class LocalSettingsStorage {
  Box<dynamic> get _box => Hive.box<dynamic>(HiveBoxes.settings);

  // Global Theme Mode
  bool loadDarkMode() {
    return _box.get('theme_dark_mode', defaultValue: false) as bool;
  }

  Future<void> saveDarkMode(bool isDark) async {
    await _box.put('theme_dark_mode', isDark);
  }

  // User-specific notification preferences
  NotificationPreferencesEntity loadNotificationPreferences(String userId) {
    if (userId.isEmpty) {
      return const NotificationPreferencesEntity();
    }
    final dynamic val = _box.get('notif_pref_$userId');
    if (val is Map) {
      return LocalNotificationPreferencesModel.fromMap(val).toEntity();
    }
    return const NotificationPreferencesEntity();
  }

  Future<void> saveNotificationPreferences(
    String userId,
    NotificationPreferencesEntity preferences,
  ) async {
    if (userId.isEmpty) return;
    final model = LocalNotificationPreferencesModel.fromEntity(preferences);
    await _box.put('notif_pref_$userId', model.toMap());
  }
}
