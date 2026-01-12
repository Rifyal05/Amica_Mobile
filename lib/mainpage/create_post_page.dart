import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'post_upload_status_page.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();

  File? _imageFile;
  final List<String> _tags = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _captionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() => _tags.add(tag));
      _tagController.clear();
    }
  }

  Future<void> _submitPost() async {
    final caption = _captionController.text.trim();
    if (caption.isEmpty && _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tulis sesuatu atau upload gambar.")),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PostUploadStatusPage(
          caption: caption,
          tags: _tags,
          imageFile: _imageFile,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Buat Postingan",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: FilledButton(
              onPressed: _submitPost,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text("Kirim"),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _captionController,
                    maxLines: null,
                    autofocus: true,
                    style: const TextStyle(fontSize: 16),
                    decoration: const InputDecoration(
                      hintText: "Apa yang sedang Anda pikirkan?",
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_imageFile != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _imageFile!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            onPressed: () => setState(() => _imageFile = null),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.close),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  if (_tags.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      children: _tags
                          .map(
                            (tag) => Chip(
                              label: Text("#$tag"),
                              onDeleted: () =>
                                  setState(() => _tags.remove(tag)),
                              backgroundColor:
                                  colorScheme.surfaceContainerHighest,
                              side: BorderSide.none,
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant.withOpacity(0.3),
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.image_outlined,
                      color: colorScheme.primary,
                    ),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.camera_alt_outlined,
                      color: colorScheme.primary,
                    ),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withOpacity(
                          0.5,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.tag,
                            size: 18,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: TextField(
                              controller: _tagController,
                              decoration: const InputDecoration(
                                hintText: "Tambah tag...",
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              onSubmitted: (_) => _addTag(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: _addTag,
                            color: colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
