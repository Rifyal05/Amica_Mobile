import 'package:flutter/material.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _feedbackController = TextEditingController();

  void _submitFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Terima kasih atas masukan Anda!')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beri Masukan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Kami sangat menghargai masukan Anda untuk membuat Amica menjadi lebih baik.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _feedbackController,
              decoration: const InputDecoration(
                hintText: 'Tulis masukan, saran, atau laporan bug Anda di sini...',
                border: OutlineInputBorder(),
              ),
              maxLines: 10,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitFeedback,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
              child: const Text('Kirim Masukan'),
            ),
          ],
        ),
      ),
    );
  }
}