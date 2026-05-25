import '../../domain/entities/chat_entities.dart';

class MockChats {
  static List<ChatThreadEntity> threads() {
    final ChatUserEntity u1 = ChatUserEntity(
      id: 'u1',
      name: 'Minh Tran',
      avatarUrl:
          'https://images.unsplash.com/photo-1599566150163-29194dcaad36?auto=format&fit=crop&w=200&q=60',
    );
    final ChatUserEntity u2 = ChatUserEntity(
      id: 'u2',
      name: 'Linh Nguyen',
      avatarUrl:
          'https://images.unsplash.com/photo-1544723795-3fb6469f5b39?auto=format&fit=crop&w=200&q=60',
    );

    return <ChatThreadEntity>[
      ChatThreadEntity(
        id: 't1',
        user: u1,
        messages: <ChatMessageEntity>[
          ChatMessageEntity(
            id: 'm1',
            threadId: 't1',
            text: 'Hi, is the room still available?',
            createdAt: DateTime.now().subtract(const Duration(hours: 5)),
            isMe: true,
          ),
          ChatMessageEntity(
            id: 'm2',
            threadId: 't1',
            text: 'Yes! When would you like to visit?',
            createdAt: DateTime.now().subtract(
              const Duration(hours: 4, minutes: 50),
            ),
            isMe: false,
          ),
        ],
      ),
      ChatThreadEntity(
        id: 't2',
        user: u2,
        messages: <ChatMessageEntity>[
          ChatMessageEntity(
            id: 'm3',
            threadId: 't2',
            text: 'Does it include parking?',
            createdAt: DateTime.now().subtract(
              const Duration(days: 1, hours: 1),
            ),
            isMe: true,
          ),
          ChatMessageEntity(
            id: 'm4',
            threadId: 't2',
            text: 'Yes, motorbike parking is free.',
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
            isMe: false,
          ),
        ],
      ),
    ];
  }
}
