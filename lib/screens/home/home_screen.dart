import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportify/config/theme.dart';
import 'package:sportify/providers/user_provider.dart';
import 'package:sportify/providers/connection_provider.dart';
import 'package:sportify/providers/auth_provider.dart';
import 'package:sportify/providers/activity_provider.dart';
import 'package:sportify/screens/discover/discover_screen.dart';
import 'package:sportify/screens/activity/activity_list_screen.dart';
import 'package:sportify/screens/chat/chats_list_screen.dart';
import 'package:sportify/screens/profile/edit_profile_screen.dart';
import 'package:sportify/screens/venues/venue_list_screen.dart';
import 'package:sportify/screens/notifications/notifications_screen.dart';
import 'package:sportify/widgets/page_layout.dart';
import 'package:sportify/widgets/activity_card.dart';
import 'package:sportify/screens/activity/activity_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  final _visited = <int>{0};
  final _profileKey = GlobalKey<EditProfileScreenState>();
  bool _switchingTab = false;
  static const _labels = [
    'Overview',
    'Find partners',
    'Games',
    'Venues',
    'Messages',
    'Profile',
  ];
  static const _icons = [
    Icons.grid_view_rounded,
    Icons.people_outline_rounded,
    Icons.sports_tennis_rounded,
    Icons.location_on_outlined,
    Icons.chat_bubble_outline_rounded,
    Icons.person_outline_rounded,
  ];
  static const _mobileLabels = [
    'Home',
    'Players',
    'Games',
    'Venues',
    'Chats',
    'Profile',
  ];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final uid = context.read<AuthProvider>().user?.uid;
      if (uid != null) context.read<ConnectionProvider>().loadConnections(uid);
      context.read<ActivityProvider>().loadActivities();
    });
  }

  Future<void> _select(int index) async {
    if (index == _index || _switchingTab) return;
    _switchingTab = true;
    try {
      if (_index == 5 &&
          !(await (_profileKey.currentState?.confirmLeave() ??
              Future.value(true)))) {
        return;
      }
      if (!mounted) return;
      setState(() {
        _index = index;
        _visited.add(index);
      });
    } finally {
      _switchingTab = false;
    }
  }

  Widget _page(int index) => switch (index) {
    0 => _Dashboard(onSelect: _select),
    1 => DiscoverScreen(),
    2 => ActivityListScreen(),
    3 => VenueListScreen(embedded: true),
    4 => ChatsListScreen(),
    _ => EditProfileScreen(key: _profileKey),
  };
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final me = context.watch<UserProvider>().currentUser;
    final requests = context.watch<ConnectionProvider>().pendingRequests.length;
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (wide)
              Container(
                key: const ValueKey('desktop-sidebar'),
                width: 224,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(right: BorderSide(color: AppColors.divider)),
                ),
                child: ListView(
                  key: const ValueKey('desktop-navigation'),
                  padding: EdgeInsets.zero,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(24, 32, 24, 32),
                      child: FittedBox(
                        child: Row(
                          children: [
                            Icon(
                              Icons.sports_rounded,
                              color: AppColors.primary,
                              size: 32,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Sportify',
                              style: TextStyle(
                                fontSize: 27,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    for (var i = 0; i < _labels.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          selected: _index == i,
                          selectedTileColor: AppColors.surfaceVariant,
                          selectedColor: AppColors.primary,
                          leading: Icon(_icons[i]),
                          title: Text(
                            _labels[i],
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          onTap: () => _select(i),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.favorite_border_rounded,
                              color: AppColors.primary,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'More play. More people.',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Make movement part of your week.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings_outlined),
                      title: const Text('Settings'),
                      onTap: () => Navigator.pushNamed(context, '/settings'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            Expanded(
              key: const ValueKey('main-content'),
              child: Column(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: AppColors.divider),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: wide ? 32 : 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        if (!wide) ...[
                          const Icon(
                            Icons.sports_rounded,
                            color: AppColors.primary,
                            size: 32,
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                wide ? _labels[_index] : 'Sportify',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                ),
                              ),
                              if (wide)
                                Text(
                                  '${me?.area ?? ''}, ${me?.city ?? 'Hyderabad'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Requests & your games',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NotificationsScreen(),
                            ),
                          ),
                          icon: Badge(
                            isLabelVisible: requests > 0,
                            label: Text('$requests'),
                            child: const Icon(Icons.notifications_none_rounded),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _select(5),
                          borderRadius: BorderRadius.circular(24),
                          child: CircleAvatar(
                            backgroundColor: AppColors.surfaceVariant,
                            child: Text(
                              me?.name.isNotEmpty == true
                                  ? me!.name[0].toUpperCase()
                                  : 'S',
                              style: const TextStyle(color: AppColors.primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageLayout(
                      child: IndexedStack(
                        index: _index,
                        children: List.generate(
                          6,
                          (i) => _visited.contains(i)
                              ? _page(i)
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _index == 2
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, '/create-activity'),
              icon: const Icon(Icons.add),
              label: const Text('Host a game'),
            )
          : null,
      bottomNavigationBar: wide
          ? null
          : DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.divider)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0B172A52),
                    blurRadius: 24,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: 8),
                child: NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: _select,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: List.generate(
                    6,
                    (i) => NavigationDestination(
                      key: ValueKey('mobile-nav-$i'),
                      icon: Icon(_icons[i]),
                      label: _mobileLabels[i],
                      tooltip: _labels[i],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  final ValueChanged<int> onSelect;
  const _Dashboard({required this.onSelect});
  @override
  Widget build(BuildContext context) {
    final me = context.watch<UserProvider>().currentUser;
    final provider = context.watch<ActivityProvider>();
    final games = provider.activities
        .where(
          (a) => a.status != 'cancelled' && a.dateTime.isAfter(DateTime.now()),
        )
        .toList();
    final joined = games
        .where((a) => a.participantIds.contains(me?.uid))
        .toList();
    final connections = context
        .watch<ConnectionProvider>()
        .acceptedConnections
        .length;
    return RefreshIndicator(
      onRefresh: () => provider.loadActivities(),
      child: ListView(
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width < 600 ? 18 : 32,
        ),
        children: [
          Text(
            'LET’S MAKE TIME TO PLAY',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hey, ${me?.name.split(' ').first ?? 'player'}.',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 6),
          const Text(
            'Find your people. Pick your game. Get out there.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 26),
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'YOUR NEXT GOOD HABIT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          letterSpacing: 1.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Less scrolling.\nMore playing.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Meet sports partners who share your interests\nand have time when you do.',
                  style: TextStyle(color: Color(0xFFDBEAFF), height: 1.6),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      style:
                          FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                          ).copyWith(
                            backgroundBuilder: (context, states, child) =>
                                child ?? const SizedBox.shrink(),
                          ),
                      onPressed: () => onSelect(1),
                      icon: const Icon(Icons.people_outline),
                      label: const Text('Find my people'),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF8DBAFF)),
                      ),
                      onPressed: () =>
                          Navigator.pushNamed(context, '/create-activity'),
                      icon: const Icon(Icons.add),
                      label: const Text('Host a game'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _stat(
                  context,
                  constraints.maxWidth,
                  '${me?.sports.length ?? 0}',
                  'Sports you love',
                  Icons.sports_tennis,
                  () => onSelect(5),
                ),
                _stat(
                  context,
                  constraints.maxWidth,
                  '$connections',
                  'Your connections',
                  Icons.people_outline,
                  () => onSelect(1),
                ),
                _stat(
                  context,
                  constraints.maxWidth,
                  '${joined.length}',
                  'Upcoming games',
                  Icons.event_outlined,
                  () => onSelect(2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Your next sessions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton(
                onPressed: () => onSelect(2),
                child: const Text('View games →'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (provider.isLoading)
            const LinearProgressIndicator()
          else if (provider.error != null)
            EmptyState(
              title: 'Games couldn’t load',
              message: provider.error!,
              onAction: () => provider.loadActivities(),
            )
          else if (joined.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.event_available_outlined,
                    color: AppColors.primary,
                    size: 30,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'A little planning. A lot more play.',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Join a local game or host one. Your upcoming sessions will appear here.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: () => onSelect(2),
                    child: const Text('Explore games →'),
                  ),
                ],
              ),
            )
          else
            ...joined
                .take(3)
                .map(
                  (a) => ActivityCard(
                    activity: a,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ActivityDetailScreen(activity: a),
                      ),
                    ),
                  ),
                ),
          const SizedBox(height: 24),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            tileColor: AppColors.surfaceVariant,
            leading: const Icon(
              Icons.location_on_outlined,
              color: AppColors.primary,
            ),
            title: const Text('Find a place to play'),
            subtitle: const Text(
              'Explore community venues or suggest your favorite.',
            ),
            trailing: const Icon(Icons.arrow_forward_rounded),
            onTap: () => onSelect(3),
          ),
          const SizedBox(height: 20),
          const Text(
            'Meet safely: choose a public venue, tell a friend your plans, and respect everyone’s boundaries.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _stat(
    BuildContext context,
    double width,
    String value,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) => SizedBox(
    width: width < 520 ? width : (width - 24) / 3,
    child: Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
