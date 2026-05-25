import '../../domain/entities/conversation_entity.dart';

class LocalConversationModel {
  final ConversationEntity conversation;

  const LocalConversationModel(this.conversation);

  Map<String, dynamic> toMap({
    required String landlordName,
    required String landlordAvatarUrl,
  }) {
    return <String, dynamic>{
      'id': conversation.id,
      'participantIds': conversation.participantIds,
      'roomId': conversation.roomId,
      'lastMessage': conversation.lastMessage,
      'lastMessageTime': conversation.lastMessageTime.toIso8601String(),
      'landlordName': landlordName,
      'landlordAvatarUrl': landlordAvatarUrl,
    };
  }

  static ConversationEntity fromMap(Map<dynamic, dynamic> map) {
    return ConversationEntity(
      id: map['id'] as String? ?? '',
      participantIds: _stringList(map['participantIds']),
      roomId: map['roomId'] as String? ?? '',
      lastMessage: map['lastMessage'] as String? ?? '',
      lastMessageTime:
          DateTime.tryParse(map['lastMessageTime'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is List<dynamic>) {
      return value.map((dynamic item) => item.toString()).toList();
    }
    return const <String>[];
  }
}
