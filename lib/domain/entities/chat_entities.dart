class ChatUserEntity {
  final String id;
  final String name;
  final String avatarUrl;

  const ChatUserEntity({
    required this.id,
    required this.name,
    required this.avatarUrl,
  });
}

class ChatMessageEntity {
  final String id;
  final String threadId;
  final String text;
  final DateTime createdAt;
  final bool isMe;
  final bool isRead;

  const ChatMessageEntity({
    required this.id,
    required this.threadId,
    required this.text,
    required this.createdAt,
    required this.isMe,
    this.isRead = true,
  });
}

class ChatThreadEntity {
  final String id;
  final ChatUserEntity user;
  final List<ChatMessageEntity> messages;
  final List<String> participantIds;
  final String roomId;

  const ChatThreadEntity({
    required this.id,
    required this.user,
    required this.messages,
    this.participantIds = const <String>[],
    this.roomId = '',
  });

  ChatMessageEntity? get lastMessage => messages.isEmpty ? null : messages.last;

  int get unreadCount => messages
      .where((ChatMessageEntity message) => !message.isMe && !message.isRead)
      .length;
}
