import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportify/config/constants.dart';
import 'package:sportify/config/theme.dart';
import 'package:sportify/providers/user_provider.dart';
import 'package:sportify/services/matching_service.dart';
import 'package:sportify/widgets/user_card.dart';
import 'package:sportify/widgets/page_layout.dart';
import 'package:sportify/screens/profile/user_profile_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});
  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  String _sport = 'All', _area = 'All', _skill = 'All';
  String _query = '';
  final _searchController = TextEditingController();
  bool _overlapOnly = false;
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _search();
    });
  }

  Future<void> _search() => context.read<UserProvider>().discoverPartners(
    sport: _sport,
    area: _area,
    skillLevel: _skill,
  );
  Widget _filter(
    String label,
    String value,
    List<String> values,
    ValueChanged<String> changed,
  ) => DropdownButtonFormField<String>(
    value: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: ['All', ...values]
        .map(
          (v) => DropdownMenuItem(
            value: v,
            child: Text(v, overflow: TextOverflow.ellipsis),
          ),
        )
        .toList(),
    onChanged: (value) {
      if (value != null) {
        setState(() => changed(value));
        _search();
      }
    },
  );
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();
    final me = provider.currentUser;
    final users = provider.discoveredUsers
        .where(
          (u) =>
              ('${u.name} ${u.bio ?? ''}').toLowerCase().contains(
                _query.toLowerCase(),
              ) &&
              (!_overlapOnly ||
                  me != null && MatchingService.overlaps(me, u).isNotEmpty),
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
                title: 'Good games start with good people.',
                subtitle: 'Find partners by sport, skill and shared free time.',
                eyebrow: 'Find your people',
                icon: Icons.people_alt_outlined,
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search players by name or bio',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  // Resizing/devtools can briefly collapse this header to zero.
                  // Never subtract column gaps from an insufficient width.
                  final availableWidth = constraints.maxWidth;
                  if (availableWidth < 160) return const SizedBox.shrink();
                  final wide = availableWidth >= 600;
                  final paired =
                      availableWidth >= 332; // Two 160px controls + gap.
                  final width = wide
                      ? (availableWidth - 24) / 3
                      : availableWidth;
                  final secondaryWidth = wide
                      ? width
                      : paired
                      ? (availableWidth - 12) / 2
                      : availableWidth;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: width,
                        child: _filter(
                          'Sport',
                          _sport,
                          AppConstants.sports
                              .map((s) => s['name'] as String)
                              .toList(),
                          (v) => _sport = v,
                        ),
                      ),
                      SizedBox(
                        width: secondaryWidth,
                        child: _filter(
                          'Area',
                          _area,
                          AppConstants.hyderabadAreas,
                          (v) => _area = v,
                        ),
                      ),
                      SizedBox(
                        width: secondaryWidth,
                        child: _filter(
                          'Skill',
                          _skill,
                          AppConstants.skillLevels,
                          (v) => _skill = v,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilterChip(
                    label: const Text('Shared free time'),
                    avatar: const Icon(Icons.schedule, size: 18),
                    selected: _overlapOnly,
                    onSelected: (value) => setState(() => _overlapOnly = value),
                  ),
                  Text(
                    '${users.length} ${users.length == 1 ? 'player' : 'players'} • ranked by compatibility',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        body: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.error != null
            ? EmptyState(
                icon: Icons.cloud_off,
                title: 'Players couldn’t load',
                message: provider.error!,
                onAction: _search,
              )
            : users.isEmpty
            ? EmptyState(
                title: 'Find your next teammate',
                message:
                    'No players match these filters yet. Try a different sport, area or time preference.',
                actionLabel: 'Refresh players',
                onAction: _search,
              )
            : RefreshIndicator(
                onRefresh: _search,
                child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, i) {
                    final user = users[i];
                    final overlap = me == null
                        ? <String>[]
                        : MatchingService.overlaps(me, user);
                    return UserCard(
                      user: user,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserProfileScreen(user: user),
                        ),
                      ),
                      footer: Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          if (me != null)
                            Text(
                              '${MatchingService.score(me, user)}% compatibility',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          Text(
                            overlap.isEmpty
                                ? 'No shared time slots yet'
                                : 'Both free: ${overlap.take(2).map(MatchingService.timeLabel).join(' • ')}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
