import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportify/providers/auth_provider.dart';
import 'package:sportify/config/constants.dart';
import 'package:sportify/widgets/page_layout.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  String? _selectedArea;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _bioController = TextEditingController();
    _photoUrl = user?.photoURL;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final controller = TextEditingController(text: _photoUrl);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: const Text('Profile photo'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Public image URL',
            hintText: 'https://…',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final url = controller.text.trim();
              if (url.isEmpty ||
                  (Uri.tryParse(url)?.scheme == 'https' &&
                      Uri.tryParse(url)!.host.isNotEmpty)) {
                Navigator.pop(dialogContext, url);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (mounted && result != null) {
      setState(() => _photoUrl = result.isEmpty ? null : result);
    }
  }

  void _next() {
    if (_formKey.currentState!.validate()) {
      if (_selectedArea == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please select an area')));
        return;
      }

      final profileData = {
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'area': _selectedArea,
        'city': 'Hyderabad',
        'photoUrl': _photoUrl,
      };

      Navigator.pushNamed(
        context,
        '/onboarding/sports',
        arguments: profileData,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Profile'),
        automaticallyImplyLeading: false,
        actions: const [
          Center(
            child: Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Text(
                '1 of 3',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _photoUrl != null
                            ? NetworkImage(_photoUrl!)
                            : null,
                        child: _photoUrl == null
                            ? const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                maxLength: 60,
                validator: (value) => value == null || value.trim().length < 2
                    ? 'Enter at least two characters'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: 'Hyderabad',
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Area',
                  border: OutlineInputBorder(),
                ),
                value: _selectedArea,
                items: AppConstants.hyderabadAreas
                    .map(
                      (area) =>
                          DropdownMenuItem(value: area, child: Text(area)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedArea = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Bio (Optional)',
                  hintText: 'Tell others a bit about yourself...',
                  border: OutlineInputBorder(),
                ),
              ),
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
      ),
    );
  }
}
