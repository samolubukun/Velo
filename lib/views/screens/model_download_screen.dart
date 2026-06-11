import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/model_status.dart';
import '../../services/model_manager.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class ModelDownloadSetupScreen extends StatelessWidget {
  const ModelDownloadSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.scaffold,
      body: SafeArea(
        child: Consumer<ModelManager>(
          builder: (context, mm, _) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  _buildHeader(),
                  const SizedBox(height: 48),
                  _buildModelCard(colors, mm),
                  const SizedBox(height: 24),
                  if (mm.isDownloading) _buildProgress(colors, mm),
                  if (mm.status == ModelStatus.error) _buildError(mm),
                  const Spacer(),
                  _buildActionButton(context, colors, mm),
                  if (mm.status != ModelStatus.ready && !mm.isDownloading) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        mm.skipSetup();
                        Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
                      },
                      child: Text(
                        'Skip Setup (Use Non-AI Features)',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: colors.textSecondary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.brandGradient),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: AppColors.brand.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 8))],
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.black87, size: 36),
        ),
        const SizedBox(height: 24),
        Text('AI Setup', style: AppTextStyles.displayMedium),
        const SizedBox(height: 8),
        Text(
          'Download the AI model to enable offline\nfinancial analysis and receipt parsing.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildModelCard(AppColorSet colors, ModelManager mm) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.psychology, color: AppColors.brand, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mm.modelInfo.name, style: AppTextStyles.heading3),
                const SizedBox(height: 4),
                Text(mm.modelInfo.sizeFormatted, style: AppTextStyles.bodySmall),
                if (mm.status == ModelStatus.ready)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 14, color: AppColors.success),
                        SizedBox(width: 4),
                        Text('Ready to use', style: TextStyle(fontSize: 12, color: AppColors.success)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(AppColorSet colors, ModelManager mm) {
    final p = mm.downloadProgress;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: p.percentage / 100, minHeight: 6,
            backgroundColor: colors.surfaceAlt,
            valueColor: const AlwaysStoppedAnimation(AppColors.brand),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${p.percentage.toStringAsFixed(1)}%  •  ${_fmt(p.bytesDownloaded)} / ${_fmt(p.totalBytes)}',
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }

  Widget _buildError(ModelManager mm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(mm.errorMessage ?? 'Error', style: const TextStyle(color: AppColors.error, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, AppColorSet colors, ModelManager mm) {
    String label;
    VoidCallback? onTap;
    bool loading = false;

    switch (mm.status) {
      case ModelStatus.notDownloaded:
        label = 'Download Model';
        onTap = () => mm.downloadModel();
        break;
      case ModelStatus.downloading:
        label = 'Downloading...';
        loading = true;
        break;
      case ModelStatus.downloadComplete:
      case ModelStatus.initializing:
        label = 'Initializing...';
        loading = true;
        break;
      case ModelStatus.ready:
        label = 'Continue';
        onTap = () => Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
        break;
      case ModelStatus.error:
        label = 'Retry Download';
        onTap = () { mm.clearError(); mm.downloadModel(); };
        break;
    }

    return SizedBox(
      width: double.infinity, height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: mm.status == ModelStatus.ready ? AppColors.brand : colors.cardElevated,
          foregroundColor: mm.status == ModelStatus.ready ? colors.textOnBrand : colors.textPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: loading
            ? SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: colors.textPrimary),
              )
            : Text(label, style: AppTextStyles.buttonLarge),
      ),
    );
  }

  String _fmt(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }
}
