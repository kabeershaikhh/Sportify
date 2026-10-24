import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportify/providers/auth_provider.dart';
import 'package:sportify/providers/user_provider.dart';
import 'package:sportify/screens/auth/login_screen.dart';
import 'package:sportify/screens/home/home_screen.dart';
import 'package:sportify/screens/onboarding/profile_setup_screen.dart';
import 'package:sportify/widgets/page_layout.dart';

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});
  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  String? _uid;
  Future<void>? _profile;
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (auth.user == null) {
      _uid = null;
      _profile = null;
      return const LoginScreen();
    }
    if (_uid != auth.user!.uid) {
      _uid = auth.user!.uid;
      final provider = context.read<UserProvider>();
      final uid = _uid!;
      // Defer notifications until the current frame has finished building.
      _profile = Future<void>(() => provider.loadUserProfile(uid));
    }
    return FutureBuilder<void>(
      future: _profile,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: EmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Your profile couldn’t load',
              message:
                  'Check your connection and try again. Your saved setup is safe.',
              onAction: () => setState(() {
                final provider = context.read<UserProvider>();
                final uid = _uid!;
                _profile = Future<void>(() => provider.loadUserProfile(uid));
              }),
            ),
          );
        }
        return context.watch<UserProvider>().isProfileComplete
            ? const HomeScreen()
            : const PageLayout(maxWidth: 720, child: ProfileSetupScreen());
      },
    );
  }
}
