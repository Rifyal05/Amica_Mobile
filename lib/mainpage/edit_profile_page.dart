import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _displayNameController = TextEditingController(text: 'Bunda Hebat');
  final _usernameController = TextEditingController(text: 'bundahebat123');
  final _bioController = TextEditingController(
    text: 'Menyebarkan positivitas dan saling mendukung.',
  );

  bool _isLoading = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /*
  =============================================================================
  ANALISIS WHITE-BOX TESTING: FUNGSI _handleSaveProfile
  -----------------------------------------------------------------------------
  Tujuan: Memastikan integritas data profil sebelum disimpan.

  Validasi yang dilakukan:
  1. Nama Tampilan tidak boleh kosong.
  2. Username tidak boleh kosong.
  3. Username tidak boleh mengandung spasi.
  4. Username hanya boleh huruf, angka, dan underscore (Regex).
  5. Username minimal 4 karakter.
  6. Bio tidak boleh lebih dari 150 karakter.
  7. (Simulasi Backend) Cek apakah username sudah dipakai orang lain.
  =============================================================================
  */
  void _handleSaveProfile() async {
    final displayName = _displayNameController.text.trim();
    final username = _usernameController.text.trim();
    final bio = _bioController.text.trim();

    // 1. Validasi Nama Tampilan
    if (displayName.isEmpty) {
      _showSnackbar('Nama tampilan tidak boleh kosong.');
      return;
    }

    // 2. Validasi Username Kosong
    if (username.isEmpty) {
      _showSnackbar('Username tidak boleh kosong.');
      return;
    }

    // 3. Validasi Spasi pada Username
    if (username.contains(' ')) {
      _showSnackbar('Username tidak boleh mengandung spasi.');
      return;
    }

    // 4. Validasi Karakter Ilegal (Hanya Alfanumerik dan Underscore)
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(username)) {
      _showSnackbar('Username hanya boleh huruf, angka, dan garis bawah (_).');
      return;
    }

    // 5. Validasi Panjang Username
    if (username.length < 4) {
      _showSnackbar('Username minimal 4 karakter.');
      return;
    }

    // 6. Validasi Panjang Bio
    if (bio.length > 150) {
      _showSnackbar('Bio maksimal 150 karakter.');
      return;
    }

    // Mulai proses simpan
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));

    // 7. Validasi Duplikasi Username
    if (username.toLowerCase() == 'admin' || username.toLowerCase() == 'user01') {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackbar('Username "$username" sudah digunakan pengguna lain.');
      }
      return;
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _showSnackbar('Profil berhasil diperbarui!', isError: false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleSaveProfile,
            child: _isLoading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
          children: [
            // Bagian Foto Profil & Banner
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                InkWell(
                  onTap: () {
                    _showSnackbar('Fitur ganti banner belum diimplementasikan.', isError: false);
                  },
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
                        backgroundColor: Colors.black.withAlpha(100),
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
                          backgroundImage: NetworkImage(
                            'https://res.cloudinary.com/dk0z4ums3/image/upload/v1661753020/attached_image/inilah-cara-merawat-anak-kucing-yang-tepat.jpg',
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          _showSnackbar('Fitur ganti avatar belum diimplementasikan.', isError: false);
                        },
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: theme.colorScheme.primary,
                          child: const Icon(
                            Icons.edit,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 80),

            // Form Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  TextField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Tampilan',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      helperText: 'Huruf, angka, & underscore. Min 4 karakter.',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _bioController,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                    maxLength: 150, // Visual limit di Flutter
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