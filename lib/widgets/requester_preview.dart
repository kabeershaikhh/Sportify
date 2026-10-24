import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportify/models/user_model.dart';
import 'package:sportify/providers/user_provider.dart';
import 'package:sportify/screens/profile/user_profile_screen.dart';
import 'package:sportify/services/firestore_service.dart';
import 'package:sportify/services/matching_service.dart';
import 'package:sportify/widgets/compatibility_summary.dart';

/// Loads the requester's current public profile, rather than a request snapshot.
class RequesterPreview extends StatefulWidget {
  final String userId;
  final FirestoreService firestoreService;
  const RequesterPreview({
    super.key,
    required this.userId,
    required this.firestoreService,
  });

  @override
  State<RequesterPreview> createState() => _RequesterPreviewState();
}

class _RequesterPreviewState extends State<RequesterPreview> {
  late Stream<UserModel?> _profileStream;
  @override
  void initState() {
    super.initState();
    _profileStream = widget.firestoreService.streamUser(widget.userId);
  }

  @override
  void didUpdateWidget(RequesterPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.firestoreService != widget.firestoreService) {
      _profileStream = widget.firestoreService.streamUser(widget.userId);
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<UserModel?>(
    stream: _profileStream,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('Loading player profile…'),
        );
      }
      final user = snapshot.data;
      if (snapshot.hasError || user == null || !user.isProfileComplete) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Player profile is unavailable. Compatibility cannot be checked.',
          ),
        );
      }
      final me = context.watch<UserProvider>().currentUser;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: user.photoUrl?.isNotEmpty == true
                      ? ClipOval(
                          child: Image.network(
                            user.photoUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, error, stack) =>
                                const Icon(Icons.person_outline),
                          ),
                        )
                      : const Icon(Icons.person_outline),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        [
                          user.area,
                          user.city,
                        ].where((part) => part.isNotEmpty).join(', '),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final sport in user.sports)
                  Chip(
                    label: Text(
                      '${MatchingService.sportName(sport)}${sport['skillLevel'] == null ? '' : ' · ${sport['skillLevel']}'}',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            CompatibilitySummary(
              currentUser: me,
              otherUser: user,
              compact: true,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserProfileScreen(user: user),
                ),
              ),
              icon: const Icon(Icons.person_search_outlined),
              label: const Text('Explore profile'),
            ),
          ],
        ),
      );
    },
  );
}
