import 'package:flutter/material.dart';

class SdResultsPage extends StatelessWidget {
  final List<int?> answers;
  const SdResultsPage({super.key, required this.answers});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Kuis')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              const Text(
                "Kuis Selesai!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                "Terima kasih telah meluangkan waktu. Hasilnya akan segera diproses dan ditampilkan di sini.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Selesai'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
