import '../../domain/entities/message_entity.dart';

class LocalMessageModel {
  final MessageEntity message;

  const LocalMessageModel(this.message);

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': message.id,
      'messageCode': message.messageCode,
      'conversationId': message.conversationId,
      'senderId': message.senderId,
      'receiverId': message.receiverId,
      'content': message.content,
      'timestamp': message.timestamp.toIso8601String(),
      'isRead': message.isRead,
    };
  }

  static MessageEntity fromMap(Map<dynamic, dynamic> map) {
    return MessageEntity(
      id: map['id'] as String? ?? '',
      messageCode: map['messageCode'] as String? ?? '',
      conversationId: map['conversationId'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      receiverId: map['receiverId'] as String? ?? '',
      content: map['content'] as String? ?? map['message'] as String? ?? '',
      timestamp:
          DateTime.tryParse(
            map['timestamp'] as String? ?? map['createdAt'] as String? ?? '',
          ) ??
          DateTime.now(),
      isRead: map['isRead'] as bool? ?? false,
    );
  }
}
