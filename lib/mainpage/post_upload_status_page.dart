import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/post_provider.dart';
import 'moderation_list_page.dart';

class PostUploadStatusPage extends StatefulWidget {
  final String caption;
  final List<String> tags;
  final File? imageFile;

  const PostUploadStatusPage({
    super.key,
    required this.caption,
    required this.tags,
    this.imageFile,
  });

  @override
  State<PostUploadStatusPage> createState() => _PostUploadStatusPageState();
}

class _PostUploadStatusPageState extends State<PostUploadStatusPage> {
  String _status = 'uploading';
  String? _errorMessage;
  Map<String, dynamic>? _moderationDetails;

  @override
  void initState() {
    super.initState();
    _startUpload();
  }

  Future<void> _startUpload() async {
    final provider = context.read<PostProvider>();
    final result = await provider.createPost(
      caption: widget.caption,
      tags: widget.tags,
      imageFile: widget.imageFile,
    );

    debugPrint("=== DEBUG HASIL UPLOAD ===");
    debugPrint("Raw Result: $result");
    debugPrint("Moderation Details: ${result['moderation_details']}");
    debugPrint("==========================");

    if (!mounted) return;

    setState(() {
      if (result['success']) {
        _status = 'approved';
      } else if (result['is_moderated'] == true) {
        _status = 'rejected';
        _errorMessage = result['message'];
        // Jika di log muncul datanya tapi di UI null, berarti key di bawah ini harus dipastikan sama
        _moderationDetails = result['moderation_details'];
      } else {
        _status = 'error';
        _errorMessage = result['message'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIcon(colorScheme),
              const SizedBox(height: 24),
              _buildText(theme),
              const SizedBox(height: 40),
              _buildActions(context, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(ColorScheme colorScheme) {
    if (_status == 'uploading') {
      return const SizedBox(
        width: 80,
        height: 80,
        child: CircularProgressIndicator(strokeWidth: 6),
      );
    }

    IconData icon;
    Color color;
    if (_status == 'approved') {
      icon = Icons.check_circle_rounded;
      color = Colors.green;
    } else if (_status == 'rejected') {
      icon = Icons.gpp_maybe_rounded;
      color = Colors.orange;
    } else {
      icon = Icons.error_outline_rounded;
      color = Colors.red;
    }

    return Icon(icon, size: 100, color: color);
  }

  Widget _buildText(ThemeData theme) {
    String title;
    String subtitle;

    if (_status == 'uploading') {
      title = "Sedang Mengirim";
      subtitle = "Mohon tunggu sebentar, kami sedang memproses postingan Anda.";
    } else if (_status == 'approved') {
      title = "Berhasil Terbit!";
      subtitle =
          "Postingan Anda sudah tayang dan dapat dilihat oleh komunitas.";
    } else if (_status == 'rejected') {
      title = "Postingan Ditahan";
      subtitle =
          _errorMessage ??
          "Konten Anda terdeteksi melanggar pedoman komunitas.";
    } else {
      title = "Gagal Mengirim";
      subtitle =
          _errorMessage ??
          "Terjadi kesalahan koneksi. Silakan coba lagi nanti.";
    }

    return Column(
      children: [
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        if (_status == 'rejected' && _moderationDetails != null) ...[
          const SizedBox(height: 20),
          _buildModerationAnalysis(theme.colorScheme),
        ],
      ],
    );
  }

  Widget _buildModerationAnalysis(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.error.withOpacity(0.2)),
      ),
      child: Column(
        children: _moderationDetails!.entries.map((entry) {
          final value = entry.value.toString().toLowerCase();
          final isSafe = value == 'safe' || value == 'SAFE';

          if (isSafe) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: colorScheme.error,
                ),
                const SizedBox(width: 6),
                Text(
                  "${entry.key.replaceAll('_', ' ').toUpperCase()}: ${entry.value.toString().toUpperCase()}",
                  style: TextStyle(
                    color: colorScheme.error,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActions(BuildContext context, ColorScheme colorScheme) {
    if (_status == 'uploading') return const SizedBox.shrink();

    if (_status == 'approved') {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("OK, LIHAT FEED"),
        ),
      );
    }

    if (_status == 'rejected') {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ModerationListPage()),
                );
              },
              child: const Text("LIHAT STATUS MODERASI"),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("TUTUP"),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => Navigator.pop(context),
        child: const Text("KEMBALI"),
      ),
    );
  }
}
