import 'package:flutter/material.dart';
import '../navigation/main_navigator.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  /*
  =============================================================================
  ANALISIS WHITE-BOX TESTING: FUNGSI _handleRegister
  -----------------------------------------------------------------------------
  Teknik: Branch Coverage
  Tujuan: Memastikan setiap jalur validasi dan alur logika dalam fungsi _handleRegister
          dieksekusi setidaknya satu kali selama pengujian.

  Fungsi ini memiliki 6 cabang keputusan utama:
  1. [Branch 1]: Pengecekan field kosong (nama, email, password).
  2. [Branch 2]: Pengecekan format email menggunakan regular expression.
  3. [Branch 3]: Pengecekan panjang minimum password.
  4. [Branch 4]: Pengecekan kesamaan antara password dan konfirmasi password.
  5. [Branch 5]: Jalur sukses, di mana semua validasi lolos dan proses registrasi
                 (async) dimulai.
  6. [Branch 6]: Pengecekan 'if (mounted)' setelah proses async, untuk navigasi yang aman.

  Kasus Uji untuk Mencapai 100% Branch Coverage:
  1. Input: Biarkan field 'Nama Lengkap' kosong, lalu tekan "Daftar".
     -> Hasil: Mengeksekusi Branch 1. Menampilkan snackbar "Semua field wajib diisi.".
  2. Input: Isi semua field, tetapi gunakan email "test.com" (tidak valid).
     -> Hasil: Mengeksekusi Branch 2. Menampilkan snackbar "Format email tidak valid.".
  3. Input: Isi semua field dengan benar, tetapi password diisi "pass123" (kurang dari 8).
     -> Hasil: Mengeksekusi Branch 3. Menampilkan snackbar "Password minimal harus 8 karakter.".
  4. Input: Isi semua field, password="Password1234", konfirmasi="PasswordBeda".
     -> Hasil: Mengeksekusi Branch 4. Menampilkan snackbar "Konfirmasi password tidak cocok.".
  5. Input: Isi semua field dengan data yang valid.
     -> Hasil: Mengeksekusi Branch 5 dan 6. Menampilkan loading, lalu navigasi ke MainNavigator.
  =============================================================================
  */
  void _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // [Branch 1]: Pengecekan field kosong
    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showErrorSnackbar('Semua field wajib diisi.');
      return;
    }

    // [Branch 2]: Validasi format email
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      _showErrorSnackbar('Format email tidak valid.');
      return;
    }

    // [Branch 3]: Validasi panjang password
    if (password.length < 8) {
      _showErrorSnackbar('Password minimal harus 8 karakter.');
      return;
    }

    // [Branch 4]: Validasi konfirmasi password
    if (password != confirmPassword) {
      _showErrorSnackbar('Konfirmasi password tidak cocok.');
      return;
    }

    // [Branch 5]: Semua validasi lolos, lanjutkan proses
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));

    // [Branch 6]: Pengecekan 'mounted' untuk navigasi aman
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainNavigator()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Buat Akun Baru'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Satu Langkah Lagi",
                      textAlign: TextAlign.center,
                      style:
                      TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Isi data di bawah ini untuk bergabung dengan komunitas kami.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 40),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            setState(
                                    () => _isPasswordVisible = !_isPasswordVisible);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: !_isConfirmPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            setState(() => _isConfirmPasswordVisible =
                            !_isConfirmPasswordVisible);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: const Text(
                        "Daftar",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Sudah punya akun?"),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'Masuk di sini',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withAlpha(128),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}