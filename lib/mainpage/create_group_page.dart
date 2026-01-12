import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../provider/chat_provider.dart';
import '../models/user_model.dart';
import 'connections_page.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _nameController = TextEditingController();
  File? _imageFile;
  final List<User> _selectedMembers = [];
  bool _allowInvites = false;
  bool _isLoading = false;

  void _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _imageFile = File(file.path));
  }

  void _selectMembers() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ConnectionsPage(isSelectionMode: true),
      ),
    );
    if (result != null && result is User) {
      if (!_selectedMembers.any((u) => u.id == result.id)) {
        setState(() => _selectedMembers.add(result));
      }
    }
  }

  void _createGroup() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Nama grup wajib diisi")));
      return;
    }
    setState(() => _isLoading = true);

    final chatId = await context.read<ChatProvider>().createGroup(
      _nameController.text,
      _imageFile,
      _selectedMembers,
      _allowInvites,
    );

    setState(() => _isLoading = false);
    if (chatId != null && mounted) {
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Gagal membuat grup")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Buat Grup Baru")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[200],
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!)
                    : null,
                child: _imageFile == null
                    ? const Icon(
                        Icons.add_a_photo,
                        size: 30,
                        color: Colors.grey,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Nama Grup",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text("Izinkan anggota mengundang?"),
              value: _allowInvites,
              onChanged: (val) => setState(() => _allowInvites = val),
            ),
            const Divider(),
            ListTile(
              title: Text("Anggota (${_selectedMembers.length})"),
              trailing: const Icon(Icons.person_add),
              onTap: _selectMembers,
            ),
            Wrap(
              spacing: 8,
              children: _selectedMembers
                  .map(
                    (u) => Chip(
                      label: Text(u.displayName),
                      onDeleted: () =>
                          setState(() => _selectedMembers.remove(u)),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : _createGroup,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Buat Grup"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
