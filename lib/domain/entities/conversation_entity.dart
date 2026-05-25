class ConversationEntity {
  final String id;
  final List<String> participantIds;
  final String roomId;
  final String lastMessage;
  final DateTime lastMessageTime;

  const ConversationEntity({
    required this.id,
    required this.participantIds,
    required this.roomId,
    required this.lastMessage,
    required this.lastMessageTime,
  });

  ConversationEntity copyWith({
    List<String>? participantIds,
    String? roomId,
    String? lastMessage,
    DateTime? lastMessageTime,
  }) {
    return ConversationEntity(
      id: id,
      participantIds: participantIds ?? this.participantIds,
      roomId: roomId ?? this.roomId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
    );
  }
}
