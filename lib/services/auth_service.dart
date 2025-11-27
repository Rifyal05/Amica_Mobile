
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String baseUrl = 'http://10.0.2.2:5000/api/auth';

  Map<String, String> _getBaseHeaders() {
    return {'Content-Type': 'application/json'};
  }
  Future<Map<String, dynamic>> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 2));
    if (email == 'fail@test.com') {
      return {'success': false, 'message': 'Email atau password salah.'};
    }

    return {'success': true, 'token': 'mock_token', 'user': {'username': 'test'}};
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<String?> sendPasswordResetCode(String email) async {
    await Future.delayed(const Duration(seconds: 1));
    if (email.contains('error')) return 'Email tidak terdaftar. Coba email lain.';

    return null;
  }

  Future<String?> verifyResetCodeAndSetPassword(String email, String code, String newPassword) async {
    await Future.delayed(const Duration(seconds: 1));

    if (code != '123456') return 'Kode verifikasi salah atau sudah kadaluarsa.';

    return null;
  }
}