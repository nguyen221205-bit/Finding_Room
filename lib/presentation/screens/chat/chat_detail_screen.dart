import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../data/models/local_user_model.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/entities/app_enums.dart';
import '../../../domain/entities/message_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/conversation_provider.dart';
import '../../providers/message_provider.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/dismiss_keyboard.dart';

class ChatDetailScreen extends StatefulWidget {
  final String conversationId;
  final String otherParticipantId;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.otherParticipantId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(animated: false);
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  UserEntity? _getOtherUser() {
    final Box<dynamic> usersBox = Hive.box<dynamic>(HiveBoxes.users);
    final dynamic value = usersBox.get(widget.otherParticipantId);
    if (value is Map<dynamic, dynamic>) {
      return LocalUserModel.fromMap(value).toEntity();
    }
    return null;
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;

    final double targetOffset = _scrollController.position.maxScrollExtent;
    if (animated) {
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(targetOffset);
    }
  }

  Future<void> _send() async {
    if (_isSending) return;
    final String text = _msgCtrl.text.trim();
    if (text.isEmpty) {
      AppSnackbar.show(context, 'Vui lòng nhập tin nhắn.');
      return;
    }

    final String currentUserId = context.read<AuthProvider>().userId;
    if (currentUserId.isEmpty) return;

    setState(() => _isSending = true);

    try {
      // 1. Gửi tin nhắn qua MessageProvider
      await context.read<MessageProvider>().sendMessage(
        conversationId: widget.conversationId,
        senderId: currentUserId,
        receiverId: widget.otherParticipantId,
        content: text,
      );

      // 2. Cập nhật tin nhắn cuối cùng trong ConversationProvider
      if (mounted) {
        await context.read<ConversationProvider>().updateLastMessage(
          conversationId: widget.conversationId,
          lastMessage: text,
          lastMessageSenderId: currentUserId,
          incrementUnread: true,
        );
      }

      _msgCtrl.clear();
    } catch (_) {
      if (mounted) {
        AppSnackbar.show(context, 'Gửi tin nhắn thất bại. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = context.watch<AuthProvider>().userId;

    // Đánh dấu đã đọc hội thoại bất đồng bộ khi mở
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || currentUserId.isEmpty) return;
      context.read<MessageProvider>().markAsRead(
        widget.conversationId,
        currentUserId,
      );
      context.read<ConversationProvider>().resetUnreadCount(
        widget.conversationId,
      );
    });

    final UserEntity? otherUser = _getOtherUser();
    final String title = otherUser?.username ?? 'Hội thoại';

    return DismissKeyboard(
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (context.read<AuthProvider>().hasRole(UserRole.admin) &&
                  otherUser != null)
                Text(
                  otherUser.userCode,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.8),
                  ),
                ),
            ],
          ),
        ),
        body: SafeArea(
          child: Consumer2<MessageProvider, ConversationProvider>(
            builder:
                (
                  BuildContext context,
                  MessageProvider msgProv,
                  ConversationProvider convProv,
                  _,
                ) {
                  final List<MessageEntity> messages = msgProv
                      .getConversationMessages(widget.conversationId);
                  final conversation = convProv.getConversationById(
                    widget.conversationId,
                  );

                  // Tự động cuộn khi có tin nhắn mới
                  if (messages.length != _lastMessageCount) {
                    _lastMessageCount = messages.length;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom();
                    });
                  }

                  return Column(
                    children: <Widget>[
                      if (conversation != null &&
                          context.read<AuthProvider>().hasRole(UserRole.admin))
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 12,
                          ),
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.05),
                          child: Center(
                            child: Text(
                              'Mã hội thoại: ${conversation.conversationCode}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: messages.isEmpty
                            ? const Center(
                                child: Text(
                                  'Chưa có tin nhắn nào. Hãy gửi lời chào 👋',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                padding: AppSpacing.paddingAllLg,
                                itemCount: messages.length,
                                itemBuilder: (BuildContext context, int i) {
                                  final MessageEntity msg = messages[i];
                                  return ChatBubble(
                                    message: msg,
                                    isMe: msg.senderId == currentUserId,
                                  );
                                },
                              ),
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          10,
                          AppSpacing.lg,
                          AppSpacing.lg,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          boxShadow: AppShadows.subtle,
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: TextField(
                                controller: _msgCtrl,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _send(),
                                enabled: !_isSending,
                                decoration: const InputDecoration(
                                  hintText: 'Nhập tin nhắn...',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton.filled(
                              onPressed: _isSending ? null : _send,
                              icon: _isSending
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.send),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
          ),
        ),
      ),
    );
  }
}
