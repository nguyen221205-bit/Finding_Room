import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/app_image.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_placeholder.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    final ChatProvider chatProvider = context.read<ChatProvider>();
    Future<void>.microtask(() => chatProvider.loadThreadsIfNeeded());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (BuildContext context, ChatProvider chat, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Chats')),
          body: SafeArea(
            child: chat.isLoading && chat.threads.isEmpty
                ? Padding(
                    padding: AppSpacing.paddingAllLg,
                    child: const LoadingPlaceholderList(itemCount: 3),
                  )
                : chat.threads.isEmpty
                ? const EmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: 'No chats yet',
                    message: 'Start a chat from a room detail page.',
                  )
                : ListView.separated(
                    key: const PageStorageKey<String>('chat_list_scroll_key'),
                    padding: AppSpacing.paddingAllLg,
                    itemCount: chat.threads.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (BuildContext context, int i) {
                      final t = chat.threads[i];
                      final last = t.lastMessage;
                      return ListTile(
                        tileColor: AppColors.cardBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.largeAll,
                        ),
                        leading: CircleAvatar(
                          child: ClipOval(
                            child: AppImage(
                              imagePath: t.user.avatarUrl,
                              width: 40,
                              height: 40,
                            ),
                          ),
                        ),
                        title: Text(t.user.name),
                        subtitle: Text(
                          last?.text ?? 'Say hi 👋',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        trailing: t.unreadCount > 0
                            ? CircleAvatar(
                                radius: 12,
                                child: Text(
                                  '${t.unreadCount}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ChatDetailScreen(threadId: t.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}
