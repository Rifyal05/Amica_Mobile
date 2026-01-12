import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/bot_service.dart';
import '../models/bot_model.dart';

class BotProvider with ChangeNotifier {
  final BotService _service = BotService();

  final List<BotMessageModel> _messages = [];
  bool _isTyping = false;
  String _currentStreamBuffer = "";
  String _statusMessage = "";

  List<BotMessageModel> get messages => _messages;
  bool get isTyping => _isTyping;
  String get currentStreamBuffer => _currentStreamBuffer;
  String get statusMessage => _statusMessage;

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  Future<void> sendMessage(String text, String token) async {
    if (text.isEmpty) return;

    _messages.add(BotMessageModel(role: 'user', content: text));
    _isTyping = true;
    _currentStreamBuffer = "";
    _statusMessage = "Menghubungkan...";
    notifyListeners();

    try {
      String history = "";
      if (_messages.length > 2) {
        final lastBotMsg = _messages.lastWhere(
          (m) => m.role == 'bot',
          orElse: () => BotMessageModel(role: 'bot', content: ''),
        );
        history = lastBotMsg.content;
      }

      final response = await _service.streamChat(text, history, token);

      response.stream
          .transform(utf8.decoder)
          .listen(
            (value) {
              if (value.contains("[STATUS:")) {
                _statusMessage = value
                    .replaceAll(RegExp(r'\[STATUS:.*?\]'), '')
                    .trim();
                if (_statusMessage.isEmpty) {
                  _statusMessage = "Sedang berpikir...";
                }
              } else if (value.contains("[HEARTBEAT]")) {
                // Ignore
              } else {
                _statusMessage = "";
                _currentStreamBuffer += value;
              }
              notifyListeners();
            },
            onDone: () {
              _isTyping = false;
              if (_currentStreamBuffer.isNotEmpty) {
                _messages.add(
                  BotMessageModel(role: 'bot', content: _currentStreamBuffer),
                );
              }
              _currentStreamBuffer = "";
              notifyListeners();
            },
            onError: (error) {
              _isTyping = false;
              _messages.add(
                BotMessageModel(
                  role: 'bot',
                  content: "Maaf, koneksi terputus.",
                ),
              );
              notifyListeners();
            },
          );
    } catch (e) {
      _isTyping = false;
      _messages.add(
        BotMessageModel(role: 'bot', content: "Gagal mengirim pesan."),
      );
      notifyListeners();
    }
  }
}
