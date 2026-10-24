import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportify/providers/auth_provider.dart';
import 'package:sportify/widgets/page_layout.dart';

class SessionService {
  static Future<void> signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.logout_rounded),
        title: const Text('Sign out of Sportify?'),
        content: const Text(
          'You can sign in again any time. Your profile, connections and games will be saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Stay signed in'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final auth = context.read<AuthProvider>();
    await runAction(context, auth.signOut, loadingMessage: 'Signing you out…');
    // The keyed session tree in SportifyApp disposes account data and routes.
  }
}
