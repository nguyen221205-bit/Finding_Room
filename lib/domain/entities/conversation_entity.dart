class ConversationEntity {
  final String id;
  final String conversationCode;
  final List<String> participantIds;
  final String roomId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String lastMessage;
  final String lastMessageSenderId;
  final int unreadCount;

  const ConversationEntity({
    required this.id,
    required this.conversationCode,
    required this.participantIds,
    required this.roomId,
    required this.createdAt,
    required this.updatedAt,
    required this.lastMessage,
    required this.lastMessageSenderId,
    required this.unreadCount,
  });

  ConversationEntity copyWith({
    String? conversationCode,
    List<String>? participantIds,
    String? roomId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastMessage,
    String? lastMessageSenderId,
    int? unreadCount,
  }) {
    return ConversationEntity(
      id: id,
      conversationCode: conversationCode ?? this.conversationCode,
      participantIds: participantIds ?? this.participantIds,
      roomId: roomId ?? this.roomId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
