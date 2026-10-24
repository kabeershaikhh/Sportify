import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sportify/providers/connection_provider.dart';
import 'package:sportify/providers/activity_provider.dart';
import 'package:sportify/providers/auth_provider.dart';
import 'package:sportify/models/game_join_request_model.dart';
import 'package:sportify/services/firestore_service.dart';
import 'package:sportify/screens/activity/activity_detail_screen.dart';
import 'package:sportify/widgets/page_layout.dart';
import 'package:sportify/widgets/requester_preview.dart';

class NotificationsScreen extends StatefulWidget {
  final FirestoreService? firestoreService;
  const NotificationsScreen({super.key, this.firestoreService});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final FirestoreService _service;
  String? _requestUserId;
  Stream<List<GameJoinRequestModel>>? _hostRequests;
  Stream<List<GameJoinRequestModel>>? _myRequests;
  @override
  void initState() {
    super.initState();
    _service = widget.firestoreService ?? FirestoreService();
  }

  @override
  Widget build(BuildContext context) {
    final connections = context.watch<ConnectionProvider>();
    final uid = context.watch<AuthProvider>().user?.uid;
    final games = context
        .watch<ActivityProvider>()
        .activities
        .where(
          (a) =>
              a.participantIds.contains(uid) &&
              a.dateTime.isAfter(DateTime.now()),
        )
        .toList();
    final service = _service;
    if (_requestUserId != uid) {
      _requestUserId = uid;
      _hostRequests = uid == null
          ? null
          : service.streamHostGameJoinRequests(uid);
      _myRequests = uid == null ? null : service.streamMyGameJoinRequests(uid);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Requests & your schedule')),
      body: PageLayout(
        maxWidth: 800,
        child: uid == null
            ? const EmptyState(
                title: 'Sign in to continue',
                message: 'Sign in to see your requests and schedule.',
              )
            : StreamBuilder<List<GameJoinRequestModel>>(
                stream: _hostRequests,
                builder: (context, hostSnapshot) => StreamBuilder<List<GameJoinRequestModel>>(
                  stream: _myRequests,
                  builder: (context, mySnapshot) {
                    final hostRequests = (hostSnapshot.data ?? [])
                        .where((request) => request.status == 'pending')
                        .toList();
                    final myRequests = mySnapshot.data ?? [];
                    if (connections.pendingRequests.isEmpty &&
                        games.isEmpty &&
                        hostRequests.isEmpty &&
                        myRequests.isEmpty) {
                      return const EmptyState(
                        icon: Icons.notifications_none,
                        title: 'You’re all caught up',
                        message:
                            'Connection requests, game requests and your schedule will appear here.',
                      );
                    }
                    return ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        if (hostRequests.isNotEmpty) ...[
                          Text(
                            'Requests to join your games',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          ...hostRequests.map((request) {
                            final matches = context
                                .read<ActivityProvider>()
                                .activities
                                .where(
                                  (activity) =>
                                      activity.id == request.activityId,
                                )
                                .toList();
                            final game = matches.isEmpty ? null : matches.first;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${request.requesterName} wants to join ${game?.sport ?? 'your game'}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (game != null)
                                      Text(
                                        '${game.venue} · ${DateFormat.yMMMd().add_jm().format(game.dateTime)}',
                                      ),
                                    RequesterPreview(
                                      key: ValueKey(
                                        'join-requester-${request.id}',
                                      ),
                                      userId: request.requesterId,
                                      firestoreService: service,
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 10,
                                      children: [
                                        FilledButton.icon(
                                          onPressed:
                                              (game?.isFull ?? false) ||
                                                  context
                                                      .watch<ActivityProvider>()
                                                      .isLoading
                                              ? null
                                              : () => runAction(
                                                  context,
                                                  () => service
                                                      .respondToGameJoinRequest(
                                                        requestId: request.id,
                                                        hostId: uid,
                                                        accept: true,
                                                      ),
                                                  success:
                                                      'Player joined your game.',
                                                ),
                                          icon: const Icon(Icons.check),
                                          label: const Text('Accept'),
                                        ),
                                        OutlinedButton(
                                          onPressed: () => runAction(
                                            context,
                                            () => service
                                                .respondToGameJoinRequest(
                                                  requestId: request.id,
                                                  hostId: uid,
                                                  accept: false,
                                                ),
                                            success: 'Join request declined.',
                                          ),
                                          child: const Text('Decline'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                        if (myRequests.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text(
                            'Your game requests',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          ...myRequests.map((request) {
                            final matches = context
                                .read<ActivityProvider>()
                                .activities
                                .where(
                                  (activity) =>
                                      activity.id == request.activityId,
                                )
                                .toList();
                            final game = matches.isEmpty ? null : matches.first;
                            final message = switch (request.status) {
                              'accepted' => 'The host accepted. You’re in!',
                              'declined' =>
                                'The host couldn’t approve this request.',
                              _ => 'Waiting for the host to respond.',
                            };
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: Icon(
                                  request.status == 'accepted'
                                      ? Icons.check_circle_outline
                                      : request.status == 'declined'
                                      ? Icons.cancel_outlined
                                      : Icons.hourglass_top,
                                ),
                                title: Text(
                                  '${game?.sport ?? 'Game'} · $message',
                                ),
                                subtitle: game == null
                                    ? null
                                    : Text(
                                        '${game.venue}\n${DateFormat.yMMMd().add_jm().format(game.dateTime)}',
                                      ),
                                isThreeLine: game != null,
                              ),
                            );
                          }),
                        ],
                        if (connections.pendingRequests.isNotEmpty) ...[
                          Text(
                            'Connection requests',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          ...connections.pendingRequests.map(
                            (request) => Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${request.fromUserName} wants to connect',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    RequesterPreview(
                                      key: ValueKey(
                                        'friend-requester-${request.id}',
                                      ),
                                      userId: request.fromUserId,
                                      firestoreService: service,
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 8,
                                      children: [
                                        FilledButton.icon(
                                          onPressed: connections.isLoading
                                              ? null
                                              : () => runAction(
                                                  context,
                                                  () =>
                                                      connections.acceptRequest(
                                                        request.id,
                                                      ),
                                                  success:
                                                      'You’re connected. Open their profile to chat.',
                                                ),
                                          icon: const Icon(Icons.check),
                                          label: const Text('Accept'),
                                        ),
                                        OutlinedButton(
                                          onPressed: connections.isLoading
                                              ? null
                                              : () => runAction(
                                                  context,
                                                  () => connections
                                                      .declineRequest(
                                                        request.id,
                                                      ),
                                                  success: 'Request declined.',
                                                ),
                                          child: const Text('Decline'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (games.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text(
                            'Your upcoming games',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          ...games.map(
                            (game) => Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: const Icon(Icons.sports),
                                title: Text(
                                  '${game.sport}${game.status == 'cancelled' ? ' · Cancelled' : ''}',
                                ),
                                subtitle: Text(
                                  '${game.venue}\n${DateFormat.yMMMd().add_jm().format(game.dateTime)}',
                                ),
                                isThreeLine: true,
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ActivityDetailScreen(activity: game),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
      ),
    );
  }
}
