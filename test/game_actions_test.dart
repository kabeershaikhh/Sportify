import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sportify/models/activity_model.dart';
import 'package:sportify/models/connection_model.dart';
import 'package:sportify/models/game_join_request_model.dart';
import 'package:sportify/models/user_model.dart';
import 'package:sportify/providers/activity_provider.dart';
import 'package:sportify/providers/auth_provider.dart';
import 'package:sportify/providers/connection_provider.dart';
import 'package:sportify/providers/chat_provider.dart';
import 'package:sportify/providers/user_provider.dart';
import 'package:sportify/screens/activity/activity_detail_screen.dart';
import 'package:sportify/screens/notifications/notifications_screen.dart';
import 'package:sportify/screens/profile/user_profile_screen.dart';
import 'package:sportify/services/auth_service.dart';
import 'package:sportify/services/firestore_service.dart';
import 'package:sportify/config/theme.dart';
import 'package:sportify/widgets/page_layout.dart';

class _User implements User {
  @override
  final String uid;
  _User(this.uid);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Auth extends AuthService {
  final User _user;
  _Auth(String uid) : _user = _User(uid);
  @override
  User get currentUser => _user;
  @override
  Stream<User?> get authStateChanges => Stream.value(_user);
}

ActivityModel _game() => ActivityModel(
  id: 'game',
  hostId: 'host',
  hostName: 'Host',
  sport: 'Cricket',
  skillLevel: 'Beginner',
  area: 'Qasimabad',
  venue: 'Public court',
  dateTime: DateTime.now().add(const Duration(days: 7)),
  playersNeeded: 4,
  participantIds: ['host', 'friend'],
  createdAt: DateTime(2026),
);

class _Database extends FirestoreService {
  ActivityModel game = _game();
  ActivityModel? edited;
  ConnectionModel? sentRequest;
  List<ConnectionModel> connections = [];
  List<GameJoinRequestModel> joinRequests = [];
  final Map<String, UserModel> profiles = {};
  final changes = StreamController<ActivityModel>.broadcast();
  @override
  Stream<ActivityModel?> streamActivity(String id) async* {
    yield game;
    yield* changes.stream;
  }

  @override
  Stream<GameJoinRequestModel?> streamGameJoinRequest(
    String gameId,
    String uid,
  ) => Stream.value(null);
  @override
  Stream<List<ConnectionModel>> getConnections(String uid) =>
      Stream.value(connections);
  @override
  Stream<List<GameJoinRequestModel>> streamHostGameJoinRequests(
    String hostId,
  ) => Stream.value(
    joinRequests.where((request) => request.hostId == hostId).toList(),
  );
  @override
  Stream<List<GameJoinRequestModel>> streamMyGameJoinRequests(String uid) =>
      Stream.value(
        joinRequests.where((request) => request.requesterId == uid).toList(),
      );
  @override
  Stream<UserModel?> streamUser(String uid) => Stream.value(profiles[uid]);
  @override
  Future<bool> checkExistingConnection(
    String fromUserId,
    String toUserId,
  ) async => false;
  @override
  Future<void> createConnection(ConnectionModel connection) async {
    sentRequest = connection;
  }

  @override
  Future<UserModel?> getUser(String uid) async =>
      profiles[uid] ??
      UserModel(
        uid: uid,
        name: 'Player Name',
        email: 'player@example.com',
        createdAt: DateTime(2026),
      );
  @override
  Future<void> editActivityDetails(
    ActivityModel activity,
    String hostId,
  ) async {
    expect(hostId, 'host');
    edited = activity;
    game = activity;
    changes.add(game);
  }

