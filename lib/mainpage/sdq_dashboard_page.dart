import 'package:flutter/material.dart';
import 'sdq_quiz_page.dart';
import 'sdq_results_page.dart';

class SdDashboardPage extends StatelessWidget {
  const SdDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<Map<String, dynamic>> history = [
      {'date': '10 Nov 2025', 'score': 15, 'status': 'Agak Meningkat'},
      {'date': '15 Agu 2025', 'score': 12, 'status': 'Normal'},
      {'date': '20 Mei 2025', 'score': 18, 'status': 'Perlu Perhatian'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Deteksi Dini')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.quiz_outlined),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SdQuizPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              label: const Text('Mulai Kuis Baru'),
            ),
            const SizedBox(height: 32),
            Text(
              'Riwayat Kuis Anda',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = history[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(
                        'Kuis tanggal ${item['date']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Skor Kesulitan Total: ${item['score']} (${item['status']})',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const SdResultsPage(answers: []),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
