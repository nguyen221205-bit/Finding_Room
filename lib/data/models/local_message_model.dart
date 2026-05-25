import '../../domain/entities/message_entity.dart';

class LocalMessageModel {
  final MessageEntity message;

  const LocalMessageModel(this.message);

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': message.id,
      'conversationId': message.conversationId,
      'senderId': message.senderId,
      'message': message.message,
      'createdAt': message.createdAt.toIso8601String(),
      'isRead': message.isRead,
    };
  }

  static MessageEntity fromMap(Map<dynamic, dynamic> map) {
    return MessageEntity(
      id: map['id'] as String? ?? '',
      conversationId: map['conversationId'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      message: map['message'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      isRead: map['isRead'] as bool? ?? false,
    );
  }
}
