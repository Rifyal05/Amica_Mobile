import 'package:flutter/material.dart';
import '../models/sdq_model.dart';

class SdResultDetailPage extends StatelessWidget {
  final SdqFullResult result;
  const SdResultDetailPage({super.key, required this.result});

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'normal':
      case 'info':
        return Colors.green;
      case 'borderline':
        return Colors.orange;
      case 'abnormal':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final interpretation = result.interpretation;
    final overallSummary = Map<String, dynamic>.from(
      interpretation['overall_summary'] ?? {},
    );
    final totalLevel = (interpretation['total_level'] ?? 'info').toString();
    final breakdown = interpretation['detailed_breakdown'] as List? ?? [];
    final totalScore = interpretation['total_score'] ?? 0;

    final totalColor = _getLevelColor(totalLevel);

    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Kuis SDQ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.analytics_outlined, size: 80, color: totalColor),
            const SizedBox(height: 24),
            Text(
              "SKOR KESULITAN TOTAL: $totalScore",
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: totalColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              overallSummary['title'] ?? 'Hasil Evaluasi',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              overallSummary['description'] ?? 'Tidak ada deskripsi tersedia.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            _buildSuggestionBox(
              context,
              overallSummary['advice'] ??
                  'Ikuti saran dari tenaga profesional jika diperlukan.',
            ),
            const SizedBox(height: 32),
            Text(
              'Rincian Berdasarkan Skala',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...breakdown.map((item) {
              final data = Map<String, dynamic>.from(item);
              final itemLevel = (data['level'] ?? 'info').toString();
              final itemColor = _getLevelColor(itemLevel);

              return _buildScaleTile(
                context,
                title: data['title'] ?? 'Skala',
                score: data['score'] ?? 0,
                description: data['description'] ?? '',
                color: itemColor,
              );
            }),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Selesai'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionBox(BuildContext context, String advice) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Saran Tindak Lanjut',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(advice, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildScaleTile(
    BuildContext context, {
    required String title,
    required int score,
    required String description,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(Icons.circle, size: 10, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        trailing: Text(
          'Skor: $score',
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            description,
            textAlign: TextAlign.justify,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
