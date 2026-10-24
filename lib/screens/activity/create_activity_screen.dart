import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sportify/config/constants.dart';
import 'package:sportify/config/theme.dart';
import 'package:sportify/models/activity_model.dart';
import 'package:sportify/providers/activity_provider.dart';
import 'package:sportify/providers/auth_provider.dart';
import 'package:sportify/providers/user_provider.dart';
import 'package:sportify/widgets/page_layout.dart';

class CreateActivityScreen extends StatefulWidget {
  final ActivityModel? activity;
  const CreateActivityScreen({super.key, this.activity});
  @override
  State<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends State<CreateActivityScreen> {
  final _form = GlobalKey<FormState>();
  final _venue = TextEditingController(),
      _address = TextEditingController(),
      _players = TextEditingController(text: '4'),
      _description = TextEditingController();
  String? _sport, _area, _skill;
  DateTime? _date;
  TimeOfDay? _time;
  bool _saving = false;
  bool get _editing => widget.activity != null;
  @override
  void initState() {
    super.initState();
    final game = widget.activity;
    if (game == null) return;
    _venue.text = game.venue;
    _address.text = game.venueAddress ?? '';
    _players.text = game.playersNeeded.toString();
    _description.text = game.description ?? '';
    _sport = game.sport;
    _area = game.area;
    _skill = game.skillLevel;
    _date = game.dateTime;
    _time = TimeOfDay.fromDateTime(game.dateTime);
  }

  @override
  void dispose() {
    _venue.dispose();
    _address.dispose();
    _players.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_date == null || _time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose the date and start time.')),
      );
      return;
    }
    final start = DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _time!.hour,
      _time!.minute,
    );
    if (!start.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The game must start in the future.')),
      );
      return;
    }
    final auth = context.read<AuthProvider>().user;
    final me = context.read<UserProvider>().currentUser;
    if (auth == null || (!_editing && me == null)) return;
    setState(() => _saving = true);
    try {
      if (_editing) {
        await context.read<ActivityProvider>().editActivity(
          widget.activity!.copyWith(
            sport: _sport!,
            skillLevel: _skill!,
            area: _area!,
            dateTime: start,
            venue: _venue.text.trim(),
            venueAddress: _address.text.trim(),
            playersNeeded: int.parse(_players.text.trim()),
            description: _description.text.trim(),
          ),
          auth.uid,
        );
      } else {
        await context.read<ActivityProvider>().createActivity(
          ActivityModel(
            id: '',
            hostId: auth.uid,
            hostName: me!.name,
            hostPhotoUrl: me.photoUrl,
            sport: _sport!,
            skillLevel: _skill!,
            area: _area!,
            dateTime: start,
            venue: _venue.text.trim(),
            venueAddress: _address.text.trim(),
            playersNeeded: int.parse(_players.text.trim()),
            description: _description.text.trim(),
            participantIds: [auth.uid],
            createdAt: DateTime.now(),
          ),
        );
      }
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              _editing
                  ? 'Game updated.'
                  : 'Your game is live. Let’s get people playing!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is StateError
                  ? e.message.toString()
                  : _editing
                  ? 'Couldn’t save the game. Check your connection and try again.'
                  : 'Couldn’t create the game. Check your connection and try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _dropdown(
    String label,
    List<String> items,
    ValueChanged<String?> changed, {
    String? selected,
  }) => DropdownButtonFormField<String>(
    isExpanded: true,
    value: selected,
    decoration: InputDecoration(labelText: label),
    items: {
      ...items,
      if (selected != null) selected,
    }.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
    validator: (v) => v == null ? 'Choose $label' : null,
    onChanged: changed,
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_editing ? 'Edit game' : 'Host a game')),
    body: PageLayout(
      maxWidth: 720,
      child: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              _editing ? 'Update your game.' : 'Bring your people together.',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _editing
                  ? 'Your players will see the updated details.'
                  : 'Set the details. We’ll help players find your session.',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 28),
            _dropdown(
              'Sport',
              AppConstants.sports.map((s) => s['name'] as String).toList(),
              (v) => _sport = v,
              selected: _sport,
            ),
            const SizedBox(height: 16),
            _dropdown(
              'Skill level',
              AppConstants.skillLevels,
              (v) => _skill = v,
              selected: _skill,
            ),
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: Text(
                      _date == null
                          ? 'Choose date'
                          : DateFormat.yMMMMd().format(_date!),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _saving
                        ? null
                        : () async {
                            final now = DateTime.now();
                            final today = DateTime(
                              now.year,
                              now.month,
                              now.day,
                            );
                            final initial = (_date ?? now).isBefore(today)
                                ? today
                                : (_date ?? now);
                            final limit = now.add(const Duration(days: 365));
                            final date = await showDatePicker(
                              context: context,
                              initialDate: initial,
                              firstDate: today,
                              lastDate: initial.isAfter(limit)
                                  ? initial
                                  : limit,
                            );
                            if (date != null && mounted) {
                              setState(() => _date = date);
                            }
                          },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.schedule),
                    title: Text(
                      _time == null
                          ? 'Choose start time'
                          : _time!.format(context),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _saving
                        ? null
                        : () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _time ?? TimeOfDay.now(),
                            );
                            if (time != null && mounted) {
                              setState(() => _time = time);
                            }
                          },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _venue,
              maxLength: 120,
              decoration: const InputDecoration(
                labelText: 'Public venue name',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              validator: (v) => v!.trim().isEmpty ? 'Enter a venue' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Venue address (optional)',
              ),
            ),
            const SizedBox(height: 12),
            _dropdown(
              'Area',
              AppConstants.hyderabadAreas,
              (v) => _area = v,
              selected: _area,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _players,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total players',
                helperText: 'Includes you as the host • between 2 and 100',
              ),
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                if (n != null &&
                    _editing &&
                    n < widget.activity!.participantIds.length) {
                  return 'Keep room for all ${widget.activity!.participantIds.length} joined players';
                }
                return n == null || n < 2 || n > 100
                    ? 'Enter a whole number from 2 to 100'
                    : null;
              },
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _description,
              maxLines: 4,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'What should players know?',
                hintText: 'Equipment, meeting point, or any shared venue cost…',
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: Icon(_editing ? Icons.save_outlined : Icons.add_rounded),
              label: ActionLabel(
                busy: _saving,
                busyLabel: _editing ? 'Saving…' : 'Publishing…',
                label: _editing ? 'Save changes' : 'Publish game',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose a public venue and clear meeting instructions. Your game will be visible to signed-in players.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    ),
  );
}
