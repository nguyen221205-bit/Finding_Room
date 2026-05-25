import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../domain/entities/chat_entities.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/dismiss_keyboard.dart';

class ChatDetailScreen extends StatefulWidget {
  final String threadId;

  const ChatDetailScreen({super.key, required this.threadId});

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

  Future<void> _send(ChatProvider chat) async {
    if (_isSending) return;
    final String text = _msgCtrl.text.trim();
    if (text.isEmpty) {
      AppSnackbar.show(context, 'Please type a message first.');
      return;
    }

    setState(() => _isSending = true);
    chat.sendMessage(threadId: widget.threadId, text: text);
    _msgCtrl.clear();
    
    // Smooth delay and then check mounted
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    
    setState(() => _isSending = false);
    // Force scroll to bottom after layout updates
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ChatProvider>().markThreadRead(widget.threadId);
    });

    return DismissKeyboard(
      child: Consumer<ChatProvider>(
        builder: (BuildContext context, ChatProvider chat, _) {
          final thread = chat.threadById(widget.threadId);
          final List<ChatMessageEntity> messages = thread == null
              ? <ChatMessageEntity>[]
              : thread.messages;

          // Auto-scroll when a new message arrives from the other party
          if (messages.length != _lastMessageCount) {
            _lastMessageCount = messages.length;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
          }

          return Scaffold(
            appBar: AppBar(title: Text(thread?.user.name ?? 'Chat')),
            body: SafeArea(
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: AppSpacing.paddingAllLg,
                      itemCount: messages.length,
                      itemBuilder: (BuildContext context, int i) {
                        return ChatBubble(message: messages[i]);
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
                            onSubmitted: (_) => _send(chat),
                            enabled: !_isSending,
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton.filled(
                          onPressed: _isSending ? null : () => _send(chat),
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
              ),
            ),
          );
        },
      ),
    );
  }
}

