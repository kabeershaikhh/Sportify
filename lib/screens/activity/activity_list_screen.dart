import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportify/config/constants.dart';
import 'package:sportify/providers/activity_provider.dart';
import 'package:sportify/providers/auth_provider.dart';
import 'package:sportify/widgets/activity_card.dart';
import 'package:sportify/widgets/page_layout.dart';
import 'package:sportify/screens/activity/activity_detail_screen.dart';

class ActivityListScreen extends StatefulWidget {
  const ActivityListScreen({super.key});
  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  String _filter = 'Explore', _sport = 'All';
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActivityProvider>();
    final uid = context.watch<AuthProvider>().user?.uid;
    final activities = provider.activities
        .where(
          (a) =>
              (_sport == 'All' || a.sport == _sport) &&
              (_filter == 'Hosting'
                  ? a.hostId == uid
                  : _filter == 'Joined'
                  ? a.participantIds.contains(uid) && a.hostId != uid
                  : _filter == 'Past'
                  ? a.dateTime.isBefore(DateTime.now())
                  : a.status != 'cancelled' &&
                        a.dateTime.isAfter(DateTime.now())),
        )
        .toList();
    return Scaffold(
      body: CollectionPage(
        header: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageIntro(
                title: 'Make room for a great game.',
                subtitle:
                    'Join a session nearby or bring your own crew together.',
                eyebrow: 'Your next session',
                icon: Icons.sports_tennis_rounded,
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Explore', 'Hosting', 'Joined', 'Past']
                    .map(
                      (f) => ChoiceChip(
                        label: Text(f),
                        selected: _filter == f,
                        onSelected: (_) => setState(() => _filter = f),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _sport,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Sport',
                  prefixIcon: Icon(Icons.sports),
                ),
                items:
                    [
                          'All',
                          ...AppConstants.sports.map(
                            (s) => s['name'] as String,
                          ),
                        ]
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                onChanged: (v) => setState(() => _sport = v ?? 'All'),
              ),
            ],
          ),
        ),
        body: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.error != null
            ? EmptyState(
                icon: Icons.cloud_off,
                title: 'Games couldn’t load',
                message: provider.error!,
                onAction: () => provider.loadActivities(),
              )
            : activities.isEmpty
            ? EmptyState(
                icon: Icons.sports_tennis_rounded,
                title: 'Your next game is waiting',
                message:
                    'No games in this view yet. Be the first to bring players together.',
                actionLabel: 'Host a game',
                onAction: () =>
                    Navigator.pushNamed(context, '/create-activity'),
              )
            : RefreshIndicator(
                onRefresh: () => provider.loadActivities(),
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: activities.length,
                  itemBuilder: (context, i) => ActivityCard(
                    activity: activities[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ActivityDetailScreen(activity: activities[i]),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
