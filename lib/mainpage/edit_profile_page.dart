import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  late TextEditingController _proAddressCtrl;
  late TextEditingController _proScheduleCtrl;
  late TextEditingController _proProvinceCtrl;

  String? _fixedProName;
  String? _fixedStrNumber;

  File? _newAvatar;
  File? _newBanner;
  bool _isLoading = false;

  bool get _isProfessional => widget.profile.isVerified == true;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile.displayName);
    _usernameCtrl = TextEditingController(text: widget.profile.username);
    _bioCtrl = TextEditingController(text: widget.profile.bio ?? "");

    if (_isProfessional) {
      _proAddressCtrl = TextEditingController(
        text: widget.profile.practiceAddress ?? "",
      );
      _proScheduleCtrl = TextEditingController(
        text: widget.profile.practiceSchedule ?? "",
      );
      _proProvinceCtrl = TextEditingController(
        text: widget.profile.province ?? "",
      );

      _fixedProName = widget.profile.fullNameWithTitle;
      _fixedStrNumber = widget.profile.strNumber;
    } else {
      _proAddressCtrl = TextEditingController();
      _proScheduleCtrl = TextEditingController();
      _proProvinceCtrl = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _proAddressCtrl.dispose();
    _proScheduleCtrl.dispose();
    _proProvinceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isAvatar) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          if (isAvatar) {
            _newAvatar = File(image.path);
          } else {
            _newBanner = File(image.path);
          }
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
      isProfessional: _isProfessional,
      practiceAddress: _isProfessional ? _proAddressCtrl.text : null,
      practiceSchedule: _isProfessional ? _proScheduleCtrl.text : null,
      province: _isProfessional ? _proProvinceCtrl.text : null,
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
    final colorScheme = theme.colorScheme;

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
                                  image: CachedNetworkImageProvider(
                                    widget.profile.fullBannerUrl!,
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null),
                  ),
                  child: const Center(
                    child: CircleAvatar(
                      backgroundColor: Colors.black45,
                      child: Icon(Icons.camera_alt, color: Colors.white),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -40,
                child: InkWell(
                  onTap: () => _pickImage(true),
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
                                        ? CachedNetworkImageProvider(
                                            widget.profile.fullAvatarUrl!,
                                          )
                                        : null)
                                    as ImageProvider?,
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

          Text(
            "Informasi Umum",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
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

          if (_isProfessional) ...[
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.verified, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  "Informasi Profesional",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "Nama resmi dan nomor STRPK tidak dapat diubah untuk menjaga validitas verifikasi.",
                style: TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: TextEditingController(text: _fixedProName),
              enabled: false,
              decoration: const InputDecoration(
                labelText: "Nama Resmi (Sesuai KTP/STR)",
                border: OutlineInputBorder(),
                filled: true,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: TextEditingController(text: _fixedStrNumber),
              enabled: false,
              decoration: const InputDecoration(
                labelText: "Nomor STRPK",
                border: OutlineInputBorder(),
                filled: true,
              ),
            ),

            const SizedBox(height: 16),
            TextField(
              controller: _proProvinceCtrl,
              decoration: const InputDecoration(
                labelText: "Wilayah / Provinsi",
                prefixIcon: Icon(Icons.map_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _proAddressCtrl,
              decoration: const InputDecoration(
                labelText: "Alamat Praktik",
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _proScheduleCtrl,
              decoration: const InputDecoration(
                labelText: "Jadwal Praktik",
                prefixIcon: Icon(Icons.calendar_today_outlined),
                border: OutlineInputBorder(),
                hintText: "Contoh: Senin - Jumat, 09:00 - 15:00",
              ),
            ),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }
}
