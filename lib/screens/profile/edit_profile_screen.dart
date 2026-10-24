import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportify/config/constants.dart';
import 'package:sportify/config/theme.dart';
import 'package:sportify/providers/user_provider.dart';
import 'package:sportify/providers/connection_provider.dart';
import 'package:sportify/widgets/availability_grid.dart';
import 'package:sportify/widgets/sport_chip.dart';
import 'package:sportify/widgets/page_layout.dart';
import 'package:sportify/screens/notifications/notifications_screen.dart';
import 'package:sportify/services/session_service.dart';

class EditProfileScreen extends StatefulWidget {
  final bool embedded;
  const EditProfileScreen({super.key, this.embedded = true});
  @override
  State<EditProfileScreen> createState() => EditProfileScreenState();
}

class EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _bio = TextEditingController(),
      _photo = TextEditingController();
  String? _uid;
  String _area = '';
  bool _saving = false;
  String? _savedDraft;
  bool _promptOpen = false;
  bool _allowPop = false;
  bool _loadingDraft = false;
  final Map<String, List<String>> _availability = {};
  final Map<String, String> _sports = {};

  String get _draft {
    final sports = _sports.keys.toList()..sort();
    final days =
        _availability.keys
            .where((day) => _availability[day]!.isNotEmpty)
            .toList()
          ..sort();
    return jsonEncode([
      _name.text.trim(),
      _bio.text.trim(),
      _photo.text.trim(),
      _area,
      for (final sport in sports) [sport, _sports[sport]],
      for (final day in days)
        [
          day,
          [..._availability[day]!]..sort(),
        ],
    ]);
  }

  bool get _dirty => _savedDraft != null && _savedDraft != _draft;

  /// Used by both mobile and desktop navigation before leaving this editor.
  Future<bool> confirmLeave() async {
    if (_saving || _promptOpen) return false;
    if (!_dirty) return true;
    _promptOpen = true;
    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.edit_note_rounded),
        title: const Text('Save your profile changes?'),
        content: const Text(
          'Your edits haven’t been saved yet. Save them now, or discard them to return to your saved profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'stay'),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'discard'),
            child: const Text('Discard changes'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, 'save'),
            child: const Text('Save changes'),
          ),
        ],
      ),
    );
    _promptOpen = false;
    if (!mounted) return false;
    if (choice == 'save') return _save();
    if (choice == 'discard') {
      setState(() => _uid = null);
      return true;
    }
    return false;
  }

  Future<void> _openPage(Widget page) async {
    if (await confirmLeave() && mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _photo.dispose();
    super.dispose();
  }

  Future<bool> _save() async {
    if (_saving || !(_form.currentState?.validate() ?? false)) return false;
    if (_sports.isEmpty ||
        _availability.values.every((slots) => slots.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Choose at least one sport and one available time slot.',
          ),
        ),
      );
      return false;
    }
    setState(() => _saving = true);
    var saved = false;
    await runAction(context, () async {
      await context.read<UserProvider>().updateUserProfile(_uid!, {
        'name': _name.text.trim(),
        'bio': _bio.text.trim(),
        'area': _area,
        'photoUrl': _photo.text.trim().isEmpty ? null : _photo.text.trim(),
        'sports': _sports.entries
            .map((e) => {'sport': e.key, 'skillLevel': e.value})
            .toList(),
        'availability': _availability.map(
          (day, slots) => MapEntry(day, [...slots]),
        ),
      });
      _savedDraft = _draft;
      saved = true;
    }, success: 'Your profile has been updated.');
    if (mounted) setState(() => _saving = false);
    return saved;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();
    final user = provider.currentUser;
    if (user == null) {
      return const EmptyState(
        title: 'Profile unavailable',
        message: 'Please sign in again to load your profile.',
      );
    }
    if (_uid != user.uid) {
      _loadingDraft = true;
      _uid = user.uid;
      _name.text = user.name;
      _bio.text = user.bio ?? '';
      _photo.text = user.photoUrl ?? '';
      _area = user.area;
      _availability.clear();
      _availability.addAll(
        user.availability.map((k, v) => MapEntry(k, [...v])),
      );
      _sports.clear();
      for (final sport in user.sports) {
        _sports[(sport['sport'] ?? sport['name']).toString()] =
            sport['skillLevel'] as String? ?? 'Intermediate';
      }
      _savedDraft = _draft;
      _loadingDraft = false;
    }
    final requests = context.watch<ConnectionProvider>().pendingRequests.length;
    return PopScope(
      canPop: widget.embedded || (!_saving && (!_dirty || _allowPop)),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || widget.embedded) return;
        if (await confirmLeave() && mounted) {
          setState(() => _allowPop = true);
          await WidgetsBinding.instance.endOfFrame;
          if (context.mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: widget.embedded
            ? null
            : AppBar(title: const Text('Edit profile')),
        body: PageLayout(
          maxWidth: 760,
          child: SingleChildScrollView(
            key: const ValueKey('profile-scroll'),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              onChanged: () {
                if (!_loadingDraft) setState(() {});
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your player profile',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Keep your interests and free time up to date.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Settings',
                        onPressed: () async {
                          if (await confirmLeave() && context.mounted) {
                            Navigator.pushNamed(context, '/settings');
                          }
                        },
                        icon: const Icon(Icons.settings_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (requests > 0)
                    ListTile(
                      tileColor: AppColors.surfaceVariant,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      leading: const Icon(Icons.person_add_outlined),
                      title: Text('$requests connection requests'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openPage(NotificationsScreen()),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: AppColors.surfaceVariant,
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : 'S',
                          style: const TextStyle(
                            fontSize: 28,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              user.email,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _name,
                          maxLength: 60,
                          decoration: const InputDecoration(labelText: 'Name'),
                          validator: (v) => v!.trim().length < 2
                              ? 'Enter at least two characters'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _bio,
                          maxLines: 3,
                          maxLength: 300,
                          decoration: const InputDecoration(
                            labelText: 'About you',
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: AppConstants.hyderabadAreas.contains(_area)
                              ? _area
                              : null,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Area'),
                          validator: (v) =>
                              v == null ? 'Select your area' : null,
                          items: AppConstants.hyderabadAreas
                              .map(
                                (a) =>
                                    DropdownMenuItem(value: a, child: Text(a)),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _area = v ?? _area),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _photo,
                          decoration: const InputDecoration(
                            labelText: 'Photo URL (optional)',
                            hintText: 'https://…',
                          ),
                          validator: (v) {
                            final url = v!.trim();
                            final uri = Uri.tryParse(url);
                            return url.isNotEmpty &&
                                    (uri?.scheme != 'https' ||
                                        uri!.host.isEmpty)
                                ? 'Use a public HTTPS image URL'
                                : null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Your sports',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppConstants.sports.map((s) {
                      final name = s['name'] as String;
                      return SportChip(
                        sportName: name,
                        icon: s['icon'] as IconData,
                        isSelected: _sports.containsKey(name),
                        onTap: () => setState(() {
                          if (!_sports.containsKey(name)) {
                            _sports[name] = 'Intermediate';
                          } else {
                            _sports.remove(name);
                          }
                        }),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  ..._sports.keys.map(
                    (sport) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DropdownButtonFormField<String>(
                        value: _sports[sport],
                        isExpanded: true,
                        decoration: InputDecoration(labelText: '$sport skill'),
                        items: AppConstants.skillLevels
                            .map(
                              (level) => DropdownMenuItem(
                                value: level,
                                child: Text(level),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _sports[sport] = v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Your weekly free time',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tap a slot to change it. Blue means you’re available.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  AvailabilityGrid(
                    availability: _availability,
                    onToggle: (day, slot) => setState(() {
                      final slots = _availability.putIfAbsent(day, () => []);
                      if (slots.contains(slot)) {
                        slots.remove(slot);
                      } else {
                        slots.add(slot);
                      }
                      if (slots.isEmpty) _availability.remove(day);
                    }),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    _dirty ? 'Unsaved changes' : 'Your profile is up to date',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _dirty
                          ? AppColors.primaryDark
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 200,
                        maxWidth: 280,
                      ),
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _saving || !_dirty ? null : _save,
                        icon: const Icon(Icons.check_rounded),
                        label: Text(_saving ? 'Saving…' : 'Save changes'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _saving
                          ? null
                          : () async {
                              if (await confirmLeave() && context.mounted) {
                                await SessionService.signOut(context);
                              }
                            },
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Sign out'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
