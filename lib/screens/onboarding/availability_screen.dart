import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportify/providers/auth_provider.dart';
import 'package:sportify/providers/user_provider.dart';
import 'package:sportify/models/user_model.dart';
import 'package:sportify/widgets/availability_grid.dart';

class AvailabilityScreen extends StatefulWidget {
  final Map<String, dynamic> profileData;

  const AvailabilityScreen({super.key, required this.profileData});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  final Map<String, List<String>> _availability = {};
  bool _isLoading = false;

  void _toggleSlot(String day, String slot) {
    setState(() {
      if (!_availability.containsKey(day)) {
        _availability[day] = [];
      }
      if (_availability[day]!.contains(slot)) {
        _availability[day]!.remove(slot);
        if (_availability[day]!.isEmpty) {
          _availability.remove(day);
        }
      } else {
        _availability[day]!.add(slot);
      }
    });
  }

  Future<void> _finish() async {
    final navigator = Navigator.of(context);
    if (_availability.values.every((slots) => slots.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Select at least one time slot so partners can find you.',
          ),
        ),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final userProvider = context.read<UserProvider>();
      final currentUser = authProvider.user;

      if (currentUser == null) throw Exception("User not logged in");

      // For MVP, use Google profile photo (no Storage upload needed)
      final photoUrl =
          widget.profileData['photoUrl'] as String? ?? currentUser.photoURL;

      final newUser = UserModel(
        uid: currentUser.uid,
        email: currentUser.email ?? '',
        name: widget.profileData['name'],
        photoUrl: photoUrl,
        bio: widget.profileData['bio'],
        city: widget.profileData['city'],
        area: widget.profileData['area'],
        sports: widget.profileData['sports'],
        availability: _availability,
        createdAt: DateTime.now(),
        isProfileComplete: true,
      );

      await userProvider.createUserProfile(newUser);

      if (navigator.mounted) {
        navigator.pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Availability'),
        automaticallyImplyLeading: true,
        actions: const [
          Center(
            child: Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Text(
                '3 of 3',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'When are you free to play?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the slots when you\'re usually available.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            AvailabilityGrid(
              availability: _availability,
              onToggle: _toggleSlot,
              isEditable: true,
            ),
            const SizedBox(height: 48),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _finish,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Finish'),
                  ),
          ],
        ),
      ),
    );
  }
}
