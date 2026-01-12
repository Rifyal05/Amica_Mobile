import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../provider/moderation_provider.dart';
import 'moderation_detail_page.dart';

class ModerationListPage extends StatefulWidget {
  const ModerationListPage({super.key});

  @override
  State<ModerationListPage> createState() => _ModerationListPageState();
}

class _ModerationListPageState extends State<ModerationListPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ModerationProvider>().fetchModeratedPosts();
    });
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _getTimeRemaining(DateTime? expiresAt) {
    if (expiresAt == null) return "";
    final diff = expiresAt.difference(DateTime.now());
    if (diff.isNegative) return "Kadaluarsa";
    return "${diff.inHours}j ${diff.inMinutes % 60}m lagi";
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ModerationProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Status Konten")),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.moderatedPosts.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.moderatedPosts.length,
        itemBuilder: (context, index) {
          final post = provider.moderatedPosts[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ModerationDetailPage(post: post)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[300],
                    child: post.imageUrl != null
                        ? CachedNetworkImage(
                      imageUrl: post.fullImageUrl!,
                      fit: BoxFit.cover,
                    )
                        : const Icon(Icons.text_fields),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatusBadge(post),
                          const SizedBox(height: 4),
                          Text(
                            post.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (post.moderationStatus == 'rejected')
                            Text(
                              "Dihapus otomatis dalam: ${_getTimeRemaining(post.expiresAt)}",
                              style: TextStyle(color: Colors.red[400], fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(post) {
    final isAppealing = post.moderationStatus == 'appealing';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isAppealing ? Colors.orange.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isAppealing ? "SEDANG DITINJAU" : "DITOLAK AI",
        style: TextStyle(
          color: isAppealing ? Colors.orange : Colors.red,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.green[200]),
          const SizedBox(height: 16),
          const Text("Semua konten Anda aman!"),
        ],
      ),
    );
  }
}