import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportify/config/theme.dart';
import 'package:sportify/providers/chat_provider.dart';
import 'package:sportify/providers/auth_provider.dart';
import 'package:sportify/screens/chat/chat_screen.dart';
import 'package:sportify/widgets/page_layout.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});
  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  void _load() {
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid != null) context.read<ChatProvider>().loadChats(uid);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final uid = context.watch<AuthProvider>().user?.uid;
    return Scaffold(
      body: CollectionPage(
        header: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageIntro(
                title: 'Keep the game going.',
                subtitle: 'Your people, your plans, all in one place.',
                eyebrow: 'Stay connected',
                icon: Icons.chat_bubble_outline_rounded,
              ),
            ],
          ),
        ),
        body: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.error != null
            ? EmptyState(
                icon: Icons.cloud_off,
                title: 'Chats couldn’t load',
                message: provider.error!,
                onAction: _load,
              )
            : provider.chats.isEmpty
            ? const EmptyState(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Good conversations start with a game',
                message:
                    'Connect with a player or join a game to start chatting.',
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: provider.chats.length,
                separatorBuilder: (_, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final chat = provider.chats[index];
                  final activity = chat.type == 'activity';
                  final other = chat.participantIds.firstWhere(
                    (id) => id != uid,
                    orElse: () => '',
                  );
                  final title = activity
                      ? 'Game conversation'
                      : chat.participantNames[other] ?? 'Player';
                  return Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.surfaceVariant,
                        child: activity
                            ? const Icon(Icons.sports, color: AppColors.primary)
                            : Text(
                                title.isEmpty ? 'P' : title[0],
                                style: const TextStyle(
                                  color: AppColors.primary,
                                ),
                              ),
                      ),
                      title: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        chat.lastMessage ?? 'Say hello and plan a session',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(chat: chat),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
