import 'package:flutter/material.dart';
import 'package:sportify/screens/auth/session_gate.dart';

/// Kept as a compatible entry point for older routes.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => const SessionGate();
}
