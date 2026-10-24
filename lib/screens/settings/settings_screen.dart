import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportify/config/theme.dart';
import 'package:sportify/providers/auth_provider.dart';
import 'package:sportify/providers/user_provider.dart';
import 'package:sportify/services/firestore_service.dart';
import 'package:sportify/services/session_service.dart';
import 'package:sportify/widgets/page_layout.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account and data?'),
        content: const Text(
          'This permanently deletes your account, profile, hosted games, connections and chats. The cleanup runs after your account is deleted. You may need to sign in again before confirming.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final auth = context.read<AuthProvider>();
      await withProgress(
        context,
        auth.deleteAccount,
        message: 'Deleting your account…',
      );
    } catch (error) {
      if (!context.mounted) return;
      final message = error.toString().contains('requires-recent-login')
          ? 'For security, sign out, sign in again, then retry account deletion.'
          : 'Couldn’t delete the account. Check your connection and try again.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _report(BuildContext context, {bool deletion = false}) async {
    final controller = TextEditingController();
    final uid = context.read<AuthProvider>().user?.uid;
    bool saving = false;
    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          scrollable: true,
          title: Text(
            deletion ? 'Request account & data deletion' : 'Report a problem',
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  deletion
                      ? 'This sends a request for review. It does not immediately delete your account. Your account stays active until the request is processed.'
                      : 'Tell us what went wrong. Your report will be saved for review.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  maxLines: 4,
                  maxLength: 1000,
                  decoration: InputDecoration(
                    labelText: deletion
                        ? 'Additional details (optional)'
                        : 'Describe the issue',
                  ),
                ),
              ],
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
                      if (!deletion && controller.text.trim().isEmpty) return;
                      setDialogState(() => saving = true);
                      try {
                        await FirestoreService().createReport({
                          'reporterId': uid,
                          'targetType': deletion ? 'account-deletion' : 'app',
                          'targetId': uid,
                          'reason': controller.text.trim(),
                          'status': 'pending',
                        });
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                              content: Text('Request saved for review.'),
                            ),
                          );
                        }
                      } catch (_) {
                        if (dialogContext.mounted) {
                          setDialogState(() => saving = false);
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Couldn’t save your request. Try again.',
                              ),
                            ),
                          );
                        }
                      }
                    },
              child: ActionLabel(
                busy: saving,
                busyLabel: 'Sending…',
                label: deletion ? 'Send deletion request' : 'Submit report',
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
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: PageLayout(
        maxWidth: 720,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const PageIntro(
              title: 'Make Sportify yours.',
              subtitle: 'Your account, preferences and peace of mind.',
              eyebrow: 'Your space',
              icon: Icons.tune_rounded,
            ),
            const SizedBox(height: 24),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Edit player profile'),
                    subtitle: const Text(
                      'Sports, area, photo and availability',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pushNamed(context, '/edit-profile'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Reset password'),
                    subtitle: Text(user?.email ?? ''),
                    onTap: user?.email == null
                        ? null
                        : () => runAction(
                            context,
                            () => auth.resetPassword(user!.email!),
                            success:
                                'Password reset email sent. Check your inbox.',
                          ),
                  ),
                  if (user != null && !user.emailVerified) ...[
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.mark_email_read_outlined),
                      title: const Text('Verify your email'),
                      subtitle: const Text(
                        'We’ll send a verification link to your inbox.',
                      ),
                      onTap: () => runAction(
                        context,
                        user.sendEmailVerification,
                        success: 'Verification email sent.',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Your privacy'),
                    subtitle: const Text('What other players can see'),
                    onTap: () => showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        scrollable: true,
                        title: const Text('Your profile & privacy'),
                        content: const Text(
                          'Signed-in players can see your name, photo, bio, area, sports and availability. Sportify uses area names rather than collecting your home address or GPS location. Accept a connection to start a direct conversation. Meet in public places and avoid sharing sensitive details in chat.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Got it'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.report_problem_outlined),
                    title: const Text('Report a problem'),
                    onTap: () => _report(context),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('About Sportify'),
                    onTap: () => showAboutDialog(
                      context: context,
                      applicationName: 'Sportify',
                      applicationVersion: '1.0.0',
                      applicationIcon: const Icon(
                        Icons.sports_rounded,
                        color: AppColors.primary,
                        size: 48,
                      ),
                      children: [
                        const Text(
                          'Find your people. Make time for sport. Built for your community.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: auth.isLoading ? null : () => _deleteAccount(context),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete account and data'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: auth.isLoading
                  ? null
                  : () => SessionService.signOut(context),
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
            const SizedBox(height: 12),
            Text(
              'Signed in as ${context.watch<UserProvider>().currentUser?.name ?? 'player'}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
