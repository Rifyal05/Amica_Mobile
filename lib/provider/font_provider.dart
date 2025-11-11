import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontProvider with ChangeNotifier {
  static const String _fontScaleKey = 'fontScale';

  double _fontScale;
  double get fontScale => _fontScale;

  FontProvider(this._fontScale);

  Future<void> setFontScale(double newScale) async {
    if (_fontScale == newScale) return;

    _fontScale = newScale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontScaleKey, newScale);
  }
}