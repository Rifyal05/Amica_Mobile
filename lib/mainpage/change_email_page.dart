import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';
import '../services/user_service.dart';

class ChangeEmailPage extends StatefulWidget {
  const ChangeEmailPage({super.key});

  @override
  State<ChangeEmailPage> createState() => _ChangeEmailPageState();
}

class _ChangeEmailPageState extends State<ChangeEmailPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _oldEmailController = TextEditingController();

  final UserService _userService = UserService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        setState(() {
          _oldEmailController.text = user.email;
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _oldEmailController.dispose();
    super.dispose();
  }

  void _save() async {
    final newEmail = _emailController.text.trim();
    final password = _passwordController.text;

    if (newEmail.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email baru dan Password harus diisi")),
      );
      return;
    }

    if (!newEmail.contains('@')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Format email salah")));
      return;
    }

    if (newEmail == _oldEmailController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email baru tidak boleh sama dengan email saat ini"),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final error = await _userService.changeEmail(newEmail, password);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (error == null) {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;

      if (currentUser != null) {
        final updatedUser = currentUser.copyWith(email: newEmail);
        authProvider.updateUser(updatedUser);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email berhasil diubah."),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ganti Email")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Informasi Akun",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _oldEmailController,
              readOnly: true,
              enabled: false,
              decoration: const InputDecoration(
                labelText: "Email Saat Ini",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
                filled: true,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Perubahan Email",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Text(
              "Masukkan email baru dan password Anda saat ini untuk konfirmasi.",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email Baru",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.mark_email_unread_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password Saat Ini",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text("Simpan Perubahan"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
