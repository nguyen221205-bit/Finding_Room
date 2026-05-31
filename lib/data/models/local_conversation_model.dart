import '../../domain/entities/conversation_entity.dart';

class LocalConversationModel {
  final ConversationEntity conversation;

  const LocalConversationModel(this.conversation);

  Map<String, dynamic> toMap({
    String? landlordName,
    String? landlordAvatarUrl,
  }) {
    return <String, dynamic>{
      'id': conversation.id,
      'conversationCode': conversation.conversationCode,
      'participantIds': conversation.participantIds,
      'roomId': conversation.roomId,
      'createdAt': conversation.createdAt.toIso8601String(),
      'updatedAt': conversation.updatedAt.toIso8601String(),
      'lastMessage': conversation.lastMessage,
      'lastMessageSenderId': conversation.lastMessageSenderId,
      'unreadCount': conversation.unreadCount,
      'landlordName': ?landlordName,
      'landlordAvatarUrl': ?landlordAvatarUrl,
    };
  }

  static ConversationEntity fromMap(Map<dynamic, dynamic> map) {
    return ConversationEntity(
      id: map['id'] as String? ?? '',
      conversationCode: map['conversationCode'] as String? ?? '',
      participantIds: _stringList(map['participantIds']),
      roomId: map['roomId'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      lastMessage: map['lastMessage'] as String? ?? '',
      lastMessageSenderId: map['lastMessageSenderId'] as String? ?? '',
      unreadCount: map['unreadCount'] as int? ?? 0,
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is List<dynamic>) {
      return value.map((dynamic item) => item.toString()).toList();
    }
    return const <String>[];
  }
}
