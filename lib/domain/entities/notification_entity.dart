import 'app_enums.dart';

class NotificationEntity {
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

  const NotificationEntity({
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

  NotificationEntity copyWith({
    String? id,
    String? notificationCode,
    String? userId,
    String? title,
    String? content,
    NotificationType? type,
    String? relatedId,
    bool? isRead,
    bool? isArchived,
    DateTime? createdAt,
    bool clearRelatedId = false,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      notificationCode: notificationCode ?? this.notificationCode,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      relatedId: clearRelatedId ? null : relatedId ?? this.relatedId,
      isRead: isRead ?? this.isRead,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
