import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../core/constants/storage_keys.dart';
import '../../core/utils/business_code_generator.dart';
import '../../core/utils/id_generator.dart';
import '../../domain/entities/message_entity.dart';
import '../../data/models/local_message_model.dart';

class MessageProvider extends ChangeNotifier {
  final Box<dynamic> _box = Hive.box<dynamic>(HiveBoxes.messages);
  List<MessageEntity> _messages = <MessageEntity>[];
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  List<MessageEntity> get messages =>
      List<MessageEntity>.unmodifiable(_messages);

  Future<void> loadMessages() async {
    _isLoading = true;
    notifyListeners();

    try {
      _messages = _box.values
          .whereType<Map<dynamic, dynamic>>()
          .map(LocalMessageModel.fromMap)
          .toList();
    } catch (_) {
      // Quietly handle
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<MessageEntity> getConversationMessages(String conversationId) {
    final List<MessageEntity> list = _messages
        .where((msg) => msg.conversationId == conversationId)
        .toList();
    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return list;
  }

  Future<MessageEntity> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    final String id = IdGenerator.generate('msg');
    final String messageCode = BusinessCodeGenerator.generate(
      prefix: 'MSG',
      box: _box,
      codeExtractor: (entry) =>
          entry is Map ? entry['messageCode'] as String? : null,
    );

    final MessageEntity message = MessageEntity(
      id: id,
      messageCode: messageCode,
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      content: content.trim(),
      timestamp: DateTime.now(),
      isRead: false,
    );

    await _box.put(id, LocalMessageModel(message).toMap());
    _messages.add(message);
    notifyListeners();
    return message;
  }

  Future<void> markAsRead(String conversationId, String readerId) async {
    bool hasChanged = false;
    for (int i = 0; i < _messages.length; i++) {
      final MessageEntity msg = _messages[i];
      if (msg.conversationId == conversationId &&
          msg.senderId != readerId &&
          !msg.isRead) {
        final MessageEntity updated = msg.copyWith(isRead: true);
        await _box.put(msg.id, LocalMessageModel(updated).toMap());
        _messages[i] = updated;
        hasChanged = true;
      }
    }
    if (hasChanged) {
      notifyListeners();
    }
  }

  Future<void> deleteMessage(String id) async {
    await _box.delete(id);
    _messages.removeWhere((msg) => msg.id == id);
    notifyListeners();
  }
}
