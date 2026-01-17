import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post_model.dart';
import '../provider/moderation_provider.dart';

class ModerationDetailPage extends StatelessWidget {
  final Post post;
  const ModerationDetailPage({super.key, required this.post});

  void _showAppealDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ajukan Banding"),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Jelaskan kenapa postingan ini aman...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              Navigator.pop(context);
              final res = await context.read<ModerationProvider>().sendAppeal(
                post.id,
                controller.text,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(res['message'])));
                Navigator.pop(context);
              }
            },
            child: const Text("Kirim"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDeletedByAdmin =
        post.moderationStatus == 'final_rejected' ||
        post.moderationStatus == 'quarantined';

    return Scaffold(
      appBar: AppBar(title: const Text("Detail Moderasi")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.imageUrl != null &&
                post.imageUrl!.isNotEmpty &&
                !isDeletedByAdmin)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: CachedNetworkImage(
                    imageUrl: post.fullImageUrl!,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
              )
            else if (isDeletedByAdmin)
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.error.withOpacity(0.3)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delete_forever_outlined,
                      size: 48,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Konten telah dihapus oleh Admin",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            const Text(
              "Caption:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(post.caption, style: theme.textTheme.bodyLarge),
            const Divider(height: 40),

            if (!isDeletedByAdmin) ...[
              _buildAnalysisCard(colorScheme),
              const SizedBox(height: 20),
            ],

            if (post.adminNote != null) _buildAdminNoteCard(colorScheme),

            const SizedBox(height: 32),
            if (post.moderationStatus == 'rejected') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showAppealDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("AJUKAN BANDING"),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    final ok = await context
                        .read<ModerationProvider>()
                        .acceptDecision(post.id);
                    if (ok && context.mounted) Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                  ),
                  child: const Text("SAYA MENGERTI, HAPUS POSTINGAN"),
                ),
              ),
            ] else if (isDeletedByAdmin) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () async {
                    await context.read<ModerationProvider>().acceptDecision(
                      post.id,
                    );
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("TUTUP & BERSIHKAN"),
                ),
              ),
            ] else ...[
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      "Sedang ditinjau oleh Admin...",
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisCard(ColorScheme colorScheme) {
    final details = post.moderationDetails;
    if (details == null || details.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.error.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology_outlined,
                color: colorScheme.error,
                size: 22,
              ),
              const SizedBox(width: 8),
              const Text(
                "Analisis AI Amica",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...details.entries.map((entry) {
            String label = entry.key.replaceAll('_', ' ').toUpperCase();
            bool isSafe =
                entry.value == null ||
                entry.value.toString().toLowerCase() == 'safe' ||
                entry.value.toString().toLowerCase() == 'bersih';
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  children: [
                    TextSpan(text: "• $label: "),
                    TextSpan(
                      text: isSafe
                          ? "SAFE"
                          : entry.value.toString().toUpperCase(),
                      style: TextStyle(
                        color: isSafe ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAdminNoteCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.admin_panel_settings_outlined,
                color: colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                "Keputusan Admin",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(post.adminNote!, style: const TextStyle(height: 1.5)),
        ],
      ),
    );
  }
}
