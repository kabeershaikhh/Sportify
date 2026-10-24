import 'package:flutter/material.dart';
import 'package:sportify/config/constants.dart';
import 'package:sportify/widgets/sport_chip.dart';
import 'package:sportify/widgets/page_layout.dart';

class SportsSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> profileData;

  const SportsSelectionScreen({super.key, required this.profileData});

  @override
  State<SportsSelectionScreen> createState() => _SportsSelectionScreenState();
}

class _SportsSelectionScreenState extends State<SportsSelectionScreen> {
  final Map<String, String> _selectedSports = {}; // sport name -> skill level

  void _next() {
    if (_selectedSports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one sport')),
      );
      return;
    }

    final sportsData = _selectedSports.entries
        .map((e) => {'sport': e.key, 'skillLevel': e.value})
        .toList();

    final updatedData = Map<String, dynamic>.from(widget.profileData);
    updatedData['sports'] = sportsData;

    Navigator.pushNamed(
      context,
      '/onboarding/availability',
      arguments: updatedData,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Sports'),
        automaticallyImplyLeading: true,
        actions: const [
          Center(
            child: Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Text(
                '2 of 3',
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
              'What sports do you play?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: AppConstants.sports.map((sportObj) {
                final sportName = sportObj['name'] as String;
                final isSelected = _selectedSports.containsKey(sportName);

                return SportChip(
                  sportName: sportName,
                  icon: sportObj['icon'] as IconData,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedSports.remove(sportName);
                      } else {
                        _selectedSports[sportName] =
                            AppConstants.skillLevels[1]; // default Intermediate
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            if (_selectedSports.isNotEmpty) ...[
              const Text(
                'Skill Levels',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ..._selectedSports.keys.map((sport) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sport,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AppConstants.skillLevels
                            .map(
                              (skill) => ChoiceChip(
                                selected: _selectedSports[sport] == skill,
                                label: Text(
                                  skill,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                onSelected: (_) => setState(() {
                                  _selectedSports[sport] = skill;
                                }),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 32),
            CompactAction(
              child: ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
