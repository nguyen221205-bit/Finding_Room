import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../core/constants/storage_keys.dart';
import '../../core/utils/business_code_generator.dart';
import '../../core/utils/id_generator.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../data/models/local_conversation_model.dart';

class ConversationProvider extends ChangeNotifier {
  final Box<dynamic> _box = Hive.box<dynamic>(HiveBoxes.conversations);
  List<ConversationEntity> _conversations = <ConversationEntity>[];
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  List<ConversationEntity> get conversations =>
      List<ConversationEntity>.unmodifiable(_conversations);

  Future<void> loadConversations() async {
    _isLoading = true;
    notifyListeners();

    try {
      _conversations = _box.values
          .whereType<Map<dynamic, dynamic>>()
          .map(LocalConversationModel.fromMap)
          .toList();
      _sortConversations();
    } catch (_) {
      // Quietly handle
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _sortConversations() {
    _conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<ConversationEntity> getUserConversations(String userId) {
    return _conversations
        .where((conv) => conv.participantIds.contains(userId))
        .toList();
  }

  ConversationEntity? getConversationById(String id) {
    try {
      return _conversations.firstWhere((conv) => conv.id == id);
    } catch (_) {
      return null;
    }
  }

  ConversationEntity? findConversationBetween(
    String user1,
    String user2, {
    String? roomId,
  }) {
    try {
      return _conversations.firstWhere((conv) {
        final bool hasParticipants =
            conv.participantIds.contains(user1) &&
            conv.participantIds.contains(user2);
        if (roomId != null && roomId.isNotEmpty) {
          return hasParticipants && conv.roomId == roomId;
        }
        return hasParticipants;
      });
    } catch (_) {
      return null;
    }
  }

  Future<ConversationEntity> createConversation({
    required List<String> participantIds,
    String roomId = '',
  }) async {
    if (participantIds.length == 2) {
      final ConversationEntity? existing = findConversationBetween(
        participantIds[0],
        participantIds[1],
        roomId: roomId,
      );
      if (existing != null) {
        return existing;
      }
    }

    final String id = IdGenerator.generate('conv');
    final String conversationCode = BusinessCodeGenerator.generate(
      prefix: 'CONV',
      box: _box,
      codeExtractor: (entry) =>
          entry is Map ? entry['conversationCode'] as String? : null,
    );

    final ConversationEntity conversation = ConversationEntity(
      id: id,
      conversationCode: conversationCode,
      participantIds: participantIds,
      roomId: roomId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lastMessage: '',
      lastMessageSenderId: '',
      unreadCount: 0,
    );

    await _box.put(id, LocalConversationModel(conversation).toMap());
    _conversations.insert(0, conversation);
    notifyListeners();
    return conversation;
  }

  Future<void> updateLastMessage({
    required String conversationId,
    required String lastMessage,
    required String lastMessageSenderId,
    bool incrementUnread = false,
  }) async {
    final int index = _conversations.indexWhere(
      (conv) => conv.id == conversationId,
    );
    if (index < 0) return;

    final ConversationEntity current = _conversations[index];
    final ConversationEntity updated = current.copyWith(
      lastMessage: lastMessage,
      lastMessageSenderId: lastMessageSenderId,
      updatedAt: DateTime.now(),
      unreadCount: incrementUnread
          ? current.unreadCount + 1
          : current.unreadCount,
    );

    await _box.put(conversationId, LocalConversationModel(updated).toMap());
    _conversations[index] = updated;
    _sortConversations();
    notifyListeners();
  }

  Future<void> resetUnreadCount(String conversationId) async {
    final int index = _conversations.indexWhere(
      (conv) => conv.id == conversationId,
    );
    if (index < 0) return;

    final ConversationEntity current = _conversations[index];
    if (current.unreadCount == 0) return;

    final ConversationEntity updated = current.copyWith(unreadCount: 0);

    await _box.put(conversationId, LocalConversationModel(updated).toMap());
    _conversations[index] = updated;
    notifyListeners();
  }

  Future<void> deleteConversation(String id) async {
    await _box.delete(id);
    _conversations.removeWhere((conv) => conv.id == id);
    notifyListeners();
  }

  Future<void> updateConversation(ConversationEntity conversation) async {
    final int index = _conversations.indexWhere(
      (conv) => conv.id == conversation.id,
    );
    if (index >= 0) {
      await _box.put(
        conversation.id,
        LocalConversationModel(conversation).toMap(),
      );
      _conversations[index] = conversation;
      _sortConversations();
      notifyListeners();
    }
  }
}
