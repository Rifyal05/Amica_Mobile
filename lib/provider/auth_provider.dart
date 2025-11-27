import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;

  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    _isLoggedIn = token != null;
    notifyListeners();
  }

  Future<String?> attemptLogin(String email, String password) async {
    final result = await _authService.login(email, password);

    if (result['success']) {
      _isLoggedIn = true;
      notifyListeners();
      return null;
    } else {
      return result['message'];
    }
  }

  Future<void> performLogout() async {
    await _authService.logout();
    _isLoggedIn = false;
    notifyListeners();
  }
}