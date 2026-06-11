import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../viewmodels/theme_view_model.dart';
import '../../services/local_db_service.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final themeVm = context.watch<ThemeViewModel>();

    return Scaffold(
      backgroundColor: colors.scaffold,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [

          // ── Theme ─────────────────────────────────────────────────────
          _SectionHeader(label: 'Appearance', colors: colors),
          _SettingTile(
            colors: colors,
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            trailing: Switch(
              value: themeVm.themeMode == ThemeMode.dark,
              activeThumbColor: AppColors.brand,
              onChanged: (_) => themeVm.toggleTheme(),
            ),
          ),

          const SizedBox(height: 8),

          // ── Data ──────────────────────────────────────────────────────
          _SectionHeader(label: 'Data & Privacy', colors: colors),
          _SettingTile(
            colors: colors,
            icon: Icons.download_outlined,
            title: 'Export Transactions (CSV)',
            subtitle: 'Save all transactions to a CSV file on your device',
            trailing: _isExporting
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brand))
                : Icon(Icons.chevron_right, color: colors.textTertiary),
            onTap: _isExporting ? null : () => _exportCsv(context),
          ),
          _SettingTile(
            colors: colors,
            icon: Icons.security_outlined,
            title: 'Privacy Mode',
            subtitle: 'Double-tap the balance card on Dashboard to toggle',
            trailing: Icon(Icons.chevron_right, color: colors.textTertiary),
          ),

          const SizedBox(height: 8),

          // ── About ─────────────────────────────────────────────────────
          _SectionHeader(label: 'About', colors: colors),
          _SettingTile(
            colors: colors,
            icon: Icons.account_balance_wallet_outlined,
            title: 'Velo',
            subtitle: 'Offline AI Finance Controller — v2.0.0',
            trailing: const SizedBox.shrink(),
          ),
          _SettingTile(
            colors: colors,
            icon: Icons.lock_outline,
            title: 'Privacy-First',
            subtitle: 'All data stays on your device. Zero cloud calls.',
            trailing: const SizedBox.shrink(),
          ),
          _SettingTile(
            colors: colors,
            icon: Icons.smart_toy_outlined,
            title: 'AI Engine',
            subtitle: 'Powered by Gemma 4 on-device inference',
            trailing: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context) async {
    setState(() => _isExporting = true);
    try {
      final csv = await LocalDbService.instance.exportTransactionsToCsv();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/velo_transactions_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Exported to ${file.path}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Export failed: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final AppColorSet colors;
  const _SectionHeader({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
      child: Text(label.toUpperCase(),
          style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.brand, letterSpacing: 1.2, fontSize: 11)),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final AppColorSet colors;
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.colors,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.brand, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelMedium),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: colors.textSecondary),
                        maxLines: 2),
                  ],
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
