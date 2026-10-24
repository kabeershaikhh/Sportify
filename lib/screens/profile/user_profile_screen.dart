import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportify/models/user_model.dart';
import 'package:sportify/models/connection_model.dart';
import 'package:sportify/providers/auth_provider.dart';
import 'package:sportify/providers/connection_provider.dart';
import 'package:sportify/providers/chat_provider.dart';
import 'package:sportify/providers/user_provider.dart';
import 'package:sportify/config/constants.dart';
import 'package:sportify/config/theme.dart';
import 'package:sportify/widgets/availability_grid.dart';
import 'package:sportify/services/firestore_service.dart';
import 'package:sportify/screens/chat/chat_screen.dart';
import 'package:sportify/widgets/page_layout.dart';
import 'package:sportify/widgets/compatibility_summary.dart';

class UserProfileScreen extends StatelessWidget {
  final UserModel user;

  const UserProfileScreen({super.key, required this.user});

  Future<void> _reportUser(BuildContext context) async {
    final reporter = context.read<AuthProvider>().user?.uid;
    if (reporter == null) return;
    final controller = TextEditingController();
    bool saving = false;
    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          scrollable: true,
          title: const Text('Report this player'),
          content: TextField(
            controller: controller,
            maxLength: 1000,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Reason for reporting',
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (controller.text.trim().isEmpty) return;
                      setDialogState(() => saving = true);
                      try {
                        await FirestoreService().createReport({
                          'reporterId': reporter,
                          'targetType': 'user',
                          'targetId': user.uid,
                          'reason': controller.text.trim(),
                          'status': 'pending',
                        });
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Report submitted for review.'),
                            ),
                          );
                        }
                      } catch (_) {
                        if (dialogContext.mounted) {
                          setDialogState(() => saving = false);
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Couldn’t send the report. Try again.',
                              ),
                            ),
                          );
                        }
                      }
                    },
              child: ActionLabel(
                busy: saving,
                label: 'Submit report',
                busyLabel: 'Submitting…',
              ),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connProvider = context.watch<ConnectionProvider>();
    final authUser = context.read<AuthProvider>().user;
    final currentUserModel = context.watch<UserProvider>().currentUser;

    // Check connection status with this user
    bool isPending = connProvider.connections.any(
      (c) =>
          (c.fromUserId == authUser?.uid &&
              c.toUserId == user.uid &&
              c.status == 'pending') ||
          (c.toUserId == authUser?.uid &&
              c.fromUserId == user.uid &&
              c.status == 'pending'),
    );
    bool isConnected = connProvider.acceptedConnections.any(
      (c) =>
          (c.fromUserId == authUser?.uid && c.toUserId == user.uid) ||
          (c.toUserId == authUser?.uid && c.fromUserId == user.uid),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(user.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.report_outlined),
            onPressed: () => _reportUser(context),
          ),
        ],
      ),
      body: PageLayout(
        maxWidth: 900,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x252F4FC0),
                      blurRadius: 22,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Hero(
                          tag: 'avatar_${user.uid}',
                          child: CircleAvatar(
                            radius: 34,
                            backgroundColor: const Color(0xFFDBE5FF),
                            backgroundImage: user.photoUrl != null
                                ? NetworkImage(user.photoUrl!)
                                : null,
                            child: user.photoUrl == null
                                ? Text(
                                    user.name.isNotEmpty
                                        ? user.name[0].toUpperCase()
                                        : 'P',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryDark,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  height: 1.2,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                [
                                  user.area,
                                  user.city,
                                ].where((s) => s.isNotEmpty).join(', '),
                                style: const TextStyle(
                                  color: Color(0xFFD5E3FF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (user.bio?.isNotEmpty == true) ...[
                      const SizedBox(height: 18),
                      Text(
                        user.bio!,
                        style: const TextStyle(
                          color: Color(0xFFE1EAFF),
                          height: 1.6,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isConnected ? 'Connected player' : 'Community player',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Card(
                margin: EdgeInsets.zero,
                color: AppColors.lavender,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'YOUR MATCH',
                              style: TextStyle(
                                color: AppColors.primaryDark,
                                fontSize: 11,
                                letterSpacing: 1.4,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      CompatibilitySummary(
                        currentUser: currentUserModel,
                        otherUser: user,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sports',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) => Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: user.sports.map((sport) {
                    final name = (sport['sport'] ?? sport['name'] ?? '')
                        .toString();
                    final icons = AppConstants.sports.where(
                      (s) => s['name'] == name,
                    );
                    return SizedBox(
                      width: constraints.maxWidth >= 600
                          ? (constraints.maxWidth - 12) / 2
                          : constraints.maxWidth,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              icons.isEmpty
                                  ? Icons.sports
                                  : icons.first['icon'] as IconData,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (sport['skillLevel'] != null)
                                    Text(
                                      sport['skillLevel'].toString(),
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Availability',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: AvailabilityGrid(
                    availability: user.availability,
                    isEditable: false,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: isConnected
            ? ElevatedButton.icon(
                onPressed: context.watch<ChatProvider>().isLoading
                    ? null
                    : () async {
                        final chatProvider = context.read<ChatProvider>();
                        await runAction(context, () async {
                          final id = await chatProvider.getOrCreateDirectChat(
                            authUser!.uid,
                            user.uid,
                            currentUserModel?.name ??
                                authUser.displayName ??
                                '',
                            user.name,
                          );
                          final chat = await FirestoreService().getChat(id);
                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(chat: chat),
                              ),
                            );
                          }
                        });
                      },
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 19),
                label: const Text('Chat'),
              )
            : isPending
            ? const ElevatedButton(
                onPressed: null,
                child: Text('Request Pending'),
              )
            : ElevatedButton.icon(
                onPressed: connProvider.isLoading
                    ? null
                    : () {
                        final req = ConnectionModel(
                          id: '',
                          fromUserId: authUser!.uid,
                          fromUserName:
                              currentUserModel?.name ??
                              authUser.displayName ??
                              '',
                          fromUserPhotoUrl:
                              currentUserModel?.photoUrl ?? authUser.photoURL,
                          toUserId: user.uid,
                          toUserName: user.name,
                          toUserPhotoUrl: user.photoUrl,
                          status: 'pending',
                          createdAt: DateTime.now(),
                        );
                        runAction(
                          context,
                          () => context.read<ConnectionProvider>().sendRequest(
                            req,
                          ),
                          success: 'Connection request sent.',
                        );
                      },
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 19),
                label: const Text('Send Request'),
              ),
      ),
    );
  }
}
