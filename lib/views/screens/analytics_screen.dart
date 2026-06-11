import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../services/finance_health_service.dart';
import '../../services/local_db_service.dart';
import '../../viewmodels/ledger_view_model.dart';
import '../../models/transaction_record.dart';
import '../../models/budget_limit.dart';
import '../widgets/transaction_card.dart';
import '../../utils/number_formatter.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Consumer<LedgerViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          backgroundColor: colors.scaffold,
          body: SafeArea(
            child: RefreshIndicator(
              color: AppColors.brand,
              backgroundColor: colors.surface,
              onRefresh: vm.refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Analytics', style: AppTextStyles.heading1),
                    const SizedBox(height: 20),
                    _healthGauge(colors, vm),
                    const SizedBox(height: 20),
                    _spendingPieChart(context, colors, vm),
                    const SizedBox(height: 20),
                    _cashFlowChart(context, colors, vm),
                    const SizedBox(height: 20),
                    _budgetProgress(context, colors),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _healthGauge(AppColorSet colors, LedgerViewModel vm) {
    final healthColor = FinanceHealthService.instance.getHealthColor(vm.healthScore);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border, width: 0.5),
      ),
      child: Column(
        children: [
          CircularPercentIndicator(
            radius: 80,
            lineWidth: 12,
            percent: vm.healthScore / 100,
            progressColor: healthColor,
            backgroundColor: colors.surfaceAlt,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${vm.healthScore.toStringAsFixed(0)}',
                    style: AppTextStyles.heading1.copyWith(fontSize: 32, fontWeight: FontWeight.w700)),
                Text('/ 100', style: AppTextStyles.bodySmall.copyWith(color: colors.textTertiary)),
              ],
            ),
            circularStrokeCap: CircularStrokeCap.round,
            animateFromLastPercent: true,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _statLabel(colors, 'Savings', '${vm.savingsPercentage.toStringAsFixed(0)}%'),
              ),
              Container(width: 1, height: 32, color: colors.border),
              Expanded(
                child: _statLabel(colors, 'Survival', '${vm.survivalIndex.toStringAsFixed(1)}mo'),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08);
  }

  Widget _statLabel(AppColorSet colors, String label, String value) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.heading2.copyWith(color: AppColors.brand)),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: colors.textTertiary)),
      ],
    );
  }

  Widget _spendingPieChart(BuildContext context, AppColorSet colors, LedgerViewModel vm) {
    final now = DateTime.now();
    final expenses = vm.transactions
        .where((t) => t.type == TransactionType.expense && t.date.month == now.month && t.date.year == now.year)
        .toList();

    final Map<String, double> byCategory = {};
    for (final tx in expenses) {
      byCategory.update(tx.categoryId, (v) => v + tx.value, ifAbsent: () => tx.value);
    }

    if (byCategory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Spending by Category', style: AppTextStyles.heading2),
            const SizedBox(height: 20),
            Center(
              child: Text('No expenses this month', style: AppTextStyles.bodyMedium.copyWith(color: colors.textTertiary)),
            ),
          ],
        ),
      );
    }

    final sorted = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = byCategory.values.fold(0.0, (s, v) => s + v);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spending by Category', style: AppTextStyles.heading2),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: sorted.map((entry) {
                  final cat = vm.getCategoryById(entry.key);
                  return PieChartSectionData(
                    value: entry.value,
                    color: Color(cat?.colorValue ?? 0xFFC87D55),
                    title: '${((entry.value / total) * 100).toStringAsFixed(0)}%',
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...sorted.take(5).map((entry) {
            final cat = vm.getCategoryById(entry.key);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: Color(cat?.colorValue ?? 0xFFC87D55),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(cat?.name ?? 'Unknown', style: AppTextStyles.bodySmall)),
                  Text('\$${NumberFormatter.formatInt(entry.value)}', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08);
  }

  Widget _cashFlowChart(BuildContext context, AppColorSet colors, LedgerViewModel vm) {
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final m = now.month - (5 - i);
      final y = now.year;
      if (m <= 0) return DateTime(y - 1, m + 12, 1);
      return DateTime(y, m, 1);
    });

    final monthlyIncome = <double>[];
    final monthlyExpenses = <double>[];

    for (final month in months) {
      double inc = 0, exp = 0;
      for (final tx in vm.transactions) {
        if (tx.date.month == month.month && tx.date.year == month.year) {
          if (tx.type == TransactionType.income) inc += tx.value;
          else if (tx.type == TransactionType.expense) exp += tx.value;
        }
      }
      monthlyIncome.add(inc);
      monthlyExpenses.add(exp);
    }

    final maxVal = [
      ...monthlyIncome,
      ...monthlyExpenses,
    ].fold(0.0, (max, v) => v > max ? v : max);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Monthly Cash Flow', style: AppTextStyles.heading2),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= months.length) return const SizedBox.shrink();
                        final monthNames = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(monthNames[months[idx].month - 1],
                              style: TextStyle(fontSize: 10, color: colors.textTertiary)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxVal > 0 ? maxVal / 4 : 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: colors.border.withValues(alpha: 0.3),
                    strokeWidth: 0.5,
                  ),
                ),
                barGroups: List.generate(months.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: monthlyIncome[i],
                        color: AppColors.success,
                        width: 10,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                      BarChartRodData(
                        toY: monthlyExpenses[i],
                        color: AppColors.error,
                        width: 10,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(AppColors.success, 'Income'),
              const SizedBox(width: 24),
              _legendDot(AppColors.error, 'Expenses'),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08);
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _budgetProgress(BuildContext context, AppColorSet colors) {
    return FutureBuilder<List>(
      future: LocalDbService.instance.getBudgets(),
      builder: (context, snapshot) {
        final budgets = snapshot.data ?? [];
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Budget Progress', style: AppTextStyles.heading2)),
                  GestureDetector(
                    onTap: () => _showAddBudgetDialog(context, colors),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.brand.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.add, size: 14, color: AppColors.brand),
                          const SizedBox(width: 4),
                          Text('Add', style: AppTextStyles.labelSmall.copyWith(color: AppColors.brand)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (budgets.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('No budgets set. Tap + to add one.',
                        style: AppTextStyles.bodyMedium.copyWith(color: colors.textTertiary)),
                  ),
                ),
              ...budgets.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onLongPress: () => _confirmDeleteBudget(context, b.id, colors),
                  child: BudgetProgressTile(
                    title: b.title,
                    current: b.currentAmount.toDouble(),
                    limit: b.limitAmount.toDouble(),
                  ),
                ),
              )),
            ],
          ),
        );
      },
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08);
  }

  void _showAddBudgetDialog(BuildContext context, AppColorSet colors) {
    final titleCtrl = TextEditingController();
    final limitCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Budget'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Budget Name', hintText: 'e.g. Monthly Groceries', prefixIcon: Icon(Icons.title))),
            const SizedBox(height: 12),
            TextField(controller: limitCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monthly Limit', prefixText: '\$ ', prefixIcon: Icon(Icons.attach_money))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = titleCtrl.text.trim();
              final limit = NumberFormatter.parseAmount(limitCtrl.text);
              if (name.isEmpty || limit <= 0) return;
              final budget = BudgetLimit(
                id: const Uuid().v4(),
                title: name,
                limitAmount: limit,
                currentAmount: 0,
                period: 'monthly',
              );
              await LocalDbService.instance.saveBudget(budget);
              if (ctx.mounted) Navigator.pop(ctx);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand),
            child: const Text('Add Budget', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteBudget(BuildContext context, String budgetId, AppColorSet colors) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: const Text('Delete Budget'),
        content: const Text('Delete this budget?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await LocalDbService.instance.deleteBudget(budgetId);
              if (ctx.mounted) Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
