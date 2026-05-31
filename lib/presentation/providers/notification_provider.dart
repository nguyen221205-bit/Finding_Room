import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../core/constants/storage_keys.dart';
import '../../core/utils/business_code_generator.dart';
import '../../core/utils/id_generator.dart';
import '../../data/repositories/local_notification_storage.dart';
import '../../domain/entities/app_enums.dart';
import '../../domain/entities/notification_entity.dart';

import '../../data/repositories/local_settings_storage.dart';

class NotificationProvider extends ChangeNotifier {
  final LocalNotificationStorage _storage;
  final LocalSettingsStorage _settingsStorage;

  NotificationProvider({
    LocalNotificationStorage? storage,
    LocalSettingsStorage? settingsStorage,
  }) : _storage = storage ?? LocalNotificationStorage(),
       _settingsStorage = settingsStorage ?? LocalSettingsStorage();

  List<NotificationEntity> _notifications = <NotificationEntity>[];
  bool _isLoading = false;
  String? _currentLoadedUserId;

  List<NotificationEntity> get notifications =>
      List<NotificationEntity>.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  String? get currentLoadedUserId => _currentLoadedUserId;

  int get unreadCount =>
      _notifications.where((NotificationEntity n) => !n.isRead).length;

  Future<void> loadNotifications(String userId) async {
    _currentLoadedUserId = userId;
    _isLoading = true;
    notifyListeners();

    try {
      _notifications = await _storage.loadNotificationsByUserId(userId);
    } catch (_) {
      _notifications = <NotificationEntity>[];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createNotification({
    required String userId,
    required String title,
    required String content,
    required NotificationType type,
    String? relatedId,
  }) async {
    // Kiem tra cau hinh tuy chon thong bao cua nguoi dung
    final preferences = _settingsStorage.loadNotificationPreferences(userId);
    bool isEnabled = true;
    if (type == NotificationType.verificationApproved ||
        type == NotificationType.verificationRejected ||
        type == NotificationType.landlordPrivilegeRevoked) {
      isEnabled = preferences.verificationNotificationsEnabled;
    } else if (type == NotificationType.roomApproved ||
        type == NotificationType.roomRejected ||
        type == NotificationType.roomHiddenByAdmin) {
      isEnabled = preferences.roomApprovalNotificationsEnabled;
    } else if (type == NotificationType.appointmentCreated ||
        type == NotificationType.appointmentApproved ||
        type == NotificationType.appointmentRejected ||
        type == NotificationType.appointmentCompleted ||
        type == NotificationType.appointmentCancelledByTenant ||
        type == NotificationType.appointmentCancelledByLandlord ||
        type == NotificationType.appointmentCancelledByAdmin) {
      isEnabled = preferences.appointmentNotificationsEnabled;
    }

    if (!isEnabled) {
      return; // Khong tao thong bao, khong tang dem so tin chua doc
    }

    final Box<dynamic> box = Hive.box<dynamic>(HiveBoxes.notifications);
    final String code = BusinessCodeGenerator.generate(
      prefix: 'NTF',
      box: box,
      codeExtractor: (dynamic entry) {
        if (entry is Map) {
          return entry['notificationCode'] as String?;
        }
        return null;
      },
    );

    final NotificationEntity notification = NotificationEntity(
      id: IdGenerator.generate('nt'),
      notificationCode: code,
      userId: userId,
      title: title,
      content: content,
      type: type,
      relatedId: relatedId,
      isRead: false,
      isArchived: false,
      createdAt: DateTime.now(),
    );

    await _storage.saveNotification(notification);

    // Chi cap nhat bo nho RAM neu thong bao thuoc ve nguoi dung dang duoc load
    if (userId == _currentLoadedUserId) {
      _notifications.insert(0, notification);
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final int index = _notifications.indexWhere(
      (NotificationEntity n) => n.id == notificationId,
    );
    if (index != -1) {
      final NotificationEntity updated = _notifications[index].copyWith(
        isRead: true,
      );
      _notifications[index] = updated;
      await _storage.updateNotification(updated);
      notifyListeners();
    }
  }

  Future<void> markAllAsRead(String userId) async {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        final NotificationEntity updated = _notifications[i].copyWith(
          isRead: true,
        );
        _notifications[i] = updated;
        await _storage.updateNotification(updated);
      }
    }
    notifyListeners();
  }

  Future<void> archiveNotification(String notificationId) async {
    final int index = _notifications.indexWhere(
      (NotificationEntity n) => n.id == notificationId,
    );
    if (index != -1) {
      _notifications.removeAt(index);
      await _storage.archiveNotification(notificationId);
      notifyListeners();
    }
  }

  Future<void> archiveAllReadNotifications(String userId) async {
    _notifications.removeWhere((NotificationEntity n) => n.isRead);
    await _storage.archiveAllReadNotifications(userId);
    notifyListeners();
  }
}
