class MessageEntity {
  final String id;
  final String conversationId;
  final String senderId;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  const MessageEntity({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.message,
    required this.createdAt,
    required this.isRead,
  });

  MessageEntity copyWith({
    String? senderId,
    String? message,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return MessageEntity(
      id: id,
      conversationId: conversationId,
      senderId: senderId ?? this.senderId,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
