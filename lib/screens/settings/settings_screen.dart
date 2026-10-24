import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportify/config/theme.dart';
import 'package:sportify/providers/auth_provider.dart';
import 'package:sportify/providers/user_provider.dart';
import 'package:sportify/services/firestore_service.dart';
import 'package:sportify/services/session_service.dart';
import 'package:sportify/widgets/page_layout.dart';
import 'package:sportify/widgets/change_password_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _changePassword(BuildContext context) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    if (!user.providerData.any(
      (provider) => provider.providerId == 'password',
    )) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.lock_outline),
          title: const Text('Password managed by your provider'),
          content: const Text(
            'You sign in with Google or another provider. Change your password in that provider’s account settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
      return;
    }
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ChangePasswordDialog(),
    );
    if (changed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your password has been updated.')),
      );
    }
  }

  Future<void> _report(BuildContext context) async {
    final controller = TextEditingController();
    final uid = context.read<AuthProvider>().user?.uid;
    bool saving = false;
    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          scrollable: true,
          title: const Text('Report a problem'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Tell us what went wrong. Your report will be saved for review.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  maxLines: 4,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Describe the issue',
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
                      if (controller.text.trim().isEmpty) return;
                      setDialogState(() => saving = true);
                      try {
                        await FirestoreService().createReport({
                          'reporterId': uid,
                          'targetType': 'app',
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
                label: 'Submit report',
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
                    title: const Text('Change password'),
                    subtitle: const Text(
                      'Verify your current password to update it',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: user?.email == null
                        ? null
                        : () => _changePassword(context),
                  ),
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
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        scrollable: true,
                        icon: const Icon(
                          Icons.sports_rounded,
                          color: AppColors.primary,
                          size: 42,
                        ),
                        title: const Text('About Sportify'),
                        content: const SizedBox(
                          width: 400,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Find your people. Make time for sport.',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              SizedBox(height: 14),
                              Text(
                                'Sportify brings local players together through shared sports, skill levels and free time.',
                              ),
                              SizedBox(height: 14),
                              Text(
                                'Explore compatible players, build connections, host or request to join games, and coordinate with your group in chat.',
                              ),
                              SizedBox(height: 14),
                              Text(
                                'Built for the sports community in Hyderabad.',
                              ),
                              SizedBox(height: 20),
                              Text(
                                'Developed by Kabeer with "💙"',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: auth.isLoading
                    ? null
                    : () => SessionService.signOut(context),
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
              ),
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
