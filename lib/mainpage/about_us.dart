import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Tentang Kami")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Image.asset('source/images/logo_dark.png', height: 100),
              const SizedBox(height: 20),
              Text(
                "Amica",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const Text(
                "Versi 1.0.0",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              const Text(
                "Amica adalah platform komunitas parenting yang berfokus pada edukasi dan pencegahan bullying. Misi kami adalah menciptakan lingkungan digital yang aman bagi orang tua untuk belajar dan berbagi pengalaman terkait perundungan pada anak.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, height: 1.6),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                "Dibuat dengan ❤️ untuk keluarga Indonesia",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}