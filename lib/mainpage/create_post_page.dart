import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'create_post_detail.dart';
import 'dart:io';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? imageFile = await _picker.pickImage(source: source);

    if (imageFile != null && mounted) {
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CreatePostDetail(imageFile: File(imageFile.path)),
          ));
    }
  }

  void _createTextPost() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CreatePostDetail(imageFile: null),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Postingan Baru'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Bagikan Cerita Anda',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Mulai dengan menulis atau pilih gambar untuk dibagikan.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 40),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit_note),
                onPressed: _createTextPost,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
                label: const Text('Tulis Postingan Teks'),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.photo_library_outlined),
                onPressed: () => _pickImage(ImageSource.gallery),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
                label: const Text('Pilih dari Galeri'),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.camera_alt_outlined),
                onPressed: () => _pickImage(ImageSource.camera),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
                label: const Text('Ambil Foto'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}