import 'package:amica/login/login_page.dart';
import 'package:amica/mainpage/change_email_page.dart';
import 'package:amica/mainpage/change_password_page.dart';
import 'package:amica/mainpage/feedback_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../provider/font_provider.dart';
import '../provider/theme_provider.dart';

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
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Keluar', style: TextStyle(color: Colors.redAccent)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                      (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final fontProvider = context.watch<FontProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = themeProvider.isDarkMode(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Akun'),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Ganti Email'),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const ChangeEmailPage(),
              ));
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Ganti Password'),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const ChangePasswordPage(),
              ));
            },
          ),
          const Divider(),
          _buildSectionHeader('Tampilan'),
          SwitchListTile(
            secondary: const Icon(Icons.brightness_6_outlined),
            title: const Text('Mode Gelap'),
            value: isDarkMode,
            onChanged: (value) {
              context.read<ThemeProvider>().toggleTheme();
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ukuran Font'),
                Slider(
                  value: fontProvider.fontScale,
                  min: 0.8,
                  max: 1.5,
                  divisions: 7,
                  label: '${(fontProvider.fontScale * 100).toStringAsFixed(0)}%',
                  onChanged: (double value) {
                    context.read<FontProvider>().setFontScale(value);
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          _buildSectionHeader('Lainnya'),
          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: const Text('Beri Masukan'),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const FeedbackPage(),
              ));
            },
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
            title: const Text('Keluar', style: TextStyle(color: Colors.redAccent)),
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