import '../../domain/entities/chat_entities.dart';
import '../mock/mock_chats.dart';
import 'chat_repository.dart';

class MockChatRepository implements ChatRepository {
  @override
  Future<List<ChatThreadEntity>> fetchThreads() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return MockChats.threads();
  }
}
