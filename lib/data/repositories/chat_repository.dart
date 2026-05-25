import '../../domain/entities/chat_entities.dart';

abstract class ChatRepository {
  Future<List<ChatThreadEntity>> fetchThreads();
}
