import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../data/models/local_user_model.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/entities/app_enums.dart';
import '../../../domain/entities/conversation_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/conversation_provider.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConversationProvider>().loadConversations();
    });
  }

  UserEntity? _findUserSync(String userId) {
    final Box<dynamic> usersBox = Hive.box<dynamic>(HiveBoxes.users);
    final dynamic value = usersBox.get(userId);
    if (value is Map<dynamic, dynamic>) {
      return LocalUserModel.fromMap(value).toEntity();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = context.watch<AuthProvider>().userId;

    return Consumer<ConversationProvider>(
      builder: (BuildContext context, ConversationProvider convProv, _) {
        final List<ConversationEntity> userConversations = convProv
            .getUserConversations(currentUserId);

        return Scaffold(
          appBar: AppBar(title: const Text('Tin nhắn')),
          body: SafeArea(
            child: convProv.isLoading && userConversations.isEmpty
                ? Padding(
                    padding: AppSpacing.paddingAllLg,
                    child: const LoadingPlaceholderList(itemCount: 3),
                  )
                : userConversations.isEmpty
                ? const EmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: 'Chưa có cuộc trò chuyện nào',
                    message:
                        'Nhắn tin với chủ nhà từ trang chi tiết phòng để bắt đầu.',
                  )
                : ListView.separated(
                    key: const PageStorageKey<String>(
                      'chat_list_v2_scroll_key',
                    ),
                    padding: AppSpacing.paddingAllLg,
                    itemCount: userConversations.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (BuildContext context, int i) {
                      final ConversationEntity t = userConversations[i];

                      // Tìm ID của người đối thoại
                      final String otherId = t.participantIds.firstWhere(
                        (String id) => id != currentUserId,
                        orElse: () => 'unknown',
                      );

                      final UserEntity? otherUser = _findUserSync(otherId);

                      final String otherName =
                          otherUser?.username ?? 'Người dùng';
                      final String otherAvatar = otherUser?.avatarPath ?? '';
                      final String otherCode = otherUser?.userCode ?? '';

                      return ListTile(
                        tileColor: AppColors.cardBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.largeAll,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          child: ClipOval(
                            child: AppImage(
                              imagePath: otherAvatar,
                              width: 40,
                              height: 40,
                            ),
                          ),
                        ),
                        title: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                otherName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (context.read<AuthProvider>().hasRole(
                                  UserRole.admin,
                                ) &&
                                otherCode.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  otherCode,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const SizedBox(height: 4),
                            Text(
                              t.lastMessage.isEmpty
                                  ? 'Bắt đầu cuộc hội thoại 👋'
                                  : t.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            if (t.unreadCount > 0 &&
                                t.lastMessageSenderId != currentUserId)
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                child: Text(
                                  '${t.unreadCount}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else
                              const Icon(
                                Icons.chevron_right,
                                color: AppColors.textSecondary,
                              ),
                            const SizedBox(width: 4),
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert,
                                size: 20,
                                color: AppColors.textSecondary,
                              ),
                              padding: EdgeInsets.zero,
                              onSelected: (String val) async {
                                if (val == 'delete') {
                                  final bool? confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (BuildContext dialogContext) =>
                                        AlertDialog(
                                          title: const Text('Xóa hội thoại'),
                                          content: const Text(
                                            'Bạn có chắc chắn muốn xóa cuộc trò chuyện này không?',
                                          ),
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed: () => Navigator.pop(
                                                dialogContext,
                                                false,
                                              ),
                                              child: const Text('Hủy'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(
                                                dialogContext,
                                                true,
                                              ),
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.red,
                                              ),
                                              child: const Text('Xóa'),
                                            ),
                                          ],
                                        ),
                                  );
                                  if (confirm == true) {
                                    await convProv.deleteConversation(t.id);
                                  }
                                }
                              },
                              itemBuilder: (_) => <PopupMenuEntry<String>>[
                                const PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    children: <Widget>[
                                      Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Xóa hội thoại',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ChatDetailScreen(
                                conversationId: t.id,
                                otherParticipantId: otherId,
                              ),
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
