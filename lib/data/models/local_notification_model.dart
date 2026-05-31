import '../../domain/entities/app_enums.dart';
import '../../domain/entities/notification_entity.dart';

class LocalNotificationModel {
  final String id;
  final String notificationCode;
  final String userId;
  final String title;
  final String content;
  final NotificationType type;
  final String? relatedId;
  final bool isRead;
  final bool isArchived;
  final DateTime createdAt;

  const LocalNotificationModel({
    required this.id,
    required this.notificationCode,
    required this.userId,
    required this.title,
    required this.content,
    required this.type,
    this.relatedId,
    required this.isRead,
    required this.isArchived,
    required this.createdAt,
  });

  NotificationEntity toEntity() {
    return NotificationEntity(
      id: id,
      notificationCode: notificationCode,
      userId: userId,
      title: title,
      content: content,
      type: type,
      relatedId: relatedId,
      isRead: isRead,
      isArchived: isArchived,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'notificationCode': notificationCode,
      'userId': userId,
      'title': title,
      'content': content,
      'type': type.name,
      'relatedId': relatedId,
      'isRead': isRead,
      'isArchived': isArchived,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static LocalNotificationModel fromMap(Map<dynamic, dynamic> map) {
    return LocalNotificationModel(
      id: map['id'] as String? ?? '',
      notificationCode: map['notificationCode'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      type: _typeFromName(map['type'] as String? ?? 'verificationApproved'),
      relatedId: map['relatedId'] as String?,
      isRead: map['isRead'] as bool? ?? false,
      isArchived: map['isArchived'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  static LocalNotificationModel fromEntity(NotificationEntity entity) {
    return LocalNotificationModel(
      id: entity.id,
      notificationCode: entity.notificationCode,
      userId: entity.userId,
      title: entity.title,
      content: entity.content,
      type: entity.type,
      relatedId: entity.relatedId,
      isRead: entity.isRead,
      isArchived: entity.isArchived,
      createdAt: entity.createdAt,
    );
  }

  static NotificationType _typeFromName(String name) {
    return NotificationType.values.firstWhere(
      (NotificationType t) => t.name == name,
      orElse: () => NotificationType.verificationApproved,
    );
  }
}
