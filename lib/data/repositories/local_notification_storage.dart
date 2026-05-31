import 'package:hive/hive.dart';

import '../../core/constants/storage_keys.dart';
import '../../domain/entities/notification_entity.dart';
import '../models/local_notification_model.dart';

class LocalNotificationStorage {
  Box<dynamic> get _box => Hive.box<dynamic>(HiveBoxes.notifications);

  Future<void> saveNotification(NotificationEntity notification) async {
    final LocalNotificationModel model = LocalNotificationModel.fromEntity(
      notification,
    );
    await _box.put(notification.id, model.toMap());
  }

  Future<void> updateNotification(NotificationEntity notification) async {
    await saveNotification(notification);
  }

  Future<List<NotificationEntity>> loadNotificationsByUserId(
    String userId,
  ) async {
    final List<NotificationEntity> list = <NotificationEntity>[];
    for (final dynamic val in _box.values) {
      if (val is Map) {
        final LocalNotificationModel model = LocalNotificationModel.fromMap(
          val,
        );
        if (model.userId == userId && !model.isArchived) {
          list.add(model.toEntity());
        }
      }
    }
    // Sắp xếp thời gian mới nhất lên đầu
    list.sort(
      (NotificationEntity a, NotificationEntity b) =>
          b.createdAt.compareTo(a.createdAt),
    );
    return list;
  }

  Future<void> archiveNotification(String notificationId) async {
    final dynamic val = _box.get(notificationId);
    if (val is Map) {
      final LocalNotificationModel model = LocalNotificationModel.fromMap(val);
      final NotificationEntity updated = model.toEntity().copyWith(
        isArchived: true,
      );
      await saveNotification(updated);
    }
  }

  Future<void> archiveAllReadNotifications(String userId) async {
    for (final dynamic key in _box.keys) {
      final dynamic val = _box.get(key);
      if (val is Map) {
        final LocalNotificationModel model = LocalNotificationModel.fromMap(
          val,
        );
        if (model.userId == userId && model.isRead && !model.isArchived) {
          final NotificationEntity updated = model.toEntity().copyWith(
            isArchived: true,
          );
          final LocalNotificationModel updatedModel =
              LocalNotificationModel.fromEntity(updated);
          await _box.put(key, updatedModel.toMap());
        }
      }
    }
  }
}
