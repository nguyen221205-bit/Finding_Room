import 'package:flutter/foundation.dart';
import '../../data/repositories/local_settings_storage.dart';
import '../../domain/entities/notification_preferences_entity.dart';

class SettingsProvider extends ChangeNotifier {
  final LocalSettingsStorage _storage;
  bool _isDarkMode = false;
  NotificationPreferencesEntity _notificationPreferences =
      const NotificationPreferencesEntity();
  String _currentUserId = '';

  SettingsProvider({LocalSettingsStorage? storage})
    : _storage = storage ?? LocalSettingsStorage() {
    _loadInitialSettings();
  }

  bool get isDarkMode => _isDarkMode;
  NotificationPreferencesEntity get notificationPreferences =>
      _notificationPreferences;

  void _loadInitialSettings() {
    _isDarkMode = _storage.loadDarkMode();
  }

  void loadPreferencesForUser(String userId) {
    _currentUserId = userId;
    _notificationPreferences = _storage.loadNotificationPreferences(userId);
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool enabled) async {
    _isDarkMode = enabled;
    await _storage.saveDarkMode(enabled);
    notifyListeners();
  }

  Future<void> updateNotificationPreferences(
    NotificationPreferencesEntity nextPrefs,
  ) async {
    _notificationPreferences = nextPrefs;
    if (_currentUserId.isNotEmpty) {
      await _storage.saveNotificationPreferences(_currentUserId, nextPrefs);
    }
    notifyListeners();
  }

  Future<void> toggleVerificationNotifications(bool enabled) async {
    final next = _notificationPreferences.copyWith(
      verificationNotificationsEnabled: enabled,
    );
    await updateNotificationPreferences(next);
  }

  Future<void> toggleRoomApprovalNotifications(bool enabled) async {
    final next = _notificationPreferences.copyWith(
      roomApprovalNotificationsEnabled: enabled,
    );
    await updateNotificationPreferences(next);
  }

  Future<void> toggleAppointmentNotifications(bool enabled) async {
    final next = _notificationPreferences.copyWith(
      appointmentNotificationsEnabled: enabled,
    );
    await updateNotificationPreferences(next);
  }
}
