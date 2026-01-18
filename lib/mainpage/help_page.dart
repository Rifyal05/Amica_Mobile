import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  Future<void> _contactEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'leafmoon.idn@gmail.com',
      queryParameters: {'subject': 'Bantuan Aplikasi Amica'},
    );
    if (!await launchUrl(emailLaunchUri)) {
      debugPrint('Could not launch email');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Pusat Bantuan")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // SEKSI KONTAK EMAIL (PALING ATAS)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                const Text(
                  "Butuh bantuan lebih lanjut?",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Hubungi tim dukungan kami melalui email:",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _contactEmail,
                  child: Text(
                    "leafmoon.idn@gmail.com",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          _buildHeader("Navigasi & Gestur"),
          _buildHelpTile(
            Icons.swipe_left,
            "Membuka Komentar",
            "Geser (swipe) ke kiri pada kartu postingan untuk membuka kolom komentar dengan cepat.",
          ),
          _buildHelpTile(
            Icons.swipe_right,
            "Buat Postingan",
            "Geser (swipe) ke kanan di halaman beranda untuk langsung masuk ke menu pembuatan postingan.",
          ),
          _buildHelpTile(
            Icons.refresh,
            "Refresh Konten",
            "Tarik layar ke bawah (pull to refresh) di halaman utama atau profil untuk memperbarui data terbaru.",
          ),
          _buildHelpTile(
            Icons.navigation,
            "Memunculkan Navigasi",
            "Jika tombol navigasi bawah hilang saat scroll, cukup scroll ke atas sedikit di halaman postingan untuk memunculkannya kembali.",
          ),

          const Divider(height: 32),
          _buildHeader("Profil & Koleksi"),
          _buildHelpTile(
            Icons.bookmark,
            "Privasi Koleksi Tersimpan",
            "Di halaman profil, jika tombol 'Koleksi Publik' dinyalakan, postingan yang Anda simpan bisa dilihat orang lain. Jika dimatikan, koleksi akan menjadi privat.",
          ),
          _buildHelpTile(
            Icons.tag,
            "Mencari Lewat Tag",
            "Tekan tag (tanda pagar) pada kartu postingan untuk mencari konten lain dengan topik serupa.",
          ),

          const Divider(height: 32),
          _buildHeader("Panduan & Edukasi"),
          _buildHelpTile(
            Icons.search,
            "Pencarian Artikel",
            "Untuk mencari materi edukasi, ketik kata kunci lalu pastikan Anda menekan tombol panah atau ikon 'Search' pada keyboard ponsel Anda.",
          ),

          const Divider(height: 32),
          _buildHeader("Pengaturan & Keamanan"),
          _buildHelpTile(
            Icons.settings,
            "Fitur Pengaturan",
            "Ganti Email, Password, mengatur PIN Keamanan, dan menghapus Cache (untuk melegakan memori HP) dapat dilakukan di menu Pengaturan.",
          ),
          _buildHelpTile(
            Icons.verified,
            "Verifikasi Profesional",
            "Psikolog dapat mengajukan verifikasi akun di menu Pengaturan untuk mendapatkan lencana verifikasi dan fitur khusus.",
          ),
          _buildHelpTile(
            Icons.gpp_maybe,
            "Status Moderasi & Banding",
            "Lihat postingan Anda yang ditahan di 'Status Moderasi'. Jika merasa postingan Anda tidak melanggar, Anda dapat mengajukan banding melalui menu tersebut.",
          ),
          _buildHelpTile(
            Icons.feedback,
            "Memberi Masukan",
            "Anda dapat memberikan saran atau kritik melalui menu 'Beri Masukan' di Pengaturan.",
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.blueAccent,
        ),
      ),
    );
  }

  Widget _buildHelpTile(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Colors.grey.shade600),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
