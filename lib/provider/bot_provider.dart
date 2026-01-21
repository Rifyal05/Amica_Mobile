import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_config.dart';

class BotMessageModel {
  final String? id;
  final String role;
  final String content;

  BotMessageModel({this.id, required this.role, required this.content});
}

class ChatSession {
  final String id;
  final String title;
  final String updatedAt;

  ChatSession({required this.id, required this.title, required this.updatedAt});

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      title: json['title'],
      updatedAt: json['updated_at'],
    );
  }
}

class BotProvider with ChangeNotifier {
  final List<BotMessageModel> _messages = [];
  final List<ChatSession> _sessions = [];

  bool _isTyping = false;
  String _currentStreamBuffer = "";
  String _statusMessage = "";
  String? _currentSessionId;
  StreamSubscription? _streamSubscription;

  List<BotMessageModel> get messages => _messages;
  List<ChatSession> get sessions => _sessions;
  bool get isTyping => _isTyping;
  String get currentStreamBuffer => _currentStreamBuffer;
  String get statusMessage => _statusMessage;
  String? get currentSessionId => _currentSessionId;

  Future<void> fetchSessions(String token) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/bot/sessions');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        _sessions.clear();
        _sessions.addAll(data.map((e) => ChatSession.fromJson(e)).toList());
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching sessions: $e");
    }
  }

  Future<void> loadSessionHistory(String sessionId, String token) async {
    try {
      stopGeneration();
      _currentSessionId = sessionId;
      _messages.clear();
      notifyListeners();

      final url = Uri.parse('${ApiConfig.baseUrl}/api/bot/history/$sessionId');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        _messages.addAll(
          data
              .map(
                (e) => BotMessageModel(
                  id: e['id'],
                  role: e['role'],
                  content: e['text'],
                ),
              )
              .toList(),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading history: $e");
    }
  }

  Future<void> deleteSession(String sessionId, String token) async {
    try {
      if (_currentSessionId == sessionId) startNewSession();
      _sessions.removeWhere((s) => s.id == sessionId);
      notifyListeners();
      await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/bot/sessions/$sessionId'),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      fetchSessions(token);
    }
  }

  void startNewSession() {
    _currentSessionId = null;
    _messages.clear();
    stopGeneration();
    notifyListeners();
  }

  void stopGeneration() {
    if (_streamSubscription != null) {
      _streamSubscription?.cancel();
      _streamSubscription = null;
    }

    _isTyping = false;
    _statusMessage = "Dihentikan oleh pengguna.";

    if (_currentStreamBuffer.isNotEmpty) {
      _messages.add(
        BotMessageModel(role: 'bot', content: _currentStreamBuffer),
      );
    }
    _currentStreamBuffer = "";
    notifyListeners();
  }

  Future<void> deleteMessage(String messageId, String token) async {
    _messages.removeWhere((m) => m.id == messageId);
    notifyListeners();
    try {
      await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/bot/messages/$messageId'),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      debugPrint("Error deleting message: $e");
    }
  }

  Future<void> regenerateLastResponse(String token) async {
    if (_messages.isEmpty) return;

    if (_messages.last.role == 'model' || _messages.last.role == 'bot') {
      final lastBotId = _messages.last.id;
      _messages.removeLast();
      notifyListeners();

      if (lastBotId != null) {
        http.delete(
          Uri.parse('${ApiConfig.baseUrl}/api/bot/messages/$lastBotId'),
          headers: {'Authorization': 'Bearer $token'},
        );
      }
    }

    if (_messages.isNotEmpty && _messages.last.role == 'user') {
      final lastUserText = _messages.last.content;
      final lastUserId = _messages.last.id;

      if (lastUserId != null) {
        _messages.removeLast();
        notifyListeners();
        http.delete(
          Uri.parse('${ApiConfig.baseUrl}/api/bot/messages/$lastUserId'),
          headers: {'Authorization': 'Bearer $token'},
        );
      } else {
        _messages.removeLast();
      }

      sendMessage(lastUserText, token);
    }
  }

  Future<void> editMessage(
    String messageId,
    String newText,
    String token,
  ) async {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;

    await deleteMessage(messageId, token);

    if (index < _messages.length &&
        (_messages[index].role == 'model' || _messages[index].role == 'bot')) {
      final botMsgId = _messages[index].id;
      if (botMsgId != null) {
        await deleteMessage(botMsgId, token);
      } else {
        _messages.removeAt(index);
        notifyListeners();
      }
    }

    sendMessage(newText, token);
  }

  Future<void> sendMessage(String text, String token) async {
    if (text.isEmpty) return;

    _messages.add(BotMessageModel(role: 'user', content: text));
    _isTyping = true;
    _currentStreamBuffer = "";
    _statusMessage = "Menghubungkan...";
    notifyListeners();

    bool isNewSession = _currentSessionId == null;

    try {
      final request = http.Request(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/api/bot/send'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        "message": text,
        "session_id": _currentSessionId,
      });

      final response = await request.send();

      if (response.statusCode != 200) {
        final bodyString = await response.stream.bytesToString();
        String errorMessage = "Terjadi kesalahan pada server.";

        if (response.statusCode == 429) {
          try {
            final jsonError = jsonDecode(bodyString);
            final retryInfo = jsonError['retry_after'] ?? 'beberapa saat';
            errorMessage =
                "⏳ Limit Tercapai ($retryInfo).\n\nMohon tunggu sebelum mengirim pesan lagi.";
          } catch (_) {
            errorMessage =
                "⏳ Terlalu banyak permintaan. Mohon tunggu sebentar.";
          }
        } else {
          try {
            final jsonError = jsonDecode(bodyString);
            errorMessage =
                "⚠️ ${jsonError['error'] ?? 'Gagal memproses pesan.'}";
          } catch (_) {}
        }

        _messages.add(BotMessageModel(role: 'bot', content: errorMessage));
        _isTyping = false;
        _statusMessage = "";
        notifyListeners();
        return;
      }

      _streamSubscription = response.stream
          .transform(utf8.decoder)
          .listen(
            (value) {
              if (value.contains('"type": "meta"')) {
                final sessionRegex = RegExp(r'"session_id":\s*"([^"]+)"');
                final msgRegex = RegExp(r'"user_message_id":\s*"([^"]+)"');

                final sessionMatch = sessionRegex.firstMatch(value);
                final msgMatch = msgRegex.firstMatch(value);

                if (sessionMatch != null) {
                  _currentSessionId = sessionMatch.group(1);
                }

                if (msgMatch != null &&
                    _messages.isNotEmpty &&
                    _messages.last.role == 'user') {
                  final updatedMsg = BotMessageModel(
                    id: msgMatch.group(1),
                    role: _messages.last.role,
                    content: _messages.last.content,
                  );
                  _messages.removeLast();
                  _messages.add(updatedMsg);
                }
                value = value.replaceAll(
                  RegExp(r'\{.*"type": "meta".*\}\n?'),
                  '',
                );
              }

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
              _streamSubscription = null;

              if (isNewSession) {
                fetchSessions(token);
              }
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
              _streamSubscription = null;
              notifyListeners();
            },
          );
    } catch (e) {
      _isTyping = false;
      _messages.add(
        BotMessageModel(
          role: 'bot',
          content: "Gagal mengirim pesan (Koneksi Error).",
        ),
      );
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}
