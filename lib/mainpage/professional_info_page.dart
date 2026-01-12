import 'package:flutter/material.dart';
import '../models/user_profile_model.dart';
import 'widgets/verified_badge.dart';

class ProfessionalInfoPage extends StatelessWidget {
  final UserProfileData profile;

  const ProfessionalInfoPage({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Informasi Profesional")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Center(child: VerifiedBadge(size: 60)),
            const SizedBox(height: 16),
            Text(
              "Psikolog Terverifikasi",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Akun ini telah melewati proses verifikasi identitas dan lisensi praktik resmi.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            _buildInfoCard(
              theme,
              "Detail Lisensi",
              [
                _buildInfoRow("Nama Lengkap", profile.fullNameWithTitle ?? "-"),
                _buildInfoRow("Nomor STRPK", profile.strNumber ?? "-"),
                _buildInfoRow("Wilayah", profile.province ?? "-"),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              theme,
              "Lokasi & Jadwal Praktik",
              [
                _buildInfoRow("Alamat", profile.practiceAddress ?? "-"),
                _buildInfoRow("Jadwal", profile.practiceSchedule ?? "-"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}