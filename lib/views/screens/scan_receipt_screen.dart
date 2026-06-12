import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../viewmodels/scan_receipt_view_model.dart';
import '../../viewmodels/ledger_view_model.dart';
import '../../models/transaction_record.dart';
import '../../services/local_db_service.dart';
import '../widgets/capture_prompt_card.dart';
import '../../utils/number_formatter.dart';

class ScanReceiptScreen extends StatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  bool _pdfMode = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Import', style: AppTextStyles.heading1),
                        Text('Scan or upload financial documents',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: colors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Mode Toggle ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.border, width: 0.5),
                ),
                child: Row(
                  children: [
                    _ModeTab(
                      label: 'Receipt',
                      icon: Icons.receipt_long_outlined,
                      selected: !_pdfMode,
                      onTap: () {
                        setState(() => _pdfMode = false);
                        context.read<ScanReceiptViewModel>().toggleMode(false);
                      },
                      colors: colors,
                    ),
                    _ModeTab(
                      label: 'Bank Statement',
                      icon: Icons.picture_as_pdf_outlined,
                      selected: _pdfMode,
                      onTap: () {
                        setState(() => _pdfMode = true);
                        context.read<ScanReceiptViewModel>().toggleMode(true);
                      },
                      colors: colors,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Body ─────────────────────────────────────────────────────
            Expanded(
              child: Consumer<ScanReceiptViewModel>(
                builder: (context, vm, _) {
                  if (vm.isAnalyzing) return _buildLoading(colors);
                  if (vm.errorMessage != null) return _buildError(vm, colors);

                  if (_pdfMode) {
                    if (vm.parsedTransactions.isNotEmpty) {
                      return _BulkResultView(vm: vm, colors: colors);
                    }
                    return _buildPdfPrompt(context, vm, colors);
                  } else {
                    if (vm.parsedTransaction != null) {
                      return _SingleResultView(vm: vm, colors: colors);
                    }
                    return _buildReceiptPrompt(context, vm, colors);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptPrompt(
      BuildContext context, ScanReceiptViewModel vm, AppColorSet colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: CapturePromptCard(
        title: 'Scan a Receipt',
        subtitle:
            'Take a photo or select a receipt image. Velo AI will extract merchant, amount, and date automatically.',
        icon: Icons.receipt_long_rounded,
        accentColor: AppColors.brand,
        primaryLabel: 'Take Photo',
        secondaryLabel: 'Choose from Gallery',
        onPrimary: () async {
          await vm.takePhoto();
          if (vm.hasImage) await vm.analyzeImage();
        },
        onSecondary: () async {
          await vm.pickImage();
          if (vm.hasImage) await vm.analyzeImage();
        },
      ),
    );
  }

  Widget _buildPdfPrompt(
      BuildContext context, ScanReceiptViewModel vm, AppColorSet colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: CapturePromptCard(
        title: 'Import Bank Statement',
        subtitle:
            'Select a PDF bank statement. Velo AI will extract all transactions offline and let you review before saving.',
        icon: Icons.picture_as_pdf_rounded,
        accentColor: AppColors.accent,
        primaryLabel: 'Select PDF File',
        secondaryLabel: 'What formats are supported?',
        onPrimary: () async {
          final result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf'],
          );
          if (result != null && result.files.single.path != null) {
            await vm.selectPdf(result.files.single.path!);
          }
        },
        onSecondary: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Supported Formats'),
              content: const Text(
                  'Text-based PDF bank statements are supported.\n\nScanned PDFs (image-only) are not supported — use the Receipt scanner instead.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Got it')),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoading(AppColorSet colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 56, height: 56,
            child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(
                    AppColors.brand.withValues(alpha: 0.85))),
          ),
          const SizedBox(height: 20),
          Text('Analyzing...', style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          Text(_pdfMode ? 'Extracting transactions from PDF' : 'Parsing receipt with Gemma AI',
              style: AppTextStyles.bodySmall.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  Widget _buildError(ScanReceiptViewModel vm, AppColorSet colors) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 36),
                const SizedBox(height: 12),
                Text('Analysis Failed', style: AppTextStyles.heading3),
                const SizedBox(height: 8),
                Text(vm.errorMessage!,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: colors.textSecondary),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: vm.clearAll,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }
}

// ─── Single Receipt Result ─────────────────────────────────────────────────

class _SingleResultView extends StatefulWidget {
  final ScanReceiptViewModel vm;
  final AppColorSet colors;
  const _SingleResultView({required this.vm, required this.colors});

  @override
  State<_SingleResultView> createState() => _SingleResultViewState();
}

class _SingleResultViewState extends State<_SingleResultView> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  String? _selectedAccountId;
  String? _selectedCategoryId;
  List<dynamic> _accounts = [];
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    final tx = widget.vm.parsedTransaction!;
    _titleCtrl = TextEditingController(text: tx.title);
    _amountCtrl = TextEditingController(text: tx.value.toStringAsFixed(2));
    _selectedAccountId = tx.accountId;
    _selectedCategoryId = tx.categoryId;
    _loadDropdowns();
  }

  Future<void> _loadDropdowns() async {
    final accounts = await LocalDbService.instance.getAccounts();
    final cats = await LocalDbService.instance.getCategories();
    setState(() {
      _accounts = accounts;
      _categories = cats;
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.border, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Text('Receipt Parsed', style: AppTextStyles.labelLarge),
                  ],
                ),
                const SizedBox(height: 20),
                _buildField('Merchant / Title', _titleCtrl),
                const SizedBox(height: 14),
                _buildField('Amount', _amountCtrl, isNumber: true),
                const SizedBox(height: 14),
                _buildDropdown<dynamic>(
                  label: 'Account',
                  value: _accounts.isEmpty ? null : _selectedAccountId,
                  items: _accounts.map((a) {
                    return DropdownMenuItem(
                        value: a.id,
                        child: Text(a.name, overflow: TextOverflow.ellipsis));
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedAccountId = v?.id ?? v),
                  colors: colors,
                ),
                const SizedBox(height: 14),
                _buildDropdown<Category>(
                  label: 'Category',
                  value: _categories.isEmpty ? null : _categories.firstWhere(
                    (c) => c.id == _selectedCategoryId,
                    orElse: () => _categories.first,
                  ),
                  items: _categories.map((c) {
                    return DropdownMenuItem(value: c, child: Text(c.name, overflow: TextOverflow.ellipsis));
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedCategoryId = v?.id),
                  colors: colors,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: () async {
                await widget.vm.saveSingleReceipt(
                  _selectedAccountId ?? '',
                  _selectedCategoryId ?? '',
                  _titleCtrl.text.trim(),
                  NumberFormatter.parseAmount(_amountCtrl.text),
                );
                if (context.mounted) {
                  context.read<LedgerViewModel>().refresh();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Receipt saved to ledger ✓'),
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              },
              icon: const Icon(Icons.save_alt_rounded),
              label: const Text('Save Transaction'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity, height: 48,
            child: OutlinedButton.icon(
              onPressed: widget.vm.clearAll,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Scan Another'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.textSecondary,
                side: BorderSide(color: colors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl,
      {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required AppColorSet colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.labelSmall
                .copyWith(color: colors.textSecondary)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: colors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            dropdownColor: colors.surface,
            items: items,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

// ─── Bulk PDF Result ──────────────────────────────────────────────────────

class _BulkResultView extends StatefulWidget {
  final ScanReceiptViewModel vm;
  final AppColorSet colors;
  const _BulkResultView({required this.vm, required this.colors});

  @override
  State<_BulkResultView> createState() => _BulkResultViewState();
}

class _BulkResultViewState extends State<_BulkResultView> {
  String? _selectedAccountId;
  List<dynamic> _accounts = [];
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
  }

  Future<void> _loadDropdowns() async {
    final accounts = await LocalDbService.instance.getAccounts();
    final cats = await LocalDbService.instance.getCategories();
    setState(() {
      _accounts = accounts;
      _categories = cats;
      if (accounts.isNotEmpty) _selectedAccountId = accounts.first.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final vm = widget.vm;
    final txs = vm.parsedTransactions;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  color: AppColors.success, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text('${txs.length} transactions found',
                    style: AppTextStyles.labelLarge,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              if (_accounts.isNotEmpty)
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: DropdownButton<String>(
                      value: _selectedAccountId,
                      underline: const SizedBox.shrink(),
                      dropdownColor: colors.surface,
                      isExpanded: false,
                      items: _accounts
                          .map((a) => DropdownMenuItem<String>(
                              value: a.id as String,
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 120),
                                child: Text(a.name as String,
                                    style: AppTextStyles.bodySmall,
                                    overflow: TextOverflow.ellipsis),
                              )))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedAccountId = v),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: txs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final tx = txs[i];
              final isExpense = tx.type == TransactionType.expense;
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border, width: 0.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tx.title,
                              style: AppTextStyles.labelSmall,
                              overflow: TextOverflow.ellipsis),
                          Text(tx.date.toIso8601String().substring(0, 10),
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: colors.textTertiary)),
                        ],
                      ),
                    ),
                    Text(
                      '${isExpense ? '-' : '+'}\$${NumberFormatter.formatDouble(tx.value.abs())}',
                      style: AppTextStyles.labelMedium.copyWith(
                          color: isExpense ? AppColors.error : AppColors.success),
                    ),
                    const SizedBox(width: 8),
                    if (_categories.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxWidth: 110),
                        child: DropdownButton<Category>(
                          isExpanded: true,
                          value: _categories.firstWhere(
                            (c) => c.id == tx.categoryId,
                            orElse: () => _categories.first,
                          ),
                          underline: const SizedBox.shrink(),
                          dropdownColor: colors.surface,
                          items: _categories
                              .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c.name,
                                      style: AppTextStyles.bodySmall,
                                      overflow: TextOverflow.ellipsis)))
                              .toList(),
                          onChanged: (c) {
                            if (c != null) {
                              vm.updateBulkTransactionCategory(i, c.id);
                            }
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: () async {
                final count = txs.length;
                await vm.saveBulkTransactions(_selectedAccountId ?? '');
                if (context.mounted) {
                  context.read<LedgerViewModel>().refresh();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('$count transactions saved ✓'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.success,
                  ));
                }
              },
              icon: const Icon(Icons.save_alt_rounded),
              label: Text('Save All ${txs.length} Transactions'),
            ),
          ),
        ),
      ],
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final AppColorSet colors;
  const _ModeTab(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap,
      required this.colors});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.brand : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: selected ? Colors.white : colors.textSecondary),
              const SizedBox(width: 6),
              Text(label,
                  style: AppTextStyles.labelSmall.copyWith(
                      color: selected ? Colors.white : colors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
