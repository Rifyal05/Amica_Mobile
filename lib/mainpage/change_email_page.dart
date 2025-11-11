import 'package:flutter/material.dart';

class ChangeEmailPage extends StatefulWidget {
  const ChangeEmailPage({super.key});

  @override
  State<ChangeEmailPage> createState() => _ChangeEmailPageState();
}

class _ChangeEmailPageState extends State<ChangeEmailPage> {
  final _newEmailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _saveEmail() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email berhasil diperbarui!')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ganti Email'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Masukkan email baru Anda. Untuk keamanan, kami memerlukan password Anda saat ini untuk menyimpan perubahan.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _newEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Baru',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password Saat Ini',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveEmail,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
              child: const Text('Simpan Perubahan'),
            ),
          ],
        ),
      ),
    );
  }
}