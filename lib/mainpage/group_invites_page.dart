import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/chat_service.dart';
import 'package:intl/intl.dart';

class GroupInvitesPage extends StatefulWidget {
  final String chatId;
  const GroupInvitesPage({super.key, required this.chatId});

  @override
  State<GroupInvitesPage> createState() => _GroupInvitesPageState();
}

class _GroupInvitesPageState extends State<GroupInvitesPage> {
  final ChatService _chatService = ChatService();
  List<dynamic> _invites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInvites();
  }

  Future<void> _fetchInvites() async {
    try {
      final data = await _chatService.getActiveInvites(widget.chatId);
      if (mounted) {
        setState(() {
          _invites = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _revoke(String token) async {
    try {
      await _chatService.revokeInvite(token);
      _fetchInvites();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Link dicabut")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Gagal mencabut link")));
    }
  }

  String _formatDate(String iso) {
    if (iso == "Selamanya") return "Tidak terbatas";
    try {
      final date = DateTime.parse(iso).toLocal();
      return DateFormat('dd MMM HH:mm').format(date);
    } catch (e) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        title: const Text("Link Undangan Aktif"),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _invites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.link_off, size: 64, color: colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    "Tidak ada link aktif",
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _invites.length,
              itemBuilder: (context, index) {
                final inv = _invites[index];
                return Card(
                  color: colorScheme.surface,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      inv['url'],
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        _infoRow(
                          Icons.person,
                          "Dibuat oleh: ${inv['created_by']}",
                          colorScheme,
                        ),
                        const SizedBox(height: 4),
                        _infoRow(
                          Icons.timer,
                          "Exp: ${_formatDate(inv['expires_at'])}",
                          colorScheme,
                        ),
                        const SizedBox(height: 4),
                        _infoRow(
                          Icons.group,
                          "Dipakai: ${inv['uses']}",
                          colorScheme,
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _revoke(inv['token']),
                      tooltip: "Hapus Link",
                    ),
                    onLongPress: () {
                      Clipboard.setData(ClipboardData(text: inv['url']));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Link disalin")),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _infoRow(IconData icon, String text, ColorScheme scheme) {
    return Row(
      children: [
        Icon(icon, size: 14, color: scheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
