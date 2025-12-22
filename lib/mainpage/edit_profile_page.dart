import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/user_profile_model.dart';
import '../services/user_service.dart';
import '../provider/profile_provider.dart';

class EditProfilePage extends StatefulWidget {
  final UserProfileData profile;
  const EditProfilePage({super.key, required this.profile});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameCtrl;
  late TextEditingController _usernameCtrl;
  late TextEditingController _bioCtrl;

  File? _newAvatar;
  File? _newBanner;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile.displayName);
    _usernameCtrl = TextEditingController(text: widget.profile.username);
    _bioCtrl = TextEditingController(text: widget.profile.bio ?? "");
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isAvatar) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          if (isAvatar)
            _newAvatar = File(image.path);
          else
            _newBanner = File(image.path);
        });
      }
    } catch (e) {
      _showSnackbar("Gagal mengambil gambar: $e");
    }
  }

  void _showSnackbar(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  Future<void> _handleSaveProfile() async {
    setState(() => _isLoading = true);

    final service = UserService();
    final result = await service.updateProfile(
      displayName: _nameCtrl.text,
      username: _usernameCtrl.text,
      bio: _bioCtrl.text,
      avatarFile: _newAvatar,
      bannerFile: _newBanner,
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      if (mounted) {
        _showSnackbar("Profil berhasil diperbarui!", isError: false);
        context.read<ProfileProvider>().loadFullProfile(widget.profile.id);

        Navigator.pop(context);
      }
    } else {
      _showSnackbar(result['message']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profil"),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleSaveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Simpan',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              InkWell(
                onTap: () => _pickImage(false),
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                    image: _newBanner != null
                        ? DecorationImage(
                            image: FileImage(_newBanner!),
                            fit: BoxFit.cover,
                          )
                        : (widget.profile.fullBannerUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(
                                    widget.profile.fullBannerUrl!,
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null),
                  ),
                  child: Center(
                    child: CircleAvatar(
                      backgroundColor: Colors.black45,
                      child: const Icon(Icons.camera_alt, color: Colors.white),
                    ),
                  ),
                ),
              ),
              // Avatar
              Positioned(
                bottom: -40,
                child: InkWell(
                  onTap: () => _pickImage(true), // Pick Avatar
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: theme.colorScheme.surface,
                        child: CircleAvatar(
                          radius: 46,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _newAvatar != null
                              ? FileImage(_newAvatar!)
                              : (widget.profile.fullAvatarUrl != null
                                    ? NetworkImage(
                                            widget.profile.fullAvatarUrl!,
                                          )
                                          as ImageProvider
                                    : null),
                          child:
                              _newAvatar == null &&
                                  widget.profile.fullAvatarUrl == null
                              ? const Icon(Icons.person, size: 40)
                              : null,
                        ),
                      ),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: theme.colorScheme.primary,
                        child: const Icon(
                          Icons.edit,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 60),

          // Form Fields
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: "Nama Tampilan",
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _usernameCtrl,
            decoration: const InputDecoration(
              labelText: "Username",
              prefixIcon: Icon(Icons.alternate_email),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _bioCtrl,
            decoration: const InputDecoration(
              labelText: "Bio",
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 3,
            maxLength: 150,
          ),
        ],
      ),
    );
  }
}
