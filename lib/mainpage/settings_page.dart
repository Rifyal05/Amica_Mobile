import 'package:amica/login/login_page.dart';
import 'package:amica/mainpage/change_email_page.dart';
import 'package:amica/mainpage/change_password_page.dart';
import 'package:amica/mainpage/feedback_page.dart';
import 'package:amica/mainpage/blocked_user_page.dart';
import 'package:amica/mainpage/professional_registration_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import '../provider/chat_provider.dart';
import '../provider/font_provider.dart';
import '../provider/theme_provider.dart';
import '../provider/auth_provider.dart';
import 'moderation_list_page.dart';
import '../provider/moderation_provider.dart';
import '../services/custom_cache_manager.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Keluar'),
          content: const Text('Apakah Anda yakin ingin keluar dari akun Anda?'),
          actions: [
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text(
                'Keluar',
                style: TextStyle(color: Colors.redAccent),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                context.read<ChatProvider>().clearData();
                await context.read<AuthProvider>().performLogout();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (Route<dynamic> route) => false,
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _handlePinToggle(bool currentValue) {
    if (currentValue) {
      _showDisablePinDialog();
    } else {
      _showEnablePinDialog();
    }
  }

  void _showEnablePinDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buat PIN Baru'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Masukkan 6 digit PIN'),
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.length < 4) return;
              Navigator.pop(context);
              final err = await context.read<AuthProvider>().setPin(
                controller.text,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(err ?? 'PIN Berhasil diaktifkan')),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showDisablePinDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nonaktifkan PIN'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Masukkan PIN saat ini'),
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final err = await context.read<AuthProvider>().removePin(
                controller.text,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(err ?? 'PIN Berhasil dihapus')),
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearSystemCache() async {
    try {
      await PostCacheManager.instance.emptyCache();
      await ProfileCacheManager.instance.emptyCache();
      await DefaultCacheManager().emptyCache();

      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
        await tempDir.create();
      }

      final cacheDir = await getApplicationCacheDirectory();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create();
      }
    } catch (e) {
      debugPrint("Cache clear error: $e");
    }
  }

  void _showCacheClearConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Bersihkan Cache?"),
        content: const Text(
          "Ini akan menghapus semua gambar dan data sementara untuk mengosongkan ruang penyimpanan perangkat.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _clearSystemCache();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Penyimpanan berhasil dibersihkan!"),
                  ),
                );
              }
            },
            child: const Text("Bersihkan", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fontProvider = context.watch<FontProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();

    final isDarkMode = themeProvider.isDarkMode(context);
    final hasPin = authProvider.currentUser?.hasPin ?? false;
    final isVerified = authProvider.currentUser?.isVerified ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          _buildSectionHeader('Akun'),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Ganti Email'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ChangeEmailPage()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Ganti Password'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ChangePasswordPage(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Daftar Pengguna Diblokir'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const BlockedUsersPage()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.gpp_bad_outlined, color: Colors.orange),
            title: const Text('Status Moderasi Konten'),
            subtitle: const Text(
              'Lihat postingan yang ditolak atau sedang banding',
            ),
            trailing: Consumer<ModerationProvider>(
              builder: (context, mod, _) => mod.moderatedPosts.isNotEmpty
                  ? Badge(label: Text('${mod.moderatedPosts.length}'))
                  : const Icon(Icons.arrow_forward_ios, size: 14),
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ModerationListPage(),
              ),
            ),
          ),
          const Divider(),
          _buildSectionHeader('Profesional'),
          if (!isVerified)
            ListTile(
              leading: const Icon(Icons.verified_outlined, color: Colors.blue),
              title: const Text('Daftar sebagai Psikolog'),
              subtitle: const Text(
                'Verifikasi akun untuk lencana & fitur khusus',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfessionalRegistrationPage(),
                  ),
                );
              },
            )
          else
            ListTile(
              leading: const Icon(Icons.verified, color: Colors.blue),
              title: const Text('Status Akun: Terverifikasi'),
              subtitle: const Text(
                'Akun anda telah terverifikasi sebagai psikolog.',
              ),
              trailing: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 20,
              ),
            ),
          const Divider(),
          _buildSectionHeader('Keamanan'),
          SwitchListTile(
            secondary: const Icon(Icons.security),
            title: const Text('PIN Keamanan'),
            subtitle: Text(hasPin ? 'PIN Aktif' : 'PIN Tidak Aktif'),
            value: hasPin,
            onChanged: (_) => _handlePinToggle(hasPin),
          ),
          const Divider(),
          _buildSectionHeader('Tampilan'),
          SwitchListTile(
            secondary: const Icon(Icons.brightness_6_outlined),
            title: const Text('Mode Gelap'),
            value: isDarkMode,
            onChanged: (value) => context.read<ThemeProvider>().toggleTheme(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ukuran Font'),
                Slider(
                  value: fontProvider.fontScale,
                  min: 0.8,
                  max: 1.5,
                  divisions: 7,
                  label:
                      '${(fontProvider.fontScale * 100).toStringAsFixed(0)}%',
                  onChanged: (double value) =>
                      context.read<FontProvider>().setFontScale(value),
                ),
              ],
            ),
          ),
          const Divider(),
          _buildSectionHeader('Data & Cache'),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: const Text('Bersihkan Penyimpanan'),
            subtitle: const Text(
              'Hapus cache gambar dan data sementara aplikasi',
            ),
            onTap: _showCacheClearConfirmation,
          ),
          const Divider(),
          _buildSectionHeader('Lainnya'),
          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: const Text('Beri Masukan'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const FeedbackPage()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Tentang Kami'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.public),
            title: const Text('Situs Web Kami'),
            onTap: () => _launchURL('https://www.google.com'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Kebijakan Privasi'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              'Keluar',
              style: TextStyle(color: Colors.redAccent),
            ),
            onTap: _showLogoutConfirmation,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
