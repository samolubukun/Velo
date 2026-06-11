import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../viewmodels/describe_transaction_view_model.dart';
import '../../viewmodels/ledger_view_model.dart';
import '../../models/transaction_record.dart';
import '../../utils/number_formatter.dart';

class DescribeTransactionScreen extends StatefulWidget {
  const DescribeTransactionScreen({super.key});

  @override
  State<DescribeTransactionScreen> createState() => _DescribeTransactionScreenState();
}

class _DescribeTransactionScreenState extends State<DescribeTransactionScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.scaffold,
      appBar: AppBar(
        title: const Text('Describe Transaction'),
        backgroundColor: Colors.transparent,
      ),
      body: Consumer<DescribeTransactionViewModel>(
        builder: (context, vm, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!vm.hasResult && !vm.isAnalyzing)
                  _buildInputPrompt(context, colors, vm),
                if (vm.isAnalyzing) _buildAnalyzing(colors),
                if (vm.hasResult && vm.transactionRecord != null)
                  _buildResults(context, colors, vm, vm.transactionRecord!),
                if (vm.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              vm.errorMessage!,
                              style: const TextStyle(color: AppColors.error, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputPrompt(
      BuildContext context, AppColorSet colors, DescribeTransactionViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.brand.withValues(alpha: 0.2),
                  AppColors.brand.withValues(alpha: 0.05)
                ],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.edit_note_rounded, color: AppColors.brand, size: 30),
          ),
          const SizedBox(height: 20),
          Text('Describe a Transaction', style: AppTextStyles.heading2),
          const SizedBox(height: 8),
          Text(
            'Type what you spent or earned in plain language and Velo AI will parse it for you.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 12),
          // Quick templates
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              'Spent \$23 on fuel today',
              'Got paid \$2,500 salary',
              'Netflix subscription \$15.99',
              'Grocery run \$87 at Walmart',
            ].map((e) => GestureDetector(
              onTap: () {
                _controller.text = e;
                setState(() {});
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.brand.withValues(alpha: 0.3)),
                ),
                child: Text(e, style: AppTextStyles.bodySmall.copyWith(color: AppColors.brand)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'e.g. Bought groceries at Whole Foods for \$94.20 on Sunday...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: () => vm.analyze(_controller.text),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Parse Transaction'),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08);
  }

  Widget _buildAnalyzing(AppColorSet colors) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 48, height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(AppColors.brand.withValues(alpha: 0.8)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Parsing Transaction...', style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          Text('Extracting amount, merchant, and type from your description',
              style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildResults(
    BuildContext context,
    AppColorSet colors,
    DescribeTransactionViewModel vm,
    TransactionRecord tx,
  ) {
    final isExpense = tx.type == TransactionType.expense;
    final typeColor = isExpense ? AppColors.error : AppColors.success;
    final typeLabel = tx.type.name[0].toUpperCase() + tx.type.name.substring(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(typeLabel,
                        style: AppTextStyles.labelMedium.copyWith(color: typeColor)),
                  ),
                  const Spacer(),
                  Text(
                    '\$${NumberFormatter.formatDouble(tx.value.abs())}',
                    style: AppTextStyles.displaySmall.copyWith(
                      color: typeColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _resultRow(colors, Icons.store_outlined, 'Merchant', tx.title),
              const SizedBox(height: 10),
              _resultRow(colors, Icons.calendar_today_outlined, 'Date',
                  tx.date.toIso8601String().substring(0, 10)),
              if (tx.notes.isNotEmpty) ...[
                const SizedBox(height: 10),
                _resultRow(colors, Icons.notes_outlined, 'Notes', tx.notes),
              ],
            ],
          ),
        ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton.icon(
            onPressed: () async {
              await vm.saveTransaction();
              // Refresh ledger
              if (context.mounted) {
                context.read<LedgerViewModel>().refresh();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Transaction saved to ledger'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.save_alt_rounded),
            label: const Text('Save Transaction'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity, height: 52,
          child: OutlinedButton.icon(
            onPressed: () => vm.clearResults(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Parse Another'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.textPrimary,
              side: BorderSide(color: colors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _resultRow(AppColorSet colors, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colors.textSecondary),
        const SizedBox(width: 10),
        Text('$label: ', style: AppTextStyles.bodySmall.copyWith(color: colors.textSecondary)),
        Expanded(
          child: Text(value, style: AppTextStyles.bodyMedium, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
