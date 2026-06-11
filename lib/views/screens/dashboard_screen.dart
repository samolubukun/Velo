import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../services/finance_health_service.dart';
import '../../services/local_db_service.dart';
import '../../viewmodels/ledger_view_model.dart';
import '../../models/account.dart';
import '../../models/transaction_record.dart';
import '../../utils/number_formatter.dart';

/// Dashboard Screen — Tab 0
/// Displays total balance, account carousel, recent transactions,
/// financial health scores, and active subscriptions.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LedgerViewModel>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Consumer<LedgerViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return Scaffold(
            backgroundColor: colors.scaffold,
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.brand),
            ),
          );
        }
        return Scaffold(
          backgroundColor: colors.scaffold,
          body: SafeArea(
            child: RefreshIndicator(
              color: AppColors.brand,
              backgroundColor: colors.surface,
              onRefresh: vm.refresh,
              child: CustomScrollView(
                slivers: [
                  // ── Header ──────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back,',
                                  style: AppTextStyles.bodySmall.copyWith(
                                      color: colors.textSecondary),
                                ),
                                Text(
                                  vm.profile?.name.isEmpty == false
                                      ? vm.profile!.name
                                      : 'Velo User',
                                  style: AppTextStyles.heading1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Total Balance Card ────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: _BalanceCard(vm: vm, colors: colors),
                    ),
                  ),

                  // ── Financial Health Row ──────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _HealthRow(vm: vm, colors: colors),
                    ),
                  ),

                  // ── Accounts ─────────────────────────────────────────
                  if (vm.accounts.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: Row(
                          children: [
                            Text('Accounts', style: AppTextStyles.heading3),
                            const Spacer(),
                            Text(
                              'Hold card to edit/delete',
                              style: AppTextStyles.bodySmall.copyWith(color: colors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 110,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          itemCount: vm.accounts.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, i) {
                            final acc = vm.accounts[i];
                            return GestureDetector(
                              onLongPress: () => _showAccountActions(context, acc, vm, colors),
                              child: _AccountCard(
                                name: acc.name,
                                balance: vm.isPrivateMode
                                    ? '${acc.currency} ••••'
                                    : '${acc.currency} ${NumberFormatter.formatDouble(acc.currentValue)}',
                                type: acc.type,
                                color: Color(acc.colorValue),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],

                  // ── Active Subscriptions ──────────────────────────────
                  if (vm.activeSubscriptions.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: Row(
                          children: [
                            Text('Active Subscriptions',
                                style: AppTextStyles.heading3),
                            const Spacer(),
                            Text(
                              '${vm.activeSubscriptions.length} detected',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: colors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _SubscriptionsPanel(
                          vm: vm, colors: colors),
                    ),
                  ],

                  // ── Recent Transactions ───────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Text('Recent Transactions',
                          style: AppTextStyles.heading3),
                    ),
                  ),

                  if (vm.transactions.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: _EmptyState(colors: colors),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final tx = vm.transactions[i];
                          return Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20, 0, 20, 8),
                            child: GestureDetector(
                              onLongPress: () => _confirmDeleteTransaction(context, tx, vm, colors),
                              child: _TransactionTile(
                                tx: tx,
                                vm: vm,
                                isPrivate: vm.isPrivateMode,
                                colors: colors,
                              ),
                            ),
                          );
                        },
                        childCount: vm.transactions.length > 20
                            ? 20
                            : vm.transactions.length,
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

  void _showAccountActions(BuildContext context, Account acc, LedgerViewModel vm, AppColorSet colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.textTertiary, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: Color(acc.colorValue).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
                child: Icon(Icons.account_balance_wallet_outlined, color: Color(acc.colorValue), size: 26),
              ),
              const SizedBox(height: 12),
              Text(acc.name, style: AppTextStyles.heading2),
              Text('${acc.currency} ${NumberFormatter.formatDouble(acc.currentValue)}', style: AppTextStyles.bodyMedium.copyWith(color: colors.textSecondary)),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Account'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditAccountDialog(context, acc, vm, colors);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Delete Account', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteAccount(context, acc, vm, colors);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditAccountDialog(BuildContext context, Account acc, LedgerViewModel vm, AppColorSet colors) {
    final nameCtrl = TextEditingController(text: acc.name);
    final ibanCtrl = TextEditingController(text: acc.iban);
    final swiftCtrl = TextEditingController(text: acc.swift);
    String selectedType = acc.type;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.account_balance_wallet_outlined))),
            const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _typeChip('normal', 'Current', selectedType, (v) => selectedType = v, colors.border)),
                const SizedBox(width: 12),
                Expanded(child: _typeChip('saving', 'Savings', selectedType, (v) => selectedType = v, colors.border)),
              ]),
            const SizedBox(height: 12),
            TextField(controller: ibanCtrl, decoration: const InputDecoration(labelText: 'IBAN', prefixIcon: Icon(Icons.numbers))),
            const SizedBox(height: 12),
            TextField(controller: swiftCtrl, decoration: const InputDecoration(labelText: 'SWIFT', prefixIcon: Icon(Icons.code))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final updated = acc.copyWith(
                name: nameCtrl.text.trim().isEmpty ? acc.name : nameCtrl.text.trim(),
                type: selectedType,
                iban: ibanCtrl.text.trim(),
                swift: swiftCtrl.text.trim(),
              );
              await LocalDbService.instance.saveAccount(updated);
              if (ctx.mounted) Navigator.pop(ctx);
              await vm.refresh();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _typeChip(String value, String label, String selected, ValueChanged<String> onChanged, [Color? borderColor]) {
    final active = value == selected;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.brand : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? AppColors.brand : (borderColor ?? AppColors.border)),
        ),
        child: Center(child: Text(label, style: TextStyle(color: active ? Colors.white : null, fontWeight: FontWeight.w600))),
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, Account acc, LedgerViewModel vm, AppColorSet colors) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: const Text('Delete Account'),
        content: Text('Delete "${acc.name}"? This will also delete all its transactions.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await vm.deleteAccount(acc.id);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTransaction(BuildContext context, TransactionRecord tx, LedgerViewModel vm, AppColorSet colors) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: const Text('Delete Transaction'),
        content: Text('Delete "${tx.title}" (\$${NumberFormatter.formatDouble(tx.value.abs())})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await vm.deleteTransaction(tx.id);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  final LedgerViewModel vm;
  final AppColorSet colors;
  const _BalanceCard({required this.vm, required this.colors});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: vm.togglePrivateMode,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A0F06), Color(0xFF2D1709)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: AppColors.brand.withValues(alpha: 0.25), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Balance',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.brand.withValues(alpha: 0.8))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: vm.isPrivateMode
                        ? AppColors.brand.withValues(alpha: 0.15)
                        : colors.surfaceAlt.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: vm.isPrivateMode
                            ? AppColors.brand.withValues(alpha: 0.4)
                            : colors.border.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        vm.isPrivateMode
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 10,
                        color: vm.isPrivateMode
                            ? AppColors.brand
                            : colors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        vm.isPrivateMode ? 'Private' : 'Public',
                        style: AppTextStyles.labelSmall.copyWith(
                          fontSize: 9,
                          color: vm.isPrivateMode
                              ? AppColors.brand
                              : colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              vm.isPrivateMode ? '••••••' : '\$${NumberFormatter.formatDouble(vm.totalBalance)}',
              style: AppTextStyles.displayMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 36,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _balanceStat('Income', vm.monthIncome, AppColors.success, vm.isPrivateMode),
                const SizedBox(width: 24),
                _balanceStat('Expenses', vm.monthExpenses, AppColors.error, vm.isPrivateMode),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.touch_app_outlined, size: 10, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  'Tap to toggle private mode',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textTertiary, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _balanceStat(String label, double value, Color color, bool isPrivate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.bodySmall
                .copyWith(color: colors.textSecondary, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          isPrivate ? '••••' : '\$${NumberFormatter.formatDouble(value)}',
          style: AppTextStyles.labelLarge.copyWith(color: color, fontSize: 14),
        ),
      ],
    );
  }
}

class _HealthRow extends StatelessWidget {
  final LedgerViewModel vm;
  final AppColorSet colors;
  const _HealthRow({required this.vm, required this.colors});

  @override
  Widget build(BuildContext context) {
    final healthColor =
        FinanceHealthService.instance.getHealthColor(vm.healthScore);
    return Row(
      children: [
        Expanded(
            child: _MetricCard(
          label: 'Savings %',
          value: '${vm.savingsPercentage.toStringAsFixed(1)}%',
          icon: Icons.savings_outlined,
          color: AppColors.success,
          colors: colors,
        )),
        const SizedBox(width: 10),
        Expanded(
            child: _MetricCard(
          label: 'Runway',
          value: '${vm.survivalIndex.toStringAsFixed(1)} mo',
          icon: Icons.timeline_outlined,
          color: AppColors.brand,
          colors: colors,
        )),
        const SizedBox(width: 10),
        Expanded(
            child: _MetricCard(
          label: 'Health',
          value: '${vm.healthScore.toStringAsFixed(0)}/100',
          icon: Icons.monitor_heart_outlined,
          color: healthColor,
          colors: colors,
        )),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final AppColorSet colors;
  const _MetricCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color,
      required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value,
              style: AppTextStyles.labelLarge
                  .copyWith(color: color, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label,
              style:
                  AppTextStyles.bodySmall.copyWith(color: colors.textSecondary, fontSize: 10)),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final String name, balance, type;
  final Color color;
  const _AccountCard(
      {required this.name,
      required this.balance,
      required this.type,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                type == 'saving'
                    ? Icons.savings_outlined
                    : Icons.account_balance_wallet_outlined,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(type == 'saving' ? 'Savings' : 'Current',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: color.withValues(alpha: 0.8))),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(balance,
                  style: AppTextStyles.labelLarge
                      .copyWith(fontWeight: FontWeight.w700)),
              Text(name,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubscriptionsPanel extends StatelessWidget {
  final LedgerViewModel vm;
  final AppColorSet colors;
  const _SubscriptionsPanel({required this.vm, required this.colors});

  @override
  Widget build(BuildContext context) {
    final subs = vm.activeSubscriptions.take(4).toList();
    final total = subs.fold(0.0, (s, t) => s + t.value);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border, width: 0.5),
      ),
      child: Column(
        children: [
          ...subs.map((s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.repeat_rounded,
                        size: 14, color: AppColors.accent),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(s.title, style: AppTextStyles.bodySmall)),
                    Text(
                      vm.isPrivateMode
                          ? '••••'
                          : '\$${NumberFormatter.formatDouble(s.value.abs())}',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.error),
                    ),
                  ],
                ),
              )),
          Divider(color: colors.border, height: 16),
          Row(
            children: [
              Text('Total recurring / month',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: colors.textSecondary)),
              const Spacer(),
              Text(
                vm.isPrivateMode ? '••••' : '\$${NumberFormatter.formatDouble(total)}',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.error, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionRecord tx;
  final LedgerViewModel vm;
  final bool isPrivate;
  final AppColorSet colors;
  const _TransactionTile(
      {required this.tx,
      required this.vm,
      required this.isPrivate,
      required this.colors});

  @override
  Widget build(BuildContext context) {
    final isExpense = tx.type == TransactionType.expense;
    final valueColor = isExpense ? AppColors.error : AppColors.success;
    final prefix = isExpense ? '-' : '+';
    final cat = vm.getCategoryById(tx.categoryId);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: valueColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isExpense ? Icons.remove_circle_outline : Icons.add_circle_outline,
              color: valueColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.title,
                    style: AppTextStyles.labelMedium,
                    overflow: TextOverflow.ellipsis),
                Text(
                  cat?.name ?? tx.type.name,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isPrivate ? '••••' : '$prefix\$${NumberFormatter.formatDouble(tx.value.abs())}',
                style: AppTextStyles.labelMedium.copyWith(color: valueColor),
              ),
              Text(
                tx.date.toIso8601String().substring(0, 10),
                style: AppTextStyles.bodySmall
                    .copyWith(color: colors.textTertiary, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppColorSet colors;
  const _EmptyState({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 48, color: colors.textTertiary),
          const SizedBox(height: 16),
          Text('No Transactions Yet', style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add a transaction, scan a receipt, or import a bank statement.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall
                .copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
