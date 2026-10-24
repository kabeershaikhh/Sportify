import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportify/config/constants.dart';
import 'package:sportify/models/venue_model.dart';
import 'package:sportify/providers/auth_provider.dart';
import 'package:sportify/services/firestore_service.dart';
import 'package:sportify/widgets/venue_card.dart';
import 'package:sportify/widgets/page_layout.dart';

class VenueListScreen extends StatefulWidget {
  final bool embedded;
  const VenueListScreen({super.key, this.embedded = false});
  @override
  State<VenueListScreen> createState() => _VenueListScreenState();
}

class _VenueListScreenState extends State<VenueListScreen> {
  final _service = FirestoreService();
  late Future<List<VenueModel>> _venues;
  String _sport = 'All', _area = 'All';
  @override
  void initState() {
    super.initState();
    _venues = _service.getVenues();
  }

  void _load() =>
      setState(() => _venues = _service.getVenues(sport: _sport, area: _area));
  Future<void> _suggestVenue() async {
    final name = TextEditingController(),
        address = TextEditingController(),
        price = TextEditingController();
    final form = GlobalKey<FormState>();
    String? area, sport;
    bool saving = false;
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          scrollable: true,
          title: const Text('Share a place to play'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Form(
                key: form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Suggestions are reviewed before appearing in the directory.',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: name,
                      decoration: const InputDecoration(
                        labelText: 'Venue name',
                      ),
                      validator: (v) =>
                          v!.trim().isEmpty ? 'Enter a name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: address,
                      decoration: const InputDecoration(
                        labelText: 'Public venue address',
                      ),
                      validator: (v) =>
                          v!.trim().isEmpty ? 'Enter an address' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Area'),
                      items: AppConstants.hyderabadAreas
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      validator: (v) => v == null ? 'Choose an area' : null,
                      onChanged: (v) => area = v,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Sport'),
                      items: AppConstants.sports
                          .map(
                            (s) => DropdownMenuItem(
                              value: s['name'] as String,
                              child: Text(s['name'] as String),
                            ),
                          )
                          .toList(),
                      validator: (v) => v == null ? 'Choose a sport' : null,
                      onChanged: (v) => sport = v,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: price,
                      decoration: const InputDecoration(
                        labelText: 'Price note (optional)',
                      ),
                    ),
                  ],
                ),
              ),
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
                      if (!form.currentState!.validate()) return;
                      setDialogState(() => saving = true);
                      try {
                        await _service.suggestVenue(
                          VenueModel(
                            id: '',
                            name: name.text.trim(),
                            address: address.text.trim(),
                            area: area!,
                            sports: [sport!],
                            priceRange: price.text.trim().isEmpty
                                ? null
                                : price.text.trim(),
                            suggestedBy: context.read<AuthProvider>().user!.uid,
                            createdAt: DateTime.now(),
                          ),
                        );
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext, true);
                        }
                      } catch (e) {
                        if (dialogContext.mounted) {
                          setDialogState(() => saving = false);
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Couldn’t save the suggestion. Try again.',
                              ),
                            ),
                          );
                        }
                      }
                    },
              child: ActionLabel(
                busy: saving,
                label: 'Submit suggestion',
                busyLabel: 'Submitting…',
              ),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    address.dispose();
    price.dispose();
    if (mounted && submitted == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venue submitted for review. Thank you!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: widget.embedded ? null : AppBar(title: const Text('Venues')),
    body: CollectionPage(
      header: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageIntro(
              title: 'A great place for your next game.',
              subtitle:
                  'Discover public sports spaces recommended by the community.',
              eyebrow: 'Places to play',
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _sport,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Sport'),
                    items:
                        [
                              'All',
                              ...AppConstants.sports.map(
                                (s) => s['name'] as String,
                              ),
                            ]
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(s, overflow: TextOverflow.ellipsis),
                              ),
                            )
                            .toList(),
                    onChanged: (v) {
                      _sport = v ?? 'All';
                      _load();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _area,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Area'),
                    items: ['All', ...AppConstants.hyderabadAreas]
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(s, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      _area = v ?? 'All';
                      _load();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<VenueModel>>(
        future: _venues,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.cloud_off,
              title: 'Venues couldn’t load',
              message: 'Check your connection and try again.',
              onAction: _load,
            );
          }
          final venues = snapshot.data ?? [];
          if (venues.isEmpty) {
            return EmptyState(
              icon: Icons.location_on_outlined,
              title: 'Help put your area on the map',
              message:
                  'No approved venues match these filters yet. Suggest a public sports space for the community.',
              actionLabel: 'Suggest a venue',
              onAction: _suggestVenue,
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              _load();
              await _venues;
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: venues.length,
              itemBuilder: (context, i) => VenueCard(
                venue: venues[i],
                onTap: () => showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    scrollable: true,
                    title: Text(venues[i].name),
                    content: Text(
                      '${venues[i].address}\n${venues[i].area}\n\nSports: ${venues[i].sports.join(', ')}\n${venues[i].priceRange ?? 'Contact the venue for pricing.'}',
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
            ),
          );
        },
      ),
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _suggestVenue,
      label: const Text('Suggest venue'),
      icon: const Icon(Icons.add_location_alt_outlined),
    ),
  );
}
