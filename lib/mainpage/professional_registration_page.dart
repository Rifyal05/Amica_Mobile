import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/user_service.dart';

class ProfessionalRegistrationPage extends StatefulWidget {
  const ProfessionalRegistrationPage({super.key});

  @override
  State<ProfessionalRegistrationPage> createState() =>
      _ProfessionalRegistrationPageState();
}

class _ProfessionalRegistrationPageState
    extends State<ProfessionalRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _strCtrl = TextEditingController();
  final _provinceCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _scheduleCtrl = TextEditingController();

  File? _strImage;
  File? _ktpImage;
  File? _selfieImage;
  bool _isLoading = false;

  final UserService _userService = UserService();
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(String type) async {
    final XFile? image = await _picker.pickImage(
      source: type == 'selfie' ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        if (type == 'str') _strImage = File(image.path);
        if (type == 'ktp') _ktpImage = File(image.path);
        if (type == 'selfie') _selfieImage = File(image.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_strImage == null || _ktpImage == null || _selfieImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Harap lengkapi semua dokumen foto (STR, KTP, Selfie)"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _userService.applyVerification(
      fullName: _nameCtrl.text,
      strNumber: _strCtrl.text,
      province: _provinceCtrl.text,
      address: _addressCtrl.text,
      schedule: _scheduleCtrl.text,
      strImage: _strImage!,
      ktpImage: _ktpImage!,
      selfieImage: _selfieImage!,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success']) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text("Berhasil Dikirim"),
            content: const Text(
              "Data Anda telah kami terima dan sedang dalam proses peninjauan oleh Admin. Harap tunggu 1-3 hari kerja.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Verifikasi Psikolog")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified_user, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Dapatkan lencana terverifikasi dan kepercayaan lebih dari pengguna dengan memvalidasi lisensi profesional Anda.",
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Data Profesional",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameCtrl,
                label: "Nama Lengkap & Gelar",
                hint: "Cth: Dr. Anna, S.Psi., Psikolog",
              ),
              _buildTextField(
                controller: _strCtrl,
                label: "Nomor STRPK",
                hint: "Masukkan 16 digit nomor registrasi",
                keyboardType: TextInputType.number,
              ),
              _buildTextField(
                controller: _provinceCtrl,
                label: "Provinsi Wilayah Praktik",
                hint: "Cth: Jawa Tengah",
              ),
              _buildTextField(
                controller: _addressCtrl,
                label: "Alamat Praktik / Klinik",
                hint: "Nama klinik dan alamat lengkap",
                maxLines: 2,
              ),
              _buildTextField(
                controller: _scheduleCtrl,
                label: "Jadwal Praktik",
                hint: "Cth: Senin - Jumat (09:00 - 15:00)",
              ),
              const SizedBox(height: 24),
              Text(
                "Dokumen Validasi",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Unggah foto dokumen asli. Pastikan tulisan terbaca jelas.",
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              _buildImagePickerBox("Foto Sertifikat STRPK", _strImage, 'str'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildImagePickerBox("Foto KTP", _ktpImage, 'ktp'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildImagePickerBox(
                      "Selfie + KTP",
                      _selfieImage,
                      'selfie',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submitForm,
                  child: _isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  )
                      : const Text("Kirim Permohonan"),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: (val) => val == null || val.isEmpty ? "$label wajib diisi" : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildImagePickerBox(String label, File? imageFile, String type) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => _pickImage(type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: imageFile != null
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.2),
            width: imageFile != null ? 2 : 1,
          ),
          image: imageFile != null
              ? DecorationImage(
            image: FileImage(imageFile),
            fit: BoxFit.cover,
          )
              : null,
        ),
        child: imageFile == null
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'selfie'
                  ? Icons.camera_front
                  : Icons.add_photo_alternate_outlined,
              size: 32,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        )
            : Stack(
          children: [
            Positioned(
              right: 8,
              top: 8,
              child: CircleAvatar(
                radius: 12,
                backgroundColor: Colors.black54,
                child: const Icon(
                  Icons.edit,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}