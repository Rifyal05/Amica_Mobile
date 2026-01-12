import 'package:flutter/material.dart';
import '../services/sdq_service.dart';
import '../models/sdq_model.dart';

class SdqProvider with ChangeNotifier {
  final SdqService _service = SdqService();

  List<SdqHistoryItem> _history = [];
  bool _isLoading = false;

  List<SdqHistoryItem> get history => _history;
  bool get isLoading => _isLoading;

  Future<void> fetchHistory() async {
    _isLoading = true;
    notifyListeners();
    try {
      _history = await _service.getHistory();
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<SdqFullResult?> submitQuiz(List<int> answers) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _service.submitAnswers(answers);
      await fetchHistory();
      return result;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<SdqFullResult?> fetchResultDetail(int id) async {
    try {
      final result = await _service.getResultDetail(id);
      return result;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }
}
