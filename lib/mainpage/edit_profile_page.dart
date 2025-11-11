import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _displayNameController = TextEditingController(text: 'Bunda Hebat');
  final _usernameController = TextEditingController(text: '@bundahebat123');
  final _bioController = TextEditingController(text: 'Menyebarkan positivitas dan saling mendukung. Di sini untuk mendengar dan membantu.');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                InkWell(
                  onTap: () {},
                  child: Container(
                    height: 160,
                    margin: const EdgeInsets.symmetric(horizontal: 24.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.0),
                      image: const DecorationImage(
                        image: NetworkImage(
                          'https://images.pexels.com/photos/933054/pexels-photo-933054.jpeg?auto=compress&cs=tinysrgb&w=1260',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Center(
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withOpacity(0.5),
                        child: const Icon(Icons.camera_alt, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -50,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 54,
                        backgroundColor: theme.colorScheme.surface,
                        child: const CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=12'),
                        ),
                      ),
                      InkWell(
                        onTap: () {},
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: theme.colorScheme.primary,
                          child: const Icon(Icons.edit, size: 20, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 80),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  TextField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Tampilan',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _bioController,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                    keyboardType: TextInputType.multiline,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}