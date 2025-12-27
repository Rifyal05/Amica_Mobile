import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';
import '../navigation/main_navigator.dart';

class VerifyPinPage extends StatefulWidget {
  final String tempId;
  final String email;

  const VerifyPinPage({super.key, required this.tempId, required this.email});

  @override
  State<VerifyPinPage> createState() => _VerifyPinPageState();
}

class _VerifyPinPageState extends State<VerifyPinPage> {
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  void _verifyPin() async {
    String pin = _pinController.text;
    if (pin.length < 4) {
      setState(() => _errorMessage = 'PIN minimal 4 digit');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final error = await context.read<AuthProvider>().verifyPinLogin(
      widget.tempId,
      pin,
    );

    if (error == null) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainNavigator()),
        (route) => false,
      );
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = error;
          _pinController.clear();
        });
      }
    }
  }

  void _showForgotPinDialog() {
    final emailController = TextEditingController(text: widget.email);
    final otpController = TextEditingController();
    final newPinController = TextEditingController();
    int step = 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Lupa PIN'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (step == 1) ...[
                    const Text('Kode OTP akan dikirim ke email Anda.'),
                    const SizedBox(height: 10),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      enabled: false,
                    ),
                  ],
                  if (step == 2) ...[
                    const Text('Masukkan kode OTP dan PIN baru.'),
                    const SizedBox(height: 10),
                    TextField(
                      controller: otpController,
                      decoration: const InputDecoration(
                        labelText: 'Kode OTP',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: newPinController,
                      decoration: const InputDecoration(
                        labelText: 'PIN Baru (Opsional)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                    ),
                    const Text(
                      'Biarkan kosong jika ingin menghapus PIN.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              if (step == 1)
                TextButton(
                  onPressed: () async {
                    final prov = context.read<AuthProvider>();
                    final err = await prov.sendResetCode(emailController.text);
                    if (err == null) {
                      setDialogState(() => step = 2);
                    } else {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(err)));
                    }
                  },
                  child: const Text('Kirim OTP'),
                ),
              if (step == 2)
                TextButton(
                  onPressed: () async {
                    final prov = context.read<AuthProvider>();
                    final newPin = newPinController.text.isNotEmpty
                        ? newPinController.text
                        : null;
                    final err = await prov.resetPinByOtp(
                      emailController.text,
                      otpController.text,
                      newPin,
                    );

                    if (err == null) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'PIN berhasil direset, silakan login ulang.',
                          ),
                        ),
                      );
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(err)));
                    }
                  },
                  child: const Text('Reset PIN'),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verifikasi PIN')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 20),
            const Text(
              'Masukkan PIN Keamanan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              maxLength: 6,
              decoration: InputDecoration(
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _verifyPin,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Masuk'),
                    ),
                  ),
            TextButton(
              onPressed: _showForgotPinDialog,
              child: const Text("Lupa PIN?"),
            ),
          ],
        ),
      ),
    );
  }
}
