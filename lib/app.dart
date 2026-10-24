import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sportify/config/theme.dart';
import 'package:sportify/providers/auth_provider.dart';
import 'package:sportify/providers/user_provider.dart';
import 'package:sportify/providers/activity_provider.dart';
import 'package:sportify/providers/chat_provider.dart';
import 'package:sportify/providers/connection_provider.dart';
import 'package:sportify/screens/auth/session_gate.dart';
import 'package:sportify/screens/onboarding/profile_setup_screen.dart';
import 'package:sportify/screens/onboarding/sports_selection_screen.dart';
import 'package:sportify/screens/onboarding/availability_screen.dart';
import 'package:sportify/screens/activity/create_activity_screen.dart';
import 'package:sportify/screens/venues/venue_list_screen.dart';
import 'package:sportify/screens/settings/settings_screen.dart';
import 'package:sportify/screens/profile/edit_profile_screen.dart';
import 'package:sportify/widgets/page_layout.dart';
import 'package:sportify/services/auth_service.dart';
import 'package:sportify/services/firestore_service.dart';

class SportifyApp extends StatelessWidget {
  final AuthService? authService;
  final FirestoreService? firestoreService;
  const SportifyApp({super.key, this.authService, this.firestoreService});
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => AuthProvider(authService: authService),
    child: _SessionScope(database: firestoreService),
  );
}

/// Each account owns a separate provider tree and navigator. Logging out disposes
/// its Firestore subscriptions, drafts and routes before a new account can enter.
class _SessionScope extends StatelessWidget {
  final FirestoreService? database;
  const _SessionScope({this.database});
  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().user?.uid;
    return MultiProvider(
      key: ValueKey(uid),
      providers: [
        ChangeNotifierProvider(
          create: (_) => UserProvider(firestoreService: database),
        ),
        ChangeNotifierProvider(
          create: (_) => ActivityProvider(firestoreService: database),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(firestoreService: database),
        ),
        ChangeNotifierProvider(
          create: (_) => ConnectionProvider(firestoreService: database),
        ),
      ],
      child: MaterialApp(
        title: 'Sportify',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const SessionGate(),
        routes: {
          '/login': (_) => const SessionGate(),
          '/home': (_) => const SessionGate(),
          '/onboarding/profile': (_) =>
              const _SetupPage(child: ProfileSetupScreen()),
          '/onboarding/sports': (context) => _SetupPage(
            child: SportsSelectionScreen(
              profileData:
                  ModalRoute.of(context)?.settings.arguments
                      as Map<String, dynamic>? ??
                  {},
            ),
          ),
          '/onboarding/availability': (context) => _SetupPage(
            child: AvailabilityScreen(
              profileData:
                  ModalRoute.of(context)?.settings.arguments
                      as Map<String, dynamic>? ??
                  {},
            ),
          ),
          '/create-activity': (_) =>
              const _ProtectedPage(child: CreateActivityScreen()),
          '/venue-list': (_) => const _ProtectedPage(child: VenueListScreen()),
          '/settings': (_) => const _ProtectedPage(child: SettingsScreen()),
          '/edit-profile': (_) =>
              const _ProtectedPage(child: EditProfileScreen(embedded: false)),
        },
        builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppTheme.systemOverlay,
          child: PageLayout(maxWidth: 1600, child: child!),
        ),
      ),
    );
  }
}

class _ProtectedPage extends StatelessWidget {
  final Widget child;
  const _ProtectedPage({required this.child});
  @override
  Widget build(BuildContext context) =>
      context.watch<AuthProvider>().isLoggedIn &&
          context.watch<UserProvider>().isProfileComplete
      ? child
      : const SessionGate();
}

class _SetupPage extends StatefulWidget {
  final Widget child;
  const _SetupPage({required this.child});
  @override
  State<_SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<_SetupPage> {
  bool _enteredSetup = false;
  @override
  Widget build(BuildContext context) {
    final signedIn = context.watch<AuthProvider>().isLoggedIn;
    final complete = context.watch<UserProvider>().isProfileComplete;
    if (!signedIn || (complete && !_enteredSetup)) {
      return const SessionGate();
    }
    // Keep an admitted setup step mounted until its successful save clears the
    // stack. Replacing it during the save also starts profile loads on hidden
    // routes and can interfere with completion navigation.
    _enteredSetup = true;
    return PageLayout(maxWidth: 720, child: widget.child);
  }
}
