import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/model_status.dart';
import '../../services/model_manager.dart';
import '../../services/local_db_service.dart';
import '../../models/user_profile.dart';
import '../../models/account.dart';
import '../../viewmodels/theme_view_model.dart';
import '../../services/biometric_service.dart';
import '../../utils/number_formatter.dart';
import 'model_download_screen.dart';
import 'tag_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Future<UserProfile?> _profileFuture;
  bool _pinEnabled = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = LocalDbService.instance.getProfile();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    final pin = await BiometricService.instance.isPinEnabled();
    final bio = await BiometricService.instance.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _pinEnabled = pin;
        _biometricEnabled = bio;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.scaffold,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<UserProfile?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          final profile = snapshot.data;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              _sectionHeader(colors, 'Profile'),
              const SizedBox(height: 12),
              _profileCard(context, colors, profile),
              const SizedBox(height: 28),
              _sectionHeader(colors, 'AI Model'),
              const SizedBox(height: 12),
              Consumer<ModelManager>(
                builder: (context, mm, _) => _menuItem(context, colors,
                  icon: Icons.psychology,
                  label: 'Model Status',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: mm.isReady ? AppColors.success.withValues(alpha: 0.15) : AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      mm.isReady ? 'Ready' : mm.status == ModelStatus.notDownloaded ? 'Not Downloaded' : mm.status.name,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                          color: mm.isReady ? AppColors.success : AppColors.warning),
                    ),
                  ),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ModelDownloadSetupScreen())),
                ),
              ),
              const SizedBox(height: 28),
              _sectionHeader(colors, 'Preferences'),
              const SizedBox(height: 12),
              Consumer<ThemeViewModel>(
                builder: (context, themeVm, _) {
                  final isDark = themeVm.effectiveIsDark(MediaQuery.of(context).platformBrightness);
                  return _menuItem(context, colors,
                    icon: isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                    label: 'Dark Mode',
                    trailing: Switch(
                      value: isDark,
                      onChanged: (val) => themeVm.setDark(val),
                      activeThumbColor: AppColors.brand,
                    ),
                  );
                },
              ),
              _menuItem(context, colors,
                icon: Icons.lock_outline_rounded,
                label: 'Security Lock (PIN)',
                trailing: Switch(
                  value: _pinEnabled,
                  activeThumbColor: AppColors.brand,
                  onChanged: (v) async {
                    if (v) {
                      await _showPinSetupDialog(context);
                    } else {
                      await BiometricService.instance.disableSecurity();
                      await _loadSecuritySettings();
                    }
                  },
                ),
              ),
              if (_pinEnabled)
                _menuItem(context, colors,
                  icon: Icons.fingerprint_rounded,
                  label: 'Biometric Bypass',
                  trailing: Switch(
                    value: _biometricEnabled,
                    activeThumbColor: AppColors.brand,
                    onChanged: (v) async {
                      if (v) {
                        final canBio = await BiometricService.instance.canUseBiometrics();
                        if (!canBio) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Biometrics not available or set up on this device.'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: AppColors.error,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                          return;
                        }
                      }
                      await BiometricService.instance.setBiometricEnabled(v);
                      setState(() => _biometricEnabled = v);
                    },
                  ),
                ),
              const SizedBox(height: 28),
              _sectionHeader(colors, 'Data'),
              const SizedBox(height: 12),
              _menuItem(context, colors,
                icon: Icons.label_outline,
                label: 'Manage Tags',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TagManagementScreen())),
              ),
              _menuItem(context, colors,
                icon: Icons.download_outlined,
                label: 'Export Transactions (CSV)',
                onTap: () => _exportCsv(context),
              ),
              _menuItem(context, colors,
                icon: Icons.delete_outline,
                label: 'Clear All Data',
                iconColor: AppColors.error,
                onTap: () => _confirmClearData(context, colors),
              ),
              _menuItem(context, colors,
                icon: Icons.refresh,
                label: 'Reset Onboarding',
                onTap: () async {
                  await LocalDbService.instance.saveProfile(const UserProfile(name: ''));
                  try {
                    Provider.of<ModelManager>(context, listen: false).resetSkipSetup();
                  } catch (_) {}
                  Navigator.pushNamedAndRemoveUntil(context, '/onboarding', (_) => false);
                },
              ),
              const SizedBox(height: 28),
              _sectionHeader(colors, 'About'),
              const SizedBox(height: 12),
              _menuItem(context, colors,
                icon: Icons.info_outline,
                label: 'Version',
                trailing: Text('2.0.0', style: AppTextStyles.bodyMedium),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(AppColorSet colors, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(title,
        style: AppTextStyles.labelMedium.copyWith(color: colors.textTertiary, letterSpacing: 1)),
    );
  }

  Widget _profileCard(BuildContext context, AppColorSet colors, UserProfile? profile) {
    if (profile == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.border)),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: colors.surfaceAlt, borderRadius: BorderRadius.circular(14)),
              child: Icon(Icons.person, color: colors.textTertiary),
            ),
            const SizedBox(width: 16),
            Text('No profile', style: AppTextStyles.bodyMedium),
          ],
        ),
      );
    }
    return GestureDetector(
      onTap: () => _showEditProfileDialog(context, profile, colors),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.brandGradient),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(Icons.person, size: 28, color: colors.textOnBrand),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(profile.name, style: AppTextStyles.heading3)),
                      Icon(Icons.edit_outlined, size: 16, color: colors.textSecondary),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${profile.baseCurrency}  •  Goal: \$${NumberFormatter.formatDouble(profile.monthlySavingsGoal)}/mo',
                      style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(BuildContext context, AppColorSet colors, {
    required IconData icon,
    required String label,
    Widget? trailing,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? colors.textSecondary, size: 22),
        title: Text(label, style: AppTextStyles.bodyLarge),
        trailing: trailing ?? Icon(Icons.chevron_right, color: colors.textTertiary, size: 20),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: colors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context) async {
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
    }
  }

  void _confirmClearData(BuildContext context, AppColorSet colors) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: const Text('Clear All Data'),
        content: const Text('This will delete all your saved data including transactions, accounts, and profile. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<ModelManager>().clearModel();
              Navigator.pushNamedAndRemoveUntil(context, '/onboarding', (_) => false);
            },
            child: const Text('Clear', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, UserProfile profile, AppColorSet colors) {
    final nameCtrl = TextEditingController(text: profile.name);
    final goalCtrl = TextEditingController(text: profile.monthlySavingsGoal.toStringAsFixed(0));
    String selectedCurrency = profile.baseCurrency;
    final currencies = ['USD', 'EUR', 'GBP', 'TRY', 'NGN', 'CAD', 'AUD'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          scrollable: true,
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: goalCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monthly Savings Goal',
                  prefixIcon: Icon(Icons.savings_outlined),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCurrency,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Base Currency',
                  prefixIcon: Icon(Icons.currency_exchange),
                ),
                items: currencies
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedCurrency = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final goal = NumberFormatter.parseAmount(goalCtrl.text);
                if (name.isEmpty) return;

                final updated = UserProfile(
                  name: name,
                  baseCurrency: selectedCurrency,
                  monthlySavingsGoal: goal,
                );

                await LocalDbService.instance.saveProfile(updated);

                // Update all accounts to sync with the new global currency
                final accounts = await LocalDbService.instance.getAccounts();
                for (final acc in accounts) {
                  await LocalDbService.instance.saveAccount(acc.copyWith(currency: selectedCurrency));
                }

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  setState(() {
                    _profileFuture = LocalDbService.instance.getProfile();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Profile updated ✓'),
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPinSetupDialog(BuildContext context) async {
    final colors = AppColors.of(context);
    final pinCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? errorText;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          scrollable: true,
          backgroundColor: colors.surface,
          title: const Text('Setup App PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Set a 4-digit PIN to lock Velo. You can optionally enable biometric unlock later.',
                style: AppTextStyles.bodyMedium.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pinCtrl,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                style: TextStyle(color: colors.textPrimary, letterSpacing: 8, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Enter 4-digit PIN',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmCtrl,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                style: TextStyle(color: colors.textPrimary, letterSpacing: 8, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Confirm 4-digit PIN',
                  counterText: '',
                ),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 12),
                Text(
                  errorText!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ]
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _loadSecuritySettings();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final pin = pinCtrl.text;
                final confirm = confirmCtrl.text;
                if (pin.length != 4) {
                  setDialogState(() {
                    errorText = 'PIN must be 4 digits';
                  });
                  return;
                }
                if (pin != confirm) {
                  setDialogState(() {
                    errorText = 'PINs do not match';
                  });
                  return;
                }

                await BiometricService.instance.setPinCode(pin);
                if (ctx.mounted) Navigator.pop(ctx);
                await _loadSecuritySettings();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('PIN code security enabled successfully!'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }
}
