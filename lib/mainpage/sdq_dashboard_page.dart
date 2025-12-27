import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/sdq_provider.dart';
import '../models/sdq_model.dart';
import 'sdq_quiz_page.dart';
import 'sdq_results_page.dart'; // Import halaman detail hasil

class SdDashboardPage extends StatefulWidget {
  const SdDashboardPage({super.key});

  @override
  State<SdDashboardPage> createState() => _SdDashboardPageState();
}

class _SdDashboardPageState extends State<SdDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SdqProvider>().fetchHistory();
    });
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'normal':
        return Colors.green;
      case 'borderline':
        return Colors.orange;
      case 'abnormal':
        return Colors.red;
      case 'info':
        return Colors.blue; // For prosocial, just a neutral info color
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SdqProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Deteksi Dini (SDQ)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.quiz_outlined),
              label: const Text('Mulai Kuis Baru'),
              onPressed: () {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (context) => const SdQuizPage(),
                      ),
                    )
                    .then((_) {
                      // Refresh history saat kembali dari quiz
                      context.read<SdqProvider>().fetchHistory();
                    });
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                textStyle: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Riwayat Kuis',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.history.isEmpty
                  ? const Center(child: Text("Belum ada riwayat."))
                  : ListView.builder(
                      itemCount: provider.history.length,
                      itemBuilder: (context, index) {
                        final item = provider.history[index];
                        final dateStr = item.date.split(
                          'T',
                        )[0];
                        final levelColor = _getLevelColor(
                          item.interpretationTitle.toLowerCase().contains(
                                'baik',
                              )
                              ? 'normal'
                              : (item.interpretationTitle
                                        .toLowerCase()
                                        .contains('perlu')
                                    ? 'abnormal'
                                    : 'borderline'),
                        );

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: levelColor.withOpacity(0.2),
                              child: Text(
                                "${item.totalScore}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: levelColor,
                                ),
                              ),
                            ),
                            title: Text(
                              item.interpretationTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text("Tanggal: $dateStr"),
                            trailing: const Icon(Icons.chevron_right),

                            onTap: () async {
                              final fullResult = await context
                                  .read<SdqProvider>()
                                  .fetchResultDetail(item.id);

                              if (fullResult != null && context.mounted) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        SdResultDetailPage(result: fullResult),
                                  ),
                                );
                              } else if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Gagal membuka detail."),
                                  ),
                                );
                              }
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
