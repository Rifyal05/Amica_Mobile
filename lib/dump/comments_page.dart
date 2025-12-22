// import 'package:amica/mainpage/user_profile_page.dart';
// import 'package:amica/provider/comment_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../models/comment_model.dart';
// import 'package:intl/intl.dart';
//
// class CommentsPage extends StatefulWidget {
//   final String postId; // Kita butuh ID Post
//   const CommentsPage({super.key, required this.postId});
//
//   @override
//   State<CommentsPage> createState() => _CommentsPageState();
// }
//
// class _CommentsPageState extends State<CommentsPage> {
//   final _commentController = TextEditingController();
//   final FocusNode _focusNode = FocusNode();
//   Comment? _replyingToComment;
//   bool _isSending = false; // State lokal untuk loading tombol kirim
//
//   @override
//   void initState() {
//     super.initState();
//     // Load komentar saat halaman dibuka
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       context.read<CommentProvider>().loadComments(widget.postId);
//     });
//   }
//
//   // ... (Helper formatTimeAgo sama seperti sebelumnya) ...
//   String formatTimeAgo(DateTime timestamp) {
//     final difference = DateTime.now().difference(timestamp);
//     // ... (kode format waktu kamu yg lama) ...
//     if (difference.inDays < 7) return '${difference.inDays}h';
//     return DateFormat('d MMM').format(timestamp);
//   }
//
//   void _startReply(Comment comment) {
//     setState(() {
//       _replyingToComment = comment;
//     });
//     _focusNode.requestFocus();
//     // Opsional: tambah prefix nama user
//     // _commentController.text = '@${comment.user.username} ';
//   }
//
//   void _cancelReply() {
//     setState(() {
//       _replyingToComment = null;
//     });
//     _commentController.clear();
//     _focusNode.unfocus();
//   }
//
//   Future<void> _sendComment() async {
//     final text = _commentController.text.trim();
//     if (text.isEmpty) return;
//
//     setState(() => _isSending = true); // Tampilkan loading
//     _focusNode.unfocus();
//
//     final parentId = _replyingToComment?.id;
//
//     // Panggil Provider
//     final result = await context.read<CommentProvider>().addComment(
//         widget.postId,
//         text,
//         parentId: parentId
//     );
//
//     setState(() => _isSending = false); // Matikan loading
//
//     if (result['success']) {
//       _commentController.clear();
//       _cancelReply();
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Komentar terkirim!'), backgroundColor: Colors.green),
//       );
//     } else if (result['status'] == 'rejected') {
//       // TAMPILKAN POPUP MODERASI DITOLAK
//       _showModerationDialog(result['reason']);
//     } else {
//       // Error umum
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
//       );
//     }
//   }
//
//   void _showModerationDialog(String? reason) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Row(
//           children: const [
//             Icon(Icons.warning_amber_rounded, color: Colors.red),
//             SizedBox(width: 8),
//             Text('Komentar Ditolak'),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text('Sistem kami mendeteksi konten yang tidak sesuai dengan pedoman komunitas.'),
//             const SizedBox(height: 12),
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Colors.red.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Text(
//                 'Alasan: ${reason ?? "Terdeteksi konten negatif."}',
//                 style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('Saya Mengerti'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final provider = context.watch<CommentProvider>();
//
//     return Scaffold(
//       appBar: AppBar(title: const Text('Komentar')),
//       body: Column(
//         children: [
//           Expanded(
//             child: provider.isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : provider.comments.isEmpty
//                 ? Center(child: Text("Belum ada komentar.", style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey)))
//                 : ListView.builder(
//               padding: const EdgeInsets.all(12.0),
//               itemCount: provider.comments.length,
//               itemBuilder: (ctx, i) {
//                 final comment = provider.comments[i];
//                 return Column(
//                   children: [
//                     _CommentTile(
//                       comment: comment,
//                       timeAgo: formatTimeAgo(comment.timestamp),
//                       onTap: () => _startReply(comment),
//                     ),
//                     // Render Balasan (Replies)
//                     ...comment.replies.map((reply) => Padding(
//                       padding: const EdgeInsets.only(left: 48.0), // Indentasi
//                       child: _CommentTile(
//                         comment: reply,
//                         timeAgo: formatTimeAgo(reply.timestamp),
//                         onTap: () => _startReply(comment), // Reply ke parent
//                         isReply: true,
//                       ),
//                     )),
//                   ],
//                 );
//               },
//             ),
//           ),
//           _buildCommentInput(theme),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildCommentInput(ThemeData theme) {
//     return Container(
//       padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
//       decoration: BoxDecoration(
//         color: theme.colorScheme.surface,
//         boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
//       ),
//       child: SafeArea(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             if (_replyingToComment != null)
//               Container(
//                 margin: const EdgeInsets.only(bottom: 8),
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 decoration: BoxDecoration(
//                   color: theme.colorScheme.primaryContainer.withOpacity(0.5),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(Icons.reply, size: 16, color: theme.colorScheme.primary),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Text(
//                         'Membalas ${_replyingToComment!.user.displayName}',
//                         style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                     InkWell(onTap: _cancelReply, child: const Icon(Icons.close, size: 18))
//                   ],
//                 ),
//               ),
//             Row(
//               children: [
//                 const CircleAvatar(
//                   radius: 18,
//                   backgroundColor: Colors.grey,
//                   child: Icon(Icons.person, color: Colors.white, size: 20),
//                   // Ganti dengan User Avatar saat ini jika ada
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: TextField(
//                     focusNode: _focusNode,
//                     controller: _commentController,
//                     enabled: !_isSending, // Disable saat loading
//                     decoration: InputDecoration(
//                       hintText: _replyingToComment != null ? 'Tulis balasan...' : 'Tulis komentar...',
//                       filled: true,
//                       fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
//                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(24.0), borderSide: BorderSide.none),
//                       contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
//                       isDense: true,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 _isSending
//                     ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
//                     : IconButton(
//                   icon: Icon(Icons.send_rounded, color: theme.colorScheme.primary),
//                   onPressed: _sendComment,
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class _CommentTile extends StatelessWidget {
//   final Comment comment;
//   final String timeAgo;
//   final VoidCallback onTap;
//   final bool isReply;
//
//   const _CommentTile({
//     required this.comment,
//     required this.timeAgo,
//     required this.onTap,
//     this.isReply = false,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 8.0),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             CircleAvatar(
//               radius: isReply ? 14 : 18, // Balasan avatarnya lebih kecil
//               backgroundImage: comment.user.avatarUrl != null
//                   ? NetworkImage("http://192.168.1.10:5000${comment.user.avatarUrl}") // Sesuaikan Base URL
//                   : null,
//               child: comment.user.avatarUrl == null ? const Icon(Icons.person, size: 16) : null,
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Text(comment.user.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
//                       const SizedBox(width: 6),
//                       Text(timeAgo, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
//                     ],
//                   ),
//                   const SizedBox(height: 2),
//                   Text(comment.text, style: const TextStyle(fontSize: 14, height: 1.4)),
//                   const SizedBox(height: 4),
//                   Text("Balas", style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
//                 ],
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }