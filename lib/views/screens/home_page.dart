import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/model_status.dart';
import '../../models/account.dart';
import '../../models/transaction_record.dart';
import '../../services/model_manager.dart';
import '../../services/local_db_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../viewmodels/ledger_view_model.dart';
import 'model_download_screen.dart';
import '../../utils/number_formatter.dart';
import 'settings_screen.dart';
import 'dashboard_screen.dart';
import 'scan_receipt_screen.dart';
import 'analytics_screen.dart';
import 'chat_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  // Tab order: Dashboard | Scan/Import | Analytics | AI Chat
  final _screens = const [
    DashboardScreen(),
    ScanReceiptScreen(),
    AnalyticsScreen(),
    ChatScreen(),
  ];

  @override
  void initState() {
    super.initState();
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarIconBrightness:
          brightness == Brightness.dark ? Brightness.light : Brightness.dark,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ModelManager>(
      builder: (context, mm, _) {
        if (!mm.isReady && !mm.setupSkipped) {
          return const ModelDownloadSetupScreen();
        }
        return _buildMainScaffold(context);
      },
    );
  }

  Widget _buildMainScaffold(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      extendBody: true,
      backgroundColor: colors.scaffold,
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: KeyedSubtree(
              key: ValueKey(_currentIndex),
              child: _screens[_currentIndex],
            ),
          ),
          // Top-right action buttons (hidden on Chat tab)
          if (_currentIndex != 3)
            Positioned(
              top: 8,
              right: 20,
              child: SafeArea(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _topButton(
                      icon: Icons.add,
                      color: AppColors.brand,
                      onTap: _showQuickActions,
                      colors: colors,
                    ),
                    const SizedBox(width: 8),
                    _topButton(
                      icon: Icons.settings_outlined,
                      color: colors.textSecondary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      ),
                      colors: colors,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(colors),
    );
  }

  Widget _topButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required AppColorSet colors,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.card.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border.withValues(alpha: 0.5)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context) async {
    final colors = AppColors.of(context);
    final nameCtrl = TextEditingController();
    final balanceCtrl = TextEditingController(text: '0');
    String selectedType = 'normal';

    final profile = await LocalDbService.instance.getProfile();
    final selectedCurrency = profile?.baseCurrency ?? 'USD';

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          scrollable: true,
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _accountTypeChip('normal', 'Current', selectedType, (v) {
                      setDialogState(() => selectedType = v);
                    }),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _accountTypeChip('saving', 'Savings', selectedType, (v) {
                      setDialogState(() => selectedType = v);
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Account Name',
                  hintText: 'e.g. Chase Current',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: balanceCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Current Balance',
                  prefixText: '$selectedCurrency ',
                  prefixIcon: const Icon(Icons.attach_money_rounded),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final balance = NumberFormatter.parseAmount(balanceCtrl.text);
                final account = Account(
                  id: const Uuid().v4(),
                  name: name,
                  initialValue: balance,
                  currentValue: balance,
                  type: selectedType,
                  currency: selectedCurrency,
                  colorValue: _randomColor(),
                );
                await LocalDbService.instance.saveAccount(account);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  context.read<LedgerViewModel>().refresh();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Account added ✓'),
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand),
              child: const Text('Add Account', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  int _randomColor() {
    const colors = [0xFFC87D55, 0xFF10B981, 0xFF3498DB, 0xFF9B59B6, 0xFF1ABC9C, 0xFFE74C3C, 0xFFF1C40F];
    return colors[Random().nextInt(colors.length)];
  }

  Widget _accountTypeChip(String value, String label, String selected, ValueChanged<String> onTap) {
    final active = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.brand : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? AppColors.brand : AppColors.textTertiary.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  color: active ? Colors.white : AppColors.textTertiary,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  void _showManualTransactionDialog(BuildContext context) {
    final colors = AppColors.of(context);
    final vm = context.read<LedgerViewModel>();

    if (vm.accounts.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('No Accounts Found'),
          content: const Text('Please add at least one account before logging a transaction.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    
    TransactionType selectedType = TransactionType.expense;
    String selectedAccountId = vm.accounts.first.id;
    
    String? selectedCategoryId;
    final initialFiltered = vm.categories.where((c) => c.type == 'E' || c.type == 'B').toList();
    if (initialFiltered.isNotEmpty) {
      selectedCategoryId = initialFiltered.first.id;
    }

    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final filteredCategories = vm.categories.where((c) {
            if (selectedType == TransactionType.income) {
              return c.type == 'I' || c.type == 'B';
            } else {
              return c.type == 'E' || c.type == 'B';
            }
          }).toList();

          if (selectedCategoryId == null || !filteredCategories.any((c) => c.id == selectedCategoryId)) {
            selectedCategoryId = filteredCategories.isNotEmpty ? filteredCategories.first.id : null;
          }

          final currentAccount = vm.accounts.firstWhere((a) => a.id == selectedAccountId);

          return AlertDialog(
            scrollable: true,
            backgroundColor: colors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Log Transaction', style: AppTextStyles.heading2),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() {
                            selectedType = TransactionType.expense;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selectedType == TransactionType.expense
                                  ? AppColors.error.withValues(alpha: 0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedType == TransactionType.expense
                                    ? AppColors.error
                                    : colors.border,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Expense',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: selectedType == TransactionType.expense
                                      ? AppColors.error
                                      : colors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() {
                            selectedType = TransactionType.income;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selectedType == TransactionType.income
                                  ? AppColors.success.withValues(alpha: 0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedType == TransactionType.income
                                    ? AppColors.success
                                    : colors.border,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Income',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: selectedType == TransactionType.income
                                      ? AppColors.success
                                      : colors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Title / Merchant',
                      hintText: 'e.g. Starbucks',
                      prefixIcon: Icon(Icons.title_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: '${currentAccount.currency} ',
                      prefixIcon: const Icon(Icons.attach_money_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedAccountId,
                    decoration: const InputDecoration(
                      labelText: 'Account',
                      prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                    ),
                    items: vm.accounts.map((acc) {
                      return DropdownMenuItem(
                        value: acc.id,
                        child: Text('${acc.name} (${acc.currency})'),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => selectedAccountId = v);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  if (filteredCategories.isNotEmpty)
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: filteredCategories.map((cat) {
                        return DropdownMenuItem(
                          value: cat.id,
                          child: Text(cat.name),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() => selectedCategoryId = v);
                        }
                      },
                    ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        prefixIcon: Icon(Icons.calendar_today_rounded),
                      ),
                      child: Text(
                        '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                        style: TextStyle(color: colors.textPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                ],
              ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  if (title.isEmpty) return;
                  final amount = NumberFormatter.parseAmount(amountCtrl.text);
                  if (amount <= 0) return;

                  final record = TransactionRecord(
                    id: const Uuid().v4(),
                    value: amount,
                    title: title,
                    type: selectedType,
                    categoryId: selectedCategoryId ?? 'cat_other',
                    accountId: selectedAccountId,
                    date: selectedDate,
                    notes: notesCtrl.text.trim(),
                  );

                  await LocalDbService.instance.saveTransaction(record);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    context.read<LedgerViewModel>().refresh();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Transaction saved ✓'),
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                ),
                child: const Text('Save', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showQuickActions() {
    final colors = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: colors.textTertiary.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Quick Actions', style: AppTextStyles.heading2),
                const SizedBox(height: 20),

                _quickActionTile(ctx, colors,
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Add Account',
                  desc: 'Add a new current or savings account',
                  color: AppColors.brand,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showAddAccountDialog(context);
                  },
                ),
                const SizedBox(height: 8),

                _quickActionTile(ctx, colors,
                  icon: Icons.add_circle_outline_rounded,
                  label: 'Log Transaction Manually',
                  desc: 'Directly record an income or expense entry',
                  color: AppColors.success,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showManualTransactionDialog(context);
                  },
                ),
                const SizedBox(height: 8),

                _quickActionTile(ctx, colors,
                  icon: Icons.edit_note_rounded,
                  label: 'Describe Transaction',
                  desc: 'Type a natural language description to log a transaction',
                  color: AppColors.info,
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(context, '/describe-tx');
                  },
                ),
                const SizedBox(height: 8),

                _quickActionTile(ctx, colors,
                  icon: Icons.receipt_long_rounded,
                  label: 'Scan Receipt',
                  desc: 'Capture a receipt photo for automatic transaction entry',
                  color: AppColors.brand,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _currentIndex = 1);
                  },
                ),
                const SizedBox(height: 8),

                _quickActionTile(ctx, colors,
                  icon: Icons.picture_as_pdf_rounded,
                  label: 'Import Bank Statement',
                  desc: 'Upload a PDF bank statement to bulk import transactions',
                  color: AppColors.accent,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _currentIndex = 1);
                  },
                ),
                const SizedBox(height: 8),

                _quickActionTile(ctx, colors,
                  icon: Icons.smart_toy_outlined,
                  label: '"Can I Afford This?"',
                  desc: 'Ask Velo AI if a purchase fits your current budget',
                  color: const Color(0xFF9B59B6),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _currentIndex = 3);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _quickActionTile(
    BuildContext ctx,
    AppColorSet colors, {
    required IconData icon,
    required String label,
    required String desc,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.labelLarge),
                  const SizedBox(height: 2),
                  Text(desc,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: colors.textSecondary),
                      maxLines: 2),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(AppColorSet colors) {
    return SafeArea(
      bottom: true,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.border, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 28,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.brand,
            unselectedItemColor: colors.textTertiary,
            selectedFontSize: 10,
            unselectedFontSize: 10,
            selectedLabelStyle: const TextStyle(
                fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 10),
            unselectedLabelStyle: const TextStyle(
                fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 10),
            items: [
              _navItem(Icons.account_balance_wallet_outlined,
                  Icons.account_balance_wallet, 'Dashboard', 0),
              _navItem(Icons.receipt_long_outlined,
                  Icons.receipt_long_rounded, 'Scan', 1),
              _navItem(Icons.bar_chart_outlined,
                  Icons.bar_chart_rounded, 'Analytics', 2),
              _navItem(Icons.chat_bubble_outline_rounded,
                  Icons.chat_bubble_rounded, 'Velo AI', 3),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _navItem(
      IconData outline, IconData filled, String label, int index) {
    return BottomNavigationBarItem(
      icon: Icon(_currentIndex == index ? filled : outline, size: 22),
      label: label,
    );
  }
}
