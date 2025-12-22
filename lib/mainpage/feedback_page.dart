import 'package:flutter/material.dart';
import '../services/user_service.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _feedbackController = TextEditingController();
  final UserService _userService = UserService();
  bool _isLoading = false;

  void _send() async {
    final text = _feedbackController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isLoading = true);
    final success = await _userService.sendFeedback(text);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Terima Kasih!"),
          content: const Text("Masukan Anda sangat berharga bagi kami."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Tutup dialog
                Navigator.pop(context); // Kembali ke Settings
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal mengirim masukan"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Beri Masukan")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Apa yang bisa kami tingkatkan? Ceritakan pengalaman Anda.",
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _feedbackController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: "Tulis masukan Anda di sini...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _send,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Kirim"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
