import 'dart:async';

import 'package:hive/hive.dart';

import '../../core/constants/storage_keys.dart';
import '../../core/utils/id_generator.dart';
import '../../domain/entities/chat_entities.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../models/local_conversation_model.dart';
import '../models/local_message_model.dart';
import 'chat_repository.dart';

class LocalChatStorage implements ChatRepository {
  static const String defaultUserId = 'current_user';

  Box<dynamic> get _conversationsBox =>
      Hive.box<dynamic>(HiveBoxes.conversations);
  Box<dynamic> get _messagesBox => Hive.box<dynamic>(HiveBoxes.messages);

  @override
  Future<List<ChatThreadEntity>> fetchThreads() async {
    final List<ChatThreadEntity> threads = _conversationsBox.values
        .whereType<Map<dynamic, dynamic>>()
        .map(_threadFromConversationMap)
        .toList(growable: false);

    return threads..sort((ChatThreadEntity a, ChatThreadEntity b) {
      final DateTime aTime =
          a.lastMessage?.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime bTime =
          b.lastMessage?.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
  }

  String ensureConversation({
    required String roomId,
    required String userId,
    required String landlordId,
    required String landlordName,
    required String landlordAvatarUrl,
  }) {
    final String conversationId = _conversationId(
      roomId: roomId,
      userId: userId,
      landlordId: landlordId,
    );

    if (_conversationsBox.containsKey(conversationId)) {
      return conversationId;
    }

    final ConversationEntity conversation = ConversationEntity(
      id: conversationId,
      conversationCode: 'CONV00000',
      participantIds: <String>[userId, landlordId],
      roomId: roomId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lastMessage: '',
      lastMessageSenderId: '',
      unreadCount: 0,
    );

    unawaited(
      _conversationsBox.put(
        conversationId,
        LocalConversationModel(conversation).toMap(
          landlordName: landlordName,
          landlordAvatarUrl: landlordAvatarUrl,
        ),
      ),
    );
    return conversationId;
  }

  void sendMessage({
    required String conversationId,
    required String senderId,
    required String message,
  }) {
    final String trimmed = message.trim();
    if (trimmed.isEmpty) return;

    final DateTime now = DateTime.now();
    final MessageEntity entity = MessageEntity(
      id: IdGenerator.generate('m'),
      messageCode: 'MSG00000',
      conversationId: conversationId,
      senderId: senderId,
      receiverId: '',
      content: trimmed,
      timestamp: now,
      isRead: false,
    );

    unawaited(_messagesBox.put(entity.id, LocalMessageModel(entity).toMap()));
    _updateConversationLastMessage(
      conversationId: conversationId,
      message: trimmed,
      time: now,
    );
  }

  List<MessageEntity> messagesForConversation(String conversationId) {
    final List<MessageEntity> messages = _messagesBox.values
        .whereType<Map<dynamic, dynamic>>()
        .map(LocalMessageModel.fromMap)
        .where(
          (MessageEntity message) => message.conversationId == conversationId,
        )
        .toList();

    return messages..sort(
      (MessageEntity a, MessageEntity b) => a.timestamp.compareTo(b.timestamp),
    );
  }

  void markConversationRead({
    required String conversationId,
    required String readerId,
  }) {
    for (final dynamic value in _messagesBox.values) {
      if (value is! Map<dynamic, dynamic>) continue;

      final MessageEntity message = LocalMessageModel.fromMap(value);
      if (message.conversationId != conversationId ||
          message.senderId == readerId ||
          message.isRead) {
        continue;
      }

      unawaited(
        _messagesBox.put(
          message.id,
          LocalMessageModel(message.copyWith(isRead: true)).toMap(),
        ),
      );
    }
  }

  ChatThreadEntity _threadFromConversationMap(Map<dynamic, dynamic> map) {
    final ConversationEntity conversation = LocalConversationModel.fromMap(map);
    final String landlordId = conversation.participantIds.length > 1
        ? conversation.participantIds[1]
        : 'landlord';
    final List<ChatMessageEntity> messages =
        messagesForConversation(conversation.id)
            .map((MessageEntity message) {
              return ChatMessageEntity(
                id: message.id,
                threadId: message.conversationId,
                text: message.content,
                createdAt: message.timestamp,
                isMe: message.senderId != landlordId,
                isRead: message.isRead,
              );
            })
            .toList(growable: false);

    return ChatThreadEntity(
      id: conversation.id,
      user: ChatUserEntity(
        id: landlordId,
        name: map['landlordName'] as String? ?? 'Landlord',
        avatarUrl: map['landlordAvatarUrl'] as String? ?? '',
      ),
      messages: messages,
      participantIds: conversation.participantIds,
      roomId: conversation.roomId,
    );
  }

  void _updateConversationLastMessage({
    required String conversationId,
    required String message,
    required DateTime time,
  }) {
    final dynamic value = _conversationsBox.get(conversationId);
    if (value is! Map<dynamic, dynamic>) return;

    final ConversationEntity conversation = LocalConversationModel.fromMap(
      value,
    ).copyWith(lastMessage: message, updatedAt: time);

    unawaited(
      _conversationsBox.put(
        conversationId,
        LocalConversationModel(conversation).toMap(
          landlordName: value['landlordName'] as String? ?? 'Landlord',
          landlordAvatarUrl: value['landlordAvatarUrl'] as String? ?? '',
        ),
      ),
    );
  }

  String _conversationId({
    required String roomId,
    required String userId,
    required String landlordId,
  }) {
    return 'c_${_safe(roomId)}_${_safe(userId)}_${_safe(landlordId)}';
  }

  String _safe(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
  }
}
