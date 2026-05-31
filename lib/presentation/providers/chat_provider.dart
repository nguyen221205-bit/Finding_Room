import 'package:flutter/foundation.dart';

import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/local_chat_storage.dart';
import '../../core/utils/id_generator.dart';
import '../../domain/entities/chat_entities.dart';

class ChatProvider extends ChangeNotifier {
  final ChatRepository _chatRepository;

  ChatProvider(this._chatRepository);

  bool _isLoading = false;
  String? _error;
  final List<ChatThreadEntity> _threads = <ChatThreadEntity>[];

  bool get isLoading => _isLoading;
  String? get error => _error;

  List<ChatThreadEntity> get threads =>
      List<ChatThreadEntity>.unmodifiable(_threads);

  bool get hasLoaded => _threads.isNotEmpty || _error != null;

  Future<void> loadThreadsIfNeeded() async {
    if (_isLoading || hasLoaded) return;
    await loadThreads();
  }

  Future<void> loadThreads() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final List<ChatThreadEntity> result = await _chatRepository
          .fetchThreads();
      _threads
        ..clear()
        ..addAll(result);
    } catch (e) {
      _error = 'Failed to load chats.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  ChatThreadEntity? threadById(String threadId) {
    try {
      return _threads.firstWhere((ChatThreadEntity t) => t.id == threadId);
    } catch (_) {
      return null;
    }
  }

  String ensureThreadForLandlord({
    String roomId = '',
    String userId = LocalChatStorage.defaultUserId,
    String landlordId = '',
    required String landlordName,
    required String landlordAvatarUrl,
    required String landlordPhone,
  }) {
    final String resolvedLandlordId = landlordId.isEmpty
        ? 'landlord_${landlordPhone.replaceAll('+', '')}'
        : landlordId;
    final ChatRepository repository = _chatRepository;
    final String threadId = repository is LocalChatStorage
        ? repository.ensureConversation(
            roomId: roomId.isEmpty ? 'room_$resolvedLandlordId' : roomId,
            userId: userId,
            landlordId: resolvedLandlordId,
            landlordName: landlordName,
            landlordAvatarUrl: landlordAvatarUrl,
          )
        : 't_$resolvedLandlordId';

    final int existingIndex = _threads.indexWhere(
      (ChatThreadEntity t) => t.id == threadId,
    );
    if (existingIndex >= 0) return threadId;

    final ChatThreadEntity newThread = ChatThreadEntity(
      id: threadId,
      user: ChatUserEntity(
        id: resolvedLandlordId,
        name: landlordName,
        avatarUrl: landlordAvatarUrl,
      ),
      messages: const <ChatMessageEntity>[],
      participantIds: <String>[userId, resolvedLandlordId],
      roomId: roomId,
    );

    _threads.insert(0, newThread);
    notifyListeners();
    return threadId;
  }

  List<ChatMessageEntity> messages(String threadId) {
    return threadById(threadId)?.messages ?? const <ChatMessageEntity>[];
  }

  void sendMessage({required String threadId, required String text}) {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final int index = _threads.indexWhere(
      (ChatThreadEntity t) => t.id == threadId,
    );
    if (index < 0) return;

    final ChatThreadEntity thread = _threads[index];
    final String senderId = thread.participantIds.isNotEmpty
        ? thread.participantIds.first
        : LocalChatStorage.defaultUserId;
    final ChatRepository repository = _chatRepository;
    if (repository is LocalChatStorage) {
      repository.sendMessage(
        conversationId: threadId,
        senderId: senderId,
        message: trimmed,
      );
    }

    final ChatMessageEntity message = ChatMessageEntity(
      id: IdGenerator.generate('chat_msg'),
      threadId: threadId,
      text: trimmed,
      createdAt: DateTime.now(),
      isMe: true,
      isRead: true,
    );

    final ChatThreadEntity updated = ChatThreadEntity(
      id: thread.id,
      user: thread.user,
      messages: <ChatMessageEntity>[...thread.messages, message],
      participantIds: thread.participantIds,
      roomId: thread.roomId,
    );

    _threads[index] = updated;
    _sortThreads();
    notifyListeners();
  }

  void markThreadRead(String threadId) {
    final int index = _threads.indexWhere(
      (ChatThreadEntity t) => t.id == threadId,
    );
    if (index < 0) return;

    final ChatThreadEntity thread = _threads[index];
    if (thread.unreadCount == 0) return;

    final String readerId = thread.participantIds.isNotEmpty
        ? thread.participantIds.first
        : LocalChatStorage.defaultUserId;
    final ChatRepository repository = _chatRepository;
    if (repository is LocalChatStorage) {
      repository.markConversationRead(
        conversationId: threadId,
        readerId: readerId,
      );
    }

    _threads[index] = ChatThreadEntity(
      id: thread.id,
      user: thread.user,
      messages: thread.messages
          .map(
            (ChatMessageEntity message) => message.isMe
                ? message
                : ChatMessageEntity(
                    id: message.id,
                    threadId: message.threadId,
                    text: message.text,
                    createdAt: message.createdAt,
                    isMe: message.isMe,
                    isRead: true,
                  ),
          )
          .toList(growable: false),
      participantIds: thread.participantIds,
      roomId: thread.roomId,
    );
    notifyListeners();
  }

  void _sortThreads() {
    _threads.sort((ChatThreadEntity a, ChatThreadEntity b) {
      final DateTime aTime =
          a.lastMessage?.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime bTime =
          b.lastMessage?.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
  }
}
