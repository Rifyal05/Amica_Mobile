import 'package:flutter/material.dart';
import '../../models/post_model.dart';

Future<String?> showReportReasonDialog(BuildContext context) async {
  final TextEditingController reasonController = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Laporkan Konten"),
      content: TextField(
        controller: reasonController,
        decoration: const InputDecoration(
          hintText: "Jelaskan alasan pelaporan...",
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text("Batal"),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, reasonController.text.trim()),
          child: const Text("Kirim"),
        ),
      ],
    ),
  );
}


enum DiscoverBlockType { duoSquare, landscape, tetris }

class DiscoverMosaicBlock {
  final DiscoverBlockType type;
  final List<Post> posts;
  DiscoverMosaicBlock({required this.type, required this.posts});
}

class DiscoverHelper {
  static List<DiscoverMosaicBlock> generateBlocks(List<Post> rawPosts) {
    List<DiscoverMosaicBlock> blocks = [];
    List<Post> pool = List.from(rawPosts);

    while (pool.isNotEmpty) {
      if (pool.length >= 3) {
        Post p1 = pool[0];
        if (p1.fullImageUrl != null) {
          blocks.add(DiscoverMosaicBlock(
            type: DiscoverBlockType.landscape,
            posts: [pool.removeAt(0)],
          ));
        } else {
          blocks.add(DiscoverMosaicBlock(
            type: DiscoverBlockType.tetris,
            posts: [pool.removeAt(0), pool.removeAt(0), pool.removeAt(0)],
          ));
        }
      } else if (pool.length == 2) {
        blocks.add(DiscoverMosaicBlock(
          type: DiscoverBlockType.duoSquare,
          posts: [pool.removeAt(0), pool.removeAt(0)],
        ));
      } else {
        blocks.add(DiscoverMosaicBlock(
          type: DiscoverBlockType.duoSquare,
          posts: [pool.removeAt(0)],
        ));
      }
    }
    return blocks;
  }
}
