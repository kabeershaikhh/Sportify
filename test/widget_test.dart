import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sportify/config/theme.dart';
import 'package:sportify/models/activity_model.dart';
import 'package:sportify/models/chat_model.dart';
import 'package:sportify/models/connection_model.dart';
import 'package:sportify/models/user_model.dart';
import 'package:sportify/models/venue_model.dart';
import 'package:sportify/models/message_model.dart';
import 'package:sportify/services/auth_service.dart';
import 'package:sportify/services/firestore_service.dart';
import 'package:sportify/services/matching_service.dart';
import 'package:sportify/widgets/availability_grid.dart';
import 'package:sportify/widgets/activity_card.dart';
import 'package:sportify/app.dart';
import 'package:sportify/screens/onboarding/sports_selection_screen.dart';
import 'package:sportify/screens/onboarding/availability_screen.dart';
import 'package:sportify/screens/chat/chat_screen.dart';
import 'package:sportify/screens/discover/discover_screen.dart';
import 'package:sportify/widgets/user_card.dart';

class _User implements User {
  final String id;
  _User([this.id = 'player-1']);
  @override
  String get uid => id;
  @override
  String? get email => 'player@example.com';
  @override
  bool get emailVerified => true;
  @override
  String? get displayName => 'Aisha Khan';
  @override
  String? get photoURL => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Auth extends AuthService {
  User? signedInUser;
  final _changes = StreamController<User?>.broadcast();
  _Auth(this.signedInUser);
  @override
  User? get currentUser => signedInUser;
  @override
  Stream<User?> get authStateChanges async* {
    yield signedInUser;
    yield* _changes.stream;
  }

  void change(User? user) {
    signedInUser = user;
    _changes.add(user);
  }

  @override
  Future<void> signOut() async => change(null);
}

UserModel _profile({
  String uid = 'player-1',
  bool complete = true,
  String area = 'Latifabad',
  List<Map<String, dynamic>>? sports,
  Map<String, List<String>>? availability,
}) => UserModel(
  uid: uid,
  name: 'Aisha Khan',
  email: 'player@example.com',
  area: area,
  isProfileComplete: complete,
  sports:
      sports ??
      [
        {'sport': 'Cricket', 'skillLevel': 'Intermediate'},
      ],
  availability:
      availability ??
      {
        'mon': ['evening'],
      },
  createdAt: DateTime(2026),
);

class _Database extends FirestoreService {
  UserModel? profile;
  bool failProfile = false;
  bool failUpdate = false;
  Map<String, dynamic>? updated;
  List<ActivityModel> games = [];
  List<UserModel> players = [];
  List<VenueModel> venues = [];
  List<ChatModel> chats = [];
  List<ConnectionModel> connections = [];
  int cancelledConnectionStreams = 0;
  _Database(this.profile);
  @override
  Future<UserModel?> getUser(String uid) async {
    if (failProfile) throw StateError('offline');
    return profile;
  }

  @override
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    if (failUpdate) throw StateError('Profile update failed');
    updated = data;
    profile = UserModel.fromMap({...profile!.toMap(), ...data}, uid);
  }

  @override
  Future<void> createUser(UserModel user) async {
    profile = user;
  }

  @override
  Stream<List<ActivityModel>> streamActivities({String? sport, String? area}) =>
      Stream.value(games);
  @override
  Stream<List<ConnectionModel>> getConnections(String userId) {
    late StreamController<List<ConnectionModel>> controller;
    controller = StreamController(
      onListen: () => controller.add(connections),
      onCancel: () {
        cancelledConnectionStreams++;
      },
    );
    return controller.stream;
  }

  @override
  Stream<List<ChatModel>> getUserChats(String userId) => Stream.value(chats);
  @override
  Stream<List<MessageModel>> getMessages(String chatId) => Stream.value([]);
  @override
  Future<List<UserModel>> getUsersByFilters({
    String? sport,
    String? area,
    String? skillLevel,
  }) async => players;
  @override
  Future<List<VenueModel>> getVenues({String? sport, String? area}) async =>
      venues;
}

Widget _app(_Database db, {bool signedIn = true}) => SportifyApp(
  authService: _Auth(signedIn ? _User() : null),
  firestoreService: db,
);
void main() {
  testWidgets(
    'Mobile navigation uses single-word labels above Android gesture inset',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
      tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      await tester.pumpWidget(_app(_Database(_profile())));
      await tester.pumpAndSettle();
      final destinations = tester.widgetList<NavigationDestination>(
        find.byType(NavigationDestination),
      );
      expect(destinations.map((item) => item.label), [
        'Home',
        'Players',
        'Games',
        'Venues',
        'Chats',
        'Profile',
      ]);
      expect(
        tester.getBottomRight(find.byType(NavigationBar)).dy,
        lessThanOrEqualTo(776),
      );
      await tester.tap(find.byTooltip('Find partners'));
      await tester.pumpAndSettle();
      expect(find.byType(DiscoverScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Find partners recovers when filter header temporarily has zero width',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final width = ValueNotifier<double>(900);
      await tester.pumpWidget(_app(_Database(_profile())));
      await tester.pumpAndSettle();
      tester
          .state<NavigatorState>(find.byType(Navigator))
          .push(
            MaterialPageRoute(
              builder: (_) => Align(
                alignment: Alignment.topLeft,
                child: ValueListenableBuilder<double>(
                  valueListenable: width,
                  child: DiscoverScreen(),
                  builder: (_, value, child) =>
                      SizedBox(width: value, child: child),
                ),
              ),
            ),
          );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Saved search');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cricket').last);
      await tester.pumpAndSettle();
      for (final available in [
        40.0,
        0.0,
        41.0,
        199.0,
        200.0,
        320.0,
        372.0,
        640.0,
        900.0,
      ]) {
        width.value = available;
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason:
              'Page width $available (40px padding gives a zero-width filter header)',
        );
      }
      expect(find.byType(DiscoverScreen, skipOffstage: false), findsOneWidget);
      expect(find.byType(TextField, skipOffstage: false), findsOneWidget);
      await tester.ensureVisible(find.byType(TextField, skipOffstage: false));
      await tester.pumpAndSettle();
      expect(find.text('Saved search'), findsOneWidget);
      expect(find.text('Cricket'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      width.dispose();
    },
  );

  testWidgets(
    'Find partners survives desktop to mobile resizing with active filters',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final database = _Database(_profile())
        ..players = [_profile(uid: 'other')];
      await tester.pumpWidget(_app(database));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Find partners'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Aisha');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cricket').last);
      await tester.pumpAndSettle();
      for (final size in [
        const Size(360, 800),
        const Size(640, 800),
        const Size(599, 800),
        const Size(1280, 900),
        const Size(360, 800),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'Find partners resize to $size',
        );
        expect(find.text('Aisha'), findsOneWidget);
        expect(find.text('Cricket'), findsWidgets);
      }
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = const Size(720, 1600);
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final semantics = tester.ensureSemantics();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      semantics.dispose();
      debugDefaultTargetPlatformOverride = null;
      await tester.pumpAndSettle();
    },
  );

  testWidgets('Login buttons and chat composer fit a short phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 240);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(_app(_Database(null), signedIn: false));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Sign in with Google'),
      160,
      scrollable: find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(_app(_Database(_profile())));
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chat: ChatModel(
                id: 'chat',
                type: 'direct',
                participantIds: ['player-1', 'other'],
                participantNames: {'other': 'Another player'},
                createdAt: DateTime.now(),
              ),
            ),
          ),
        );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'A message with\nseveral lines\nthat should scroll\nin a short window',
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('Selected page survives crossing the navigation breakpoint', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(899, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(_Database(_profile())));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'Games'));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(900, 300);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
    expect(
      tester.widget<ListTile>(find.widgetWithText(ListTile, 'Games')).selected,
      isTrue,
    );
    tester.view.physicalSize = const Size(320, 240);
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Onboarding skills wrap and availability scrolls on a short phone',
    (tester) async {
      tester.view.physicalSize = const Size(320, 240);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SportsSelectionScreen(profileData: {}),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Cricket'), 100);
      await tester.tap(find.text('Cricket'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.widgetWithText(ChoiceChip, 'Intermediate'),
        100,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AvailabilityScreen(profileData: {}),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -220),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final gridScroll = find.descendant(
        of: find.byType(AvailabilityGrid),
        matching: find.byType(Scrollable),
      );
      expect(
        tester.state<ScrollableState>(gridScroll).position.maxScrollExtent,
        greaterThan(0),
      );
      final firstSlot = find
          .descendant(
            of: find.byType(AvailabilityGrid),
            matching: find.byType(InkWell),
          )
          .first;
      await tester.ensureVisible(firstSlot);
      await tester.pumpAndSettle();
      await tester.dragFrom(tester.getCenter(firstSlot), const Offset(-400, 0));
      await tester.pumpAndSettle();
      expect(
        tester.state<ScrollableState>(gridScroll).position.pixels,
        greaterThan(0),
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Forms and report dialogs fit a phone with keyboard insets', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 350);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(_app(_Database(_profile())));
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    navigator.pushNamed('/create-activity');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Publish game'),
      180,
      scrollable: find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .first,
    );
    expect(tester.takeException(), isNull);
    navigator.pop();
    tester.view.viewInsets = const FakeViewPadding();
    navigator.pushNamed('/settings');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Report a problem'), 180);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Report a problem'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 350);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final size in [
    const Size(320, 480),
    const Size(320, 240),
    const Size(640, 320),
    const Size(899, 300),
    const Size(900, 300),
    const Size(1280, 300),
  ]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets('All destinations fit $size with text scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final db = _Database(_profile());
        if (scale > 1) {
          db.players = [
            _profile(
              uid: 'other',
            ).copyWith(name: 'A player with a long display name'),
          ];
          db.games = [
            ActivityModel(
              id: 'game',
              hostId: 'player-1',
              hostName: 'Aisha Khan',
              sport: 'Table Tennis',
              skillLevel: 'Intermediate',
              area: 'Latifabad',
              venue: 'A community sports court with a long venue name',
              dateTime: DateTime.now().add(const Duration(days: 1)),
              playersNeeded: 4,
              participantIds: ['player-1'],
              createdAt: DateTime.now(),
            ),
          ];
          db.venues = [
            VenueModel(
              id: 'court',
              name: 'A community sports court with a long venue name',
              address:
                  'A public venue address with enough detail to wrap across lines',
              area: 'Latifabad',
              sports: ['Table Tennis', 'Cricket'],
              status: 'approved',
              createdAt: DateTime.now(),
            ),
          ];
          db.chats = [
            ChatModel(
              id: 'chat',
              type: 'direct',
              participantIds: ['player-1', 'other'],
              participantNames: {'other': 'A player with a long display name'},
              createdAt: DateTime.now(),
            ),
          ];
        }
        await tester.pumpWidget(_app(db));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        for (final label in [
          'Find partners',
          'Games',
          'Venues',
          'Messages',
          'Profile',
          'Overview',
        ]) {
          if (size.width >= 900) {
            final sidebar = find.byKey(const ValueKey('desktop-navigation'));
            final tile = find.descendant(
              of: sidebar,
              matching: find.widgetWithText(ListTile, label),
            );
            await tester.scrollUntilVisible(
              tile,
              label == 'Overview' ? -180 : 100,
              scrollable: find.descendant(
                of: sidebar,
                matching: find.byType(Scrollable),
              ),
            );
            await tester.tap(tile);
          } else {
            await tester.tap(find.byTooltip(label));
          }
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '$label at $size / $scale',
          );
          final contentScroll = find
              .byWidgetPredicate(
                (widget) =>
                    widget is Scrollable &&
                    widget.axisDirection == AxisDirection.down,
              )
              .last;
          final position = tester
              .state<ScrollableState>(contentScroll)
              .position;
          position.jumpTo(position.maxScrollExtent);
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: 'Scrolled $label at $size / $scale',
          );
        }
      });
    }
  }
  for (final height in [500.0, 320.0]) {
    testWidgets('Desktop navigation scrolls at $height px height', (
      tester,
    ) async {
      tester.view.physicalSize = Size(1000, height);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(_app(_Database(_profile())));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final sidebar = find.byKey(const ValueKey('desktop-navigation'));
      await tester.scrollUntilVisible(
        find.descendant(of: sidebar, matching: find.text('Settings')),
        150,
        scrollable: find.descendant(
          of: sidebar,
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Settings').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  if (Platform.environment['SPORTIFY_CAPTURE_UI'] == '1') {
    setUpAll(() async {
      final file = File(
        '${Platform.environment['WINDIR']}\\Fonts\\segoeui.ttf',
      );
      if (await file.exists()) {
        final loader = FontLoader('Roboto')
          ..addFont(
            Future.value(ByteData.sublistView(await file.readAsBytes())),
          );
        await loader.load();
      }
      final icons = Platform.environment['SPORTIFY_ICON_FONT'];
      if (icons != null) {
        final loader = FontLoader('MaterialIcons')
          ..addFont(
            Future.value(ByteData.sublistView(await File(icons).readAsBytes())),
          );
        await loader.load();
      }
    });
    for (final width in [390.0, 1440.0]) {
      testWidgets('UI preview at $width px', (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final key = GlobalKey();
        final database =
            _Database(
                _profile(
                  availability: {
                    'fri': ['evening'],
                    'sat': ['evening'],
                  },
                ),
              )
              ..players = [
                _profile(
                  uid: 'other',
                  availability: {
                    'fri': ['evening'],
                    'sat': ['evening'],
                  },
                ).copyWith(
                  name: 'Ahmed Khan',
                  bio:
                      'Always up for a friendly match and a good team. Let’s make time to play.',
                ),
              ]
              ..connections = [
                ConnectionModel(
                  id: 'accepted',
                  fromUserId: 'other',
                  fromUserName: 'Ahmed Khan',
                  toUserId: 'player-1',
                  toUserName: 'Aisha Khan',
                  status: 'accepted',
                  createdAt: DateTime(2026),
                ),
              ];
        await tester.pumpWidget(
          RepaintBoundary(key: key, child: _app(database)),
        );
        await tester.pumpAndSettle();
        Future<void> capture(String page) => tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final picture = await boundary.toImage(pixelRatio: 1);
          final bytes = await picture.toByteData(
            format: ui.ImageByteFormat.png,
          );
          final output = File(
            'docs/previews/$page-${width < 900 ? 'mobile' : 'desktop'}.png',
          );
          await output.parent.create(recursive: true);
          await output.writeAsBytes(bytes!.buffer.asUint8List());
          picture.dispose();
        });
        await capture('dashboard');
        await tester.tap(
          width < 900
              ? find.byTooltip('Find partners')
              : find.widgetWithText(ListTile, 'Find partners'),
        );
        await tester.pumpAndSettle();
        await capture('partners');
        await tester.ensureVisible(find.byType(UserCard).first);
        await tester.tap(find.byType(UserCard).first);
        await tester.pumpAndSettle();
        await capture('profile');
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets(
    'Signing out disposes old account streams and another account loads cleanly',
    (tester) async {
      final auth = _Auth(_User());
      final db = _Database(_profile());
      await tester.pumpWidget(
        SportifyApp(authService: auth, firestoreService: db),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hey, Aisha.'), findsOneWidget);
      auth.change(null);
      await tester.pumpAndSettle();
      expect(find.text('Login'), findsWidgets);
      expect(db.cancelledConnectionStreams, 1);
      db.profile = _profile(uid: 'player-2').copyWith(name: 'Bilal Ahmed');
      auth.change(_User('player-2'));
      await tester.pumpAndSettle();
      expect(find.text('Hey, Bilal.'), findsOneWidget);
      expect(find.text('Hey, Aisha.'), findsNothing);
    },
  );
  testWidgets(
    'First-time setup saves completion and is skipped on the next app launch',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = _Database(null);
      await tester.pumpWidget(_app(db));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Latifabad').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cricket'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Cricket'), findsWidgets);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      tester.widget<AvailabilityGrid>(find.byType(AvailabilityGrid)).onToggle!(
        'mon',
        'evening',
      );
      await tester.pump();
      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle();
      expect(db.profile!.isProfileComplete, isTrue);
      expect(find.text('Hey, Aisha.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pumpWidget(_app(db));
      await tester.pumpAndSettle();
      expect(find.text('Setup Profile'), findsNothing);
      expect(find.text('Hey, Aisha.'), findsOneWidget);
    },
  );
  testWidgets('Hosting and Joined filters show only the correct games', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ActivityModel game(
      String id,
      String host,
      String venue,
      List<String> players,
    ) => ActivityModel(
      id: id,
      hostId: host,
      hostName: host,
      sport: 'Cricket',
      skillLevel: 'Beginner',
      area: 'Latifabad',
      dateTime: DateTime.now().add(const Duration(days: 1)),
      venue: venue,
      playersNeeded: 4,
      participantIds: players,
      createdAt: DateTime.now(),
    );
    final db = _Database(_profile())
      ..games = [
        game('a', 'player-1', 'Hosted court', ['player-1']),
        game('b', 'other', 'Joined court', ['other', 'player-1']),
        game('c', 'someone', 'Other court', ['someone']),
      ];
    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Games'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hosting'));
    await tester.pumpAndSettle();
    expect(find.text('Hosted court, Latifabad'), findsOneWidget);
    expect(find.text('Other court, Latifabad'), findsNothing);
    await tester.tap(find.text('Joined'));
    await tester.pumpAndSettle();
    expect(find.text('Joined court, Latifabad'), findsOneWidget);
    expect(find.text('Hosted court, Latifabad'), findsNothing);
  });
  testWidgets('Authentication is required before any player dashboard', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_Database(null), signedIn: false));
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsWidgets);
    expect(find.text('Your next sessions'), findsNothing);
  });
  testWidgets('A first-time account enters profile setup', (tester) async {
    await tester.pumpWidget(_app(_Database(null)));
    await tester.pumpAndSettle();
    expect(find.text('Setup Profile'), findsOneWidget);
    expect(find.text('Your next sessions'), findsNothing);
  });
  for (final width in [360.0, 1440.0]) {
    testWidgets('Completed profile skips setup and dashboard fits $width px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_app(_Database(_profile())));
      await tester.pumpAndSettle();
      expect(find.text('Hey, Aisha.'), findsOneWidget);
      expect(find.text('Setup Profile'), findsNothing);
      expect(tester.takeException(), isNull);
      expect(
        find.byType(NavigationBar),
        width < 900 ? findsOneWidget : findsNothing,
      );
    });
  }
  testWidgets('Profile load errors show retry instead of restarting setup', (
    tester,
  ) async {
    final db = _Database(_profile())..failProfile = true;
    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();
    expect(find.text('Your profile couldn’t load'), findsOneWidget);
    expect(find.text('Setup Profile'), findsNothing);
    db.failProfile = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Hey, Aisha.'), findsOneWidget);
  });
  for (final width in [360.0, 1440.0]) {
    for (final choice in [
      'Keep editing',
      'Discard changes',
      'Save changes',
      'Failed save',
    ]) {
      testWidgets('Unsaved profile guard handles $choice at $width px', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final db = _Database(_profile())..failUpdate = choice == 'Failed save';
        await tester.pumpWidget(_app(db));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField).first,
          'Aisha Updated',
        );
        tester
            .widget<AvailabilityGrid>(find.byType(AvailabilityGrid))
            .onToggle!('tue', 'morning');
        await tester.pumpAndSettle();
        expect(db.profile!.availability.containsKey('tue'), isFalse);
        expect(db.updated, isNull);
        await tester.tap(
          width < 900
              ? find.byKey(const ValueKey('mobile-nav-0'))
              : find.text('Overview'),
        );
        await tester.pumpAndSettle();
        expect(find.text('Save your profile changes?'), findsOneWidget);
        final dialogAction = choice == 'Failed save' ? 'Save changes' : choice;
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text(dialogAction),
          ),
        );
        await tester.pumpAndSettle();
        if (choice == 'Keep editing' || choice == 'Failed save') {
          expect(find.text('Your player profile'), findsOneWidget);
          expect(
            tester
                .widget<AvailabilityGrid>(find.byType(AvailabilityGrid))
                .availability['tue'],
            ['morning'],
          );
          expect(db.updated, isNull);
        } else {
          expect(find.text('Hey, Aisha.'), findsOneWidget);
          await tester.tap(find.text('Profile'));
          await tester.pumpAndSettle();
          final slots = tester
              .widget<AvailabilityGrid>(find.byType(AvailabilityGrid))
              .availability;
          expect(slots.containsKey('tue'), choice == 'Save changes');
          expect(db.updated != null, choice == 'Save changes');
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'Profile name and availability changes persist without mutating saved slots',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final original = _profile();
      final db = _Database(original);
      await tester.pumpWidget(_app(db));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Aisha Updated');
      final grid = tester.widget<AvailabilityGrid>(
        find.byType(AvailabilityGrid),
      );
      grid.onToggle!('tue', 'morning');
      await tester.pump();
      expect(original.availability.containsKey('tue'), isFalse);
      await tester.scrollUntilVisible(
        find.text('Save changes'),
        350,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('profile-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save changes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
      expect(db.updated!['name'], 'Aisha Updated');
      expect((db.updated!['availability'] as Map)['tue'], ['morning']);
      expect(db.profile!.isProfileComplete, isTrue);
    },
  );
  test('Matching accepts legacy sport keys and rewards actual shared time', () {
    final me = _profile();
    final matching = _profile(
      uid: 'other',
      sports: [
        {'name': 'Cricket', 'skillLevel': 'Intermediate'},
      ],
    );
    final noOverlap = matching.copyWith(
      availability: {
        'tue': ['morning'],
      },
    );
    expect(MatchingService.overlaps(me, matching), ['mon evening']);
    expect(MatchingService.score(me, matching), 100);
    expect(
      MatchingService.score(me, noOverlap),
      lessThan(MatchingService.score(me, matching)),
    );
    expect(MatchingService.score(me, matching.copyWith(sports: [])), 0);
    expect(
      MatchingService.score(
        me.copyWith(sports: [], availability: {}),
        matching,
      ),
      0,
    );
  });
  test(
    'Activity remaining spots never become negative for legacy over-capacity data',
    () {
      final game = ActivityModel(
        id: 'game',
        hostId: 'host',
        hostName: 'Host',
        sport: 'Cricket',
        skillLevel: 'Beginner',
        area: 'Latifabad',
        dateTime: DateTime.now(),
        venue: 'Court',
        playersNeeded: 2,
        participantIds: ['host', 'a', 'b'],
        createdAt: DateTime.now(),
      );
      expect(game.spotsLeft, 0);
      expect(game.isFull, isTrue);
      expect(
        ActivityModel.fromMap(game.toMap(), game.id).participantIds,
        game.participantIds,
      );
    },
  );
  testWidgets(
    'Activity cards fit narrow phones with long venue and host names',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final game = ActivityModel(
        id: 'game',
        hostId: 'host',
        hostName: 'A very long host name that should wrap safely',
        sport: 'Table Tennis',
        skillLevel: 'Intermediate',
        area: 'Latifabad',
        dateTime: DateTime.now(),
        venue: 'A very long public sports venue',
        playersNeeded: 4,
        participantIds: ['host'],
        createdAt: DateTime.now(),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(body: ActivityCard(activity: game)),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