  @override
  Future<ActivityModel?> getActivity(String id) async => game;
  @override
  Stream<List<ActivityModel>> streamActivities({String? sport, String? area}) =>
      Stream.value([game]);
}

Future<void> _open(
  WidgetTester tester,
  _Database database,
  String uid, {
  Widget? page,
  Size size = const Size(1000, 1400),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final userProvider = UserProvider(firestoreService: database);
  await userProvider.loadUserProfile(uid);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService: _Auth(uid)),
        ),
        ChangeNotifierProvider(
          create: (_) => ActivityProvider(firestoreService: database),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              ConnectionProvider(firestoreService: database)
                ..loadConnections(uid),
        ),
        ChangeNotifierProvider(create: (_) => userProvider),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(firestoreService: database),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home:
            page ??
            ActivityDetailScreen(
              activity: database.game,
              firestoreService: database,
            ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final size in [const Size(360, 800), const Size(1440, 1000)]) {
    testWidgets(
      'Profile chat action is compact and clears the system gesture area at $size',
      (tester) async {
        final database = _Database();
        final player = UserModel(
          uid: 'other',
          name: 'Ahmed Sports Player',
          email: 'other@example.com',
          area: 'Qasimabad',
          sports: [
            {'sport': 'Cricket', 'skillLevel': 'Intermediate'},
          ],
          availability: {
            'fri': ['evening'],
            'sat': ['evening'],
          },
          createdAt: DateTime(2026),
          isProfileComplete: true,
        );
        database.connections = [
          ConnectionModel(
            id: 'accepted',
            fromUserId: 'other',
            fromUserName: player.name,
            toUserId: 'host',
            toUserName: 'Host',
            status: 'accepted',
            createdAt: DateTime(2026),
          ),
        ];
        await _open(
          tester,
          database,
          'host',
          size: size,
          page: MediaQuery(
            data: MediaQueryData(
              size: size,
              padding: const EdgeInsets.only(top: 24, bottom: 24),
              viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
            ),
            child: UserProfileScreen(user: player),
          ),
        );
        final button = find
            .ancestor(
              of: find.text('Chat'),
              matching: find.byWidgetPredicate(
                (widget) => widget is ElevatedButton,
              ),
            )
            .first;
        final bounds = tester.getRect(button);
        expect(bounds.width, lessThanOrEqualTo(360));
        expect(bounds.bottom, lessThanOrEqualTo(size.height - 24 - 14));
        expect(bounds.center.dx, closeTo(size.width / 2, 1));
        expect(find.byType(BottomActionBar), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await database.changes.close();
      },
    );
  }

  for (final gameRequest in [false, true]) {
    testWidgets(
      '${gameRequest ? 'game join' : 'friend'} request shows compatibility and opens the requester profile',
      (tester) async {
        final database = _Database();
        for (final uid in ['host', 'requester']) {
          database.profiles[uid] = UserModel(
            uid: uid,
            name: uid == 'host' ? 'Host' : 'Requesting Player',
            email: '$uid@example.com',
            area: 'Qasimabad',
            bio: 'Available for community cricket.',
            sports: [
              {'sport': 'Cricket', 'skillLevel': 'Beginner'},
            ],
            availability: {
              'mon': ['evening'],
            },
            createdAt: DateTime(2026),
            isProfileComplete: true,
          );
        }
        database.connections = [
          ConnectionModel(
            id: 'friend-request',
            fromUserId: 'requester',
            fromUserName: 'Requesting Player',
            toUserId: 'host',
            toUserName: 'Host',
            status: gameRequest ? 'accepted' : 'pending',
            createdAt: DateTime(2026),
          ),
        ];
        if (gameRequest) {
          database.joinRequests = [
            GameJoinRequestModel(
              id: 'game_requester',
              activityId: 'game',
              requesterId: 'requester',
              requesterName: 'Requesting Player',
              hostId: 'host',
              status: 'pending',
              createdAt: DateTime(2026),
            ),
          ];
        }
        await _open(
          tester,
          database,
          'host',
          page: NotificationsScreen(firestoreService: database),
          size: const Size(360, 900),
        );
        expect(find.text('100% compatibility'), findsOneWidget);
        expect(find.text('Shared sports: Cricket'), findsOneWidget);
        expect(find.text('Cricket · Beginner'), findsOneWidget);
        expect(find.text('Mon · Evening'), findsOneWidget);
        await tester.ensureVisible(find.text('Explore profile'));
        await tester.tap(find.text('Explore profile'));
        await tester.pumpAndSettle();
        expect(find.byType(UserProfileScreen), findsOneWidget);
        expect(find.text('Requesting Player'), findsWidgets);
        expect(find.text('100% compatibility'), findsOneWidget);
        expect(find.text('Available for community cricket.'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('Explore profile'), findsOneWidget);
        expect(
          database.connections.single.status,
          gameRequest ? 'accepted' : 'pending',
        );
        if (gameRequest) expect(database.joinRequests.single.status, 'pending');
        await tester.pumpWidget(const SizedBox());
        await database.changes.close();
      },
    );
  }

  testWidgets(
    'missing requester profile does not invent compatibility or offer a stale profile',
    (tester) async {
      final database = _Database();
      database.connections = [
        ConnectionModel(
          id: 'missing',
          fromUserId: 'deleted',
          fromUserName: 'Deleted Player',
          toUserId: 'host',
          toUserName: 'Host',
          status: 'pending',
          createdAt: DateTime(2026),
        ),
      ];
      await _open(
        tester,
        database,
        'host',
        page: NotificationsScreen(firestoreService: database),
      );
      expect(
        find.text(
          'Player profile is unavailable. Compatibility cannot be checked.',
        ),
        findsOneWidget,
      );
      expect(find.text('Explore profile'), findsNothing);
      expect(find.text('0% compatibility'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await database.changes.close();
    },
  );

  testWidgets(
    'non-friend can send a connection request directly from game details',
    (tester) async {
      final database = _Database();
      await _open(tester, database, 'player');
      final connect = find.text('Connect with host first');
      await tester.ensureVisible(connect);
      await tester.tap(connect);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(database.sentRequest, isNull);
      await tester.tap(find.text('Send request'));
      await tester.pumpAndSettle();
      expect(database.sentRequest?.fromUserId, 'player');
      expect(database.sentRequest?.toUserId, 'host');
      expect(database.sentRequest?.status, 'pending');
      expect(find.text('Connection request sent to the host.'), findsOneWidget);
      expect(find.text('Edit game'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await database.changes.close();
    },
  );

  testWidgets(
    'host opens a prefilled editor and saves without losing participants',
    (tester) async {
      final database = _Database();
      final original = database.game;
      await _open(tester, database, 'host');
      await tester.ensureVisible(find.text('Edit game'));
      await tester.tap(find.text('Edit game'));
      await tester.pumpAndSettle();
      expect(find.text('Save changes'), findsOneWidget);
      final venue = find.widgetWithText(TextFormField, 'Public venue name');
      await tester.ensureVisible(venue);
      await tester.enterText(venue, 'Updated court');
      final capacity = find.widgetWithText(TextFormField, 'Total players');
      await tester.ensureVisible(capacity);
      await tester.enterText(capacity, '3');
      await tester.ensureVisible(find.text('Save changes'));
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
      expect(database.edited?.venue, 'Updated court');
      expect(database.edited?.playersNeeded, 3);
      expect(database.edited?.participantIds, original.participantIds);
      expect(database.edited?.hostId, original.hostId);
      expect(database.edited?.createdAt, original.createdAt);
      expect(find.text('Updated court'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await database.changes.close();
    },
  );
}
