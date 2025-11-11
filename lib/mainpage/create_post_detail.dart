import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CreatePostDetail extends StatefulWidget {
  final File? imageFile;
  const CreatePostDetail({super.key, required this.imageFile});

  @override
  State<CreatePostDetail> createState() => _CreatePostDetailState();
}

class _CreatePostDetailState extends State<CreatePostDetail> {
  File? _currentImageFile;
  final _captionController = TextEditingController();
  final _tagsController = TextEditingController();
  final List<String> _tags = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _currentImageFile = widget.imageFile;
  }

  void _addTags() {
    final text = _tagsController.text.trim();
    if (text.isEmpty) return;

    final newTags = text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty && !_tags.contains(tag))
        .toList();

    if (newTags.isNotEmpty) {
      setState(() {
        _tags.addAll(newTags);
      });
    }
    _tagsController.clear();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _currentImageFile = File(image.path);
      });
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  /*
  =============================================================================
  ANALISIS WHITE-BOX TESTING: FUNGSI _sharePost
  -----------------------------------------------------------------------------
  Teknik: Branch Coverage
  Tujuan: Memastikan logika validasi konten dieksekusi dengan benar sebelum
          postingan dibagikan.

  Fungsi ini memiliki 3 cabang keputusan utama:
  1. [Branch 1]: Pengecekan apakah postingan benar-benar kosong (tidak ada gambar
                 DAN tidak ada caption).
  2. [Branch 2]: Pengecekan apakah panjang caption melebihi batas maksimum
                 (misalnya 1000 karakter).
  3. [Branch 3]: Jalur sukses, di mana postingan dianggap valid dan proses
                 navigasi (simulasi pengiriman) dijalankan.

  Kasus Uji untuk Mencapai 100% Branch Coverage:
  1. Aksi: Tidak memilih gambar dan tidak mengisi caption, lalu tekan "Bagikan".
     -> Hasil: Mengeksekusi Branch 1. Menampilkan snackbar "Caption atau gambar
              tidak boleh kosong.".
  2. Aksi: Isi caption dengan teks yang sangat panjang (lebih dari 1000 karakter).
     -> Hasil: Mengeksekusi Branch 2. Menampilkan snackbar "Caption tidak boleh
              lebih dari 1000 karakter.".
  3. Aksi: Isi caption yang valid (misal: "Halo semua") atau pilih sebuah gambar.
     -> Hasil: Mengeksekusi Branch 3. Aplikasi akan kembali ke halaman utama.
  =============================================================================
  */
  void _sharePost() {
    final caption = _captionController.text.trim();

    // [Branch 1]: Pengecekan konten kosong
    if (caption.isEmpty && _currentImageFile == null) {
      _showErrorSnackbar('Caption atau gambar tidak boleh kosong.');
      return;
    }

    // [Branch 2]: Pengecekan panjang caption
    if (caption.length > 1000) {
      _showErrorSnackbar('Caption tidak boleh lebih dari 1000 karakter.');
      return;
    }

    // [Branch 3]: Jalur sukses
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Postingan'),
        actions: [
          TextButton(
            onPressed: _sharePost,
            child: const Text('Bagikan'),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_currentImageFile != null)
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: Image.file(
                        _currentImageFile!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withOpacity(0.6),
                      child: IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.white, size: 20),
                        onPressed: () {
                          setState(() {
                            _currentImageFile = null;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Tambah Gambar'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 80),
                ),
                onPressed: () => _pickImage(ImageSource.gallery),
              ),
            const SizedBox(height: 24),
            TextField(
              controller: _captionController,
              decoration: const InputDecoration(
                hintText: 'Tulis caption di sini...',
                border: OutlineInputBorder(),
              ),
              maxLines: _currentImageFile == null ? 8 : 4,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _tagsController,
              decoration: InputDecoration(
                labelText: 'Tambah Tag',
                helperText: 'Pisahkan dengan koma untuk beberapa tag.',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addTags,
                ),
              ),
              onSubmitted: (_) => _addTags(),
            ),
            const SizedBox(height: 16),
            if (_tags.isNotEmpty)
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    onDeleted: () {
                      setState(() {
                        _tags.remove(tag);
                      });
                    },
                  );
                }).toList(),
              ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _sharePost,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
              child: const Text('Bagikan Postingan'),
            ),
          ],
        ),
      ),
    );
  }
}