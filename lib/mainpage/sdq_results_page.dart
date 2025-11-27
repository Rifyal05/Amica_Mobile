import 'package:flutter/material.dart';
import 'dart:math';

const Map<String, dynamic> MOCK_INTERPRETATION_RESULT = {
  "total_score": 15,
  "total_level": "borderline",
  "overall_summary": {
    "title": "Gambaran Umum: Ada Beberapa Area yang Perlu Diperhatikan",
    "description": "Hasil ini menunjukkan ada beberapa area di mana anak Anda mungkin mengalami sedikit kesulitan.",
    "advice": "Fokus pada area yang ditandai di bawah ini. Coba ajak anak berbicara santai tentang harinya di sekolah atau dengan teman-temannya."
  },
  "detailed_breakdown": [
    {
      "scale": "emotional", "title": "Gejala Emosional", "score": 4, "level": "borderline",
      "description": "Anak Anda menunjukkan beberapa tanda kekhawatiran atau kesedihan."
    },
    {
      "scale": "conduct", "title": "Masalah Perilaku", "score": 2, "level": "normal",
      "description": "Anak Anda umumnya patuh dan dapat mengelola emosi marahnya dengan baik."
    },
    {
      "scale": "hyperactivity", "title": "Hiperaktivitas & Konsentrasi", "score": 7, "level": "abnormal",
      "description": "Anak Anda menunjukkan kesulitan yang signifikan untuk tetap tenang."
    },
    {
      "scale": "prosocial", "title": "Perilaku Prososial", "score": 10, "level": "info",
      "description": "Skor ini mengukur sejauh mana anak Anda peduli pada perasaan orang lain."
    },
  ]
};

class SdResultsPage extends StatelessWidget {
  final List<int?> answers;
  final Map<String, dynamic>? fullInterpretationResult;

  const SdResultsPage({
    super.key,
    required this.answers,
    this.fullInterpretationResult,
  });

  Color _getLevelColor(String level) {
    switch (level) {
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
    final result = fullInterpretationResult ?? MOCK_INTERPRETATION_RESULT;
    final overallSummary = result['overall_summary'] as Map<String, dynamic>;
    final totalLevel = result['total_level'] as String;
    final breakdown = result['detailed_breakdown'] as List<dynamic>;

    final totalColor = _getLevelColor(totalLevel);

    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Kuis SDQ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 80,
              color: totalColor,
            ),
            const SizedBox(height: 24),
            Text(
              "SKOR KESULITAN TOTAL: ${result['total_score']}",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: totalColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              overallSummary['title'],
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              overallSummary['description'],
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),

            const SizedBox(height: 32),

            _buildSuggestionBox(context, overallSummary['advice']),

            const SizedBox(height: 32),

            Text(
              'Rincian Berdasarkan Skala',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            ...breakdown.map((item) {
              final itemLevel = item['level'] as String;
              final itemColor = _getLevelColor(itemLevel);

              return _buildScaleTile(
                context,
                title: item['title'],
                score: item['score'],
                description: item['description'],
                color: itemColor,
              );
            }).toList(),

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
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(advice, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildScaleTile(BuildContext context, {required String title, required int score, required String description, required Color color}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.5), width: 1.5)
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(Icons.circle, size: 10, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        trailing: Text('Skor: $score', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
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