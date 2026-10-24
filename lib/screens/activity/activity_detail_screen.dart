import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sportify/config/theme.dart';
import 'package:sportify/models/activity_model.dart';
import 'package:sportify/models/connection_model.dart';
import 'package:sportify/models/game_join_request_model.dart';
import 'package:sportify/providers/activity_provider.dart';
import 'package:sportify/providers/auth_provider.dart';
import 'package:sportify/providers/connection_provider.dart';
import 'package:sportify/providers/user_provider.dart';
import 'package:sportify/services/firestore_service.dart';
import 'package:sportify/screens/chat/chat_screen.dart';
import 'package:sportify/screens/activity/create_activity_screen.dart';
import 'package:sportify/widgets/page_layout.dart';

class ActivityDetailScreen extends StatefulWidget {
  final ActivityModel activity;
  final FirestoreService? firestoreService;
  const ActivityDetailScreen({
    super.key,
    required this.activity,
    this.firestoreService,
  });
  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  late final FirestoreService _service;
  late final Stream<ActivityModel?> _stream;
  Stream<GameJoinRequestModel?>? _joinRequestStream;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _service = widget.firestoreService ?? FirestoreService();
    _stream = _service.streamActivity(widget.activity.id);
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid != null) {
      _joinRequestStream = _service.streamGameJoinRequest(
        widget.activity.id,
        uid,
      );
    }
  }

  Future<void> _askToConnect(
    ActivityModel game,
    String uid, {
    ConnectionModel? incomingRequest,
  }) async {
    final send = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Connect with ${game.hostName}?'),
        content: Text(
          incomingRequest != null
              ? 'The host has sent you a connection request. Accept it here, then you can request a place in this game.'
              : 'You need to be connected with the host before you can request a place in this game. Send a connection request now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              incomingRequest != null ? 'Accept request' : 'Send request',
            ),
          ),
        ],
      ),
    );
    if (send != true || !mounted) return;
    if (incomingRequest != null) {
      await _act(
        () => context.read<ConnectionProvider>().acceptRequest(
          incomingRequest.id,
        ),
        success: 'You’re connected. You can now request to join the game.',
      );
      return;
    }
    final me = context.read<UserProvider>().currentUser;
    await _act(
      () => context.read<ConnectionProvider>().sendRequest(
        ConnectionModel(
          id: '',
          fromUserId: uid,
          fromUserName: me?.name ?? 'Player',
          fromUserPhotoUrl: me?.photoUrl,
          toUserId: game.hostId,
          toUserName: game.hostName,
          toUserPhotoUrl: game.hostPhotoUrl,
          status: 'pending',
          createdAt: DateTime.now(),
        ),
      ),
      success: 'Connection request sent to the host.',
    );
  }

  Future<void> _act(Future<void> Function() action, {String? success}) async {
    setState(() => _busy = true);
    await runAction(context, action, success: success);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Game details')),
    body: PageLayout(
      maxWidth: 760,
      child: StreamBuilder<ActivityModel?>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.cloud_off,
              title: 'Game couldn’t load',
              message: 'Go back and try again when you’re connected.',
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final game = snapshot.data;
          if (game == null) {
            return const EmptyState(
              title: 'Game no longer available',
              message: 'The host may have removed this game.',
            );
          }
          final uid = context.watch<AuthProvider>().user?.uid;
          if (uid == null) {
            return const EmptyState(
              title: 'Sign in to continue',
              message: 'You need an account to join games.',
            );
          }
          final isHost = uid == game.hostId,
              joined = game.participantIds.contains(uid);
          final isHostFriend = context
              .watch<ConnectionProvider>()
              .acceptedConnections
              .any(
                (connection) =>
                    (connection.fromUserId == uid &&
                        connection.toUserId == game.hostId) ||
                    (connection.fromUserId == game.hostId &&
                        connection.toUserId == uid),
              );
          final active =
              game.status != 'cancelled' &&
              game.dateTime.isAfter(DateTime.now());
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.sports_tennis_rounded,
                      size: 42,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '${game.sport} session',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(label: Text(game.skillLevel)),
                        Chip(
                          label: Text(
                            !active
                                ? game.status == 'cancelled'
                                      ? 'Cancelled'
                                      : 'Past game'
                                : game.isFull
                                ? 'Full'
                                : '${game.spotsLeft} open spots',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              ListTile(
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(DateFormat('EEEE, MMMM d').format(game.dateTime)),
                subtitle: Text(DateFormat.jm().format(game.dateTime)),
              ),
              ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(game.venue),
                subtitle: Text(
                  '${game.area}${game.venueAddress == null ? '' : '\n${game.venueAddress}'}',
                ),
              ),
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text(game.hostName),
                subtitle: const Text('Game host'),
              ),
              const SizedBox(height: 20),
              Text(
                'About the session',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                game.description?.isNotEmpty == true
                    ? game.description!
                    : 'Bring your gear and meet at the venue. Coordinate with the host in the group chat.',
              ),
              const SizedBox(height: 24),
              Text(
                'Players · ${game.participantIds.length}/${game.playersNeeded}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: game.playersNeeded > 0
                    ? (game.participantIds.length / game.playersNeeded).clamp(
                        0,
                        1,
                      )
                    : 0,
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 24),
              if (_busy) const LinearProgressIndicator(),
              if (active && isHost) ...[
                FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CreateActivityScreen(activity: game),
                          ),
                        ),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit game'),
                ),
                const SizedBox(height: 12),
              ],
              if (active && isHost)
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              scrollable: true,
                              title: const Text('Cancel this game?'),
                              content: const Text(
                                'Players will see the cancelled status. This game will stop accepting new players.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, false),
                                  child: const Text('Keep game'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, true),
                                  child: const Text('Cancel game'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && mounted) {
                            await _act(
                              () => context
                                  .read<ActivityProvider>()
                                  .cancelActivity(game.id),
                              success: 'Game cancelled.',
                            );
                          }
                        },
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel game'),
                ),
              if (active && !isHost)
                StreamBuilder<GameJoinRequestModel?>(
                  stream: _joinRequestStream,
                  builder: (context, requestSnapshot) {
                    final request = requestSnapshot.data;
                    final relatedConnections = context
                        .watch<ConnectionProvider>()
                        .connections
                        .where(
                          (connection) =>
                              (connection.fromUserId == uid &&
                                  connection.toUserId == game.hostId) ||
                              (connection.fromUserId == game.hostId &&
                                  connection.toUserId == uid),
                        )
                        .toList();
                    final relationship = relatedConnections.isEmpty
                        ? null
                        : relatedConnections.first;
                    final friendRequestPending =
                        relationship?.status == 'pending';
                    final incomingRequest =
                        friendRequestPending && relationship?.toUserId == uid;
                    final status = request?.status;
                    final waiting = status == 'pending';
                    final approved = status == 'accepted';
                    final enabled =
                        !_busy &&
                        (joined ||
                            (!isHostFriend &&
                                (!friendRequestPending || incomingRequest)) ||
                            (isHostFriend &&
                                !game.isFull &&
                                !waiting &&
                                !approved));
                    final label = joined
                        ? 'Leave game'
                        : !isHostFriend
                        ? friendRequestPending
                              ? incomingRequest
                                    ? 'Accept host’s connection request'
                                    : 'Connection request pending'
                              : 'Connect with host first'
                        : waiting
                        ? 'Join request pending'
                        : approved
                        ? 'Host approved your request'
                        : game.isFull
                        ? 'Game is full'
                        : status == 'declined'
                        ? 'Request to join again'
                        : 'Request to join';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton.icon(
                          onPressed: !enabled
                              ? null
                              : () async {
                                  if (joined) {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (dialogContext) => AlertDialog(
                                        icon: const Icon(
                                          Icons.exit_to_app_rounded,
                                        ),
                                        title: const Text('Leave this game?'),
                                        content: const Text(
                                          'Your place will be released. To rejoin, you’ll need the host to approve a new request.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(
                                              dialogContext,
                                              false,
                                            ),
                                            child: const Text('Stay in game'),
                                          ),
                                          FilledButton(
                                            onPressed: () => Navigator.pop(
                                              dialogContext,
                                              true,
                                            ),
                                            child: const Text('Leave game'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed != true || !mounted) return;
                                    await _act(
                                      () => context
                                          .read<ActivityProvider>()
                                          .leaveActivity(game.id, uid),
                                      success: 'You’ve left the game.',
                                    );
                                  } else if (!isHostFriend) {
                                    _askToConnect(
                                      game,
                                      uid,
                                      incomingRequest: incomingRequest
                                          ? relationship
                                          : null,
                                    );
                                  } else {
                                    final me = context
                                        .read<UserProvider>()
                                        .currentUser;
                                    _act(
                                      () => _service.requestToJoinActivity(
                                        activityId: game.id,
                                        requesterId: uid,
                                        requesterName: me?.name ?? 'Player',
                                      ),
                                      success:
                                          'Join request sent. The host must approve it.',
                                    );
                                  }
                                },
                          icon: Icon(
                            joined
                                ? Icons.exit_to_app
                                : !isHostFriend
                                ? Icons.person_add_alt_1
                                : Icons.how_to_reg_outlined,
                          ),
                          label: Text(label),
                        ),
                        if (!isHostFriend && !friendRequestPending)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Send a connection request first. After the host accepts, you can request a place in this game.',
                            ),
                          ),
                        if (waiting)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'You’ll be added after the host accepts.',
                            ),
                          ),
                        if (approved && !joined)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'The host approved your request. Joining…',
                            ),
                          ),
                      ],
                    );
                  },
                ),
              const SizedBox(height: 12),
              if (joined)
                FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _act(() async {
                          final me = context.read<UserProvider>().currentUser;
                          final chat = await _service.createActivityChat(
                            game.id,
                            game.participantIds,
                            {
                              game.hostId: game.hostName,
                              uid: me?.name ?? 'Player',
                            },
                          );
                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(chat: chat),
                              ),
                            );
                          }
                        }),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Open group chat'),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _act(() async {
                  await Clipboard.setData(
                    ClipboardData(
                      text:
                          '${game.sport} with ${game.hostName}\n${DateFormat.yMMMd().add_jm().format(game.dateTime)}\n${game.venue}, ${game.area}\n${game.spotsLeft} spots available. Find this game on Sportify.',
                    ),
                  );
                }, success: 'Game details copied. Share them with your friends.'),
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Copy game details'),
              ),
              const SizedBox(height: 24),
              const Text(
                'Play safely: meet at public venues and let a friend know your plans.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          );
        },
      ),
    ),
  );
}
