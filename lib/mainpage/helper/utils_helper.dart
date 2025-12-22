import 'package:flutter/material.dart';

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
