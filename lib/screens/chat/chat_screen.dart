import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sportify/config/theme.dart';
import 'package:sportify/models/chat_model.dart';
import 'package:sportify/models/message_model.dart';
import 'package:sportify/providers/chat_provider.dart';
import 'package:sportify/providers/auth_provider.dart';
import 'package:sportify/providers/user_provider.dart';
import 'package:sportify/widgets/page_layout.dart';

class ChatScreen extends StatefulWidget {
  final ChatModel chat;
  const ChatScreen({super.key, required this.chat});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ChatProvider>().loadMessages(widget.chat.id);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    if (text.length > 2000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keep messages under 2000 characters.')),
      );
      return;
    }
    final auth = context.read<AuthProvider>().user;
    if (auth == null) return;
    final name =
        context.read<UserProvider>().currentUser?.name ??
        auth.displayName ??
        'Player';
    setState(() => _sending = true);
    try {
      await context.read<ChatProvider>().sendMessage(
        widget.chat.id,
        MessageModel(
          id: '',
          senderId: auth.uid,
          senderName: name,
          text: text,
          sentAt: DateTime.now(),
        ),
      );
      if (!mounted) return;
      if (_controller.text.trim() == text) _controller.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Message not sent. Your draft is saved here. Try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final uid = context.watch<AuthProvider>().user?.uid;
    final activity = widget.chat.type == 'activity';
    final other = widget.chat.participantIds.firstWhere(
      (id) => id != uid,
      orElse: () => '',
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          activity
              ? 'Game conversation'
              : widget.chat.participantNames[other] ?? 'Conversation',
        ),
      ),
      body: PageLayout(
        maxWidth: 900,
        child: Column(
          children: [
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.error != null
                  ? EmptyState(
                      icon: Icons.cloud_off,
                      title: 'Messages couldn’t load',
                      message: provider.error!,
                      onAction: () => provider.loadMessages(widget.chat.id),
                    )
                  : provider.messages.isEmpty
                  ? const EmptyState(
                      icon: Icons.waving_hand_outlined,
                      title: 'Start with a hello',
                      message:
                          'Coordinate your next game, share a meeting point, or introduce yourself.',
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(20),
                      itemCount: provider.messages.length,
                      itemBuilder: (context, index) {
                        final msg = provider.messages[index],
                            mine = provider.messages[index].senderId == uid;
                        return Align(
                          alignment: mine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.sizeOf(
                                    context,
                                  ).width.clamp(0, 900) *
                                  .75,
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: mine ? AppColors.primary : Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: mine
                                    ? null
                                    : Border.all(color: AppColors.divider),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (activity && !mine)
                                    Text(
                                      msg.senderName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  SelectableText(
                                    msg.text,
                                    style: TextStyle(
                                      color: mine
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat.jm().format(msg.sentAt),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: mine
                                          ? Colors.white70
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines:
                            MediaQuery.sizeOf(context).height -
                                    MediaQuery.viewInsetsOf(context).bottom <
                                400
                            ? 1
                            : 4,
                        maxLength: 2000,
                        decoration: const InputDecoration(
                          hintText: 'Write a message…',
                          counterText: '',
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filled(
                      tooltip: 'Send message',
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
