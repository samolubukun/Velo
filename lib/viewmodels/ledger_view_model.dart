import 'package:flutter/foundation.dart' hide Category;
import '../models/account.dart';
import '../models/transaction_record.dart';
import '../models/user_profile.dart';
import '../services/local_db_service.dart';
import '../services/finance_health_service.dart';

/// LedgerViewModel manages the main dashboard state:
/// accounts, recent transactions, financial health metrics,
/// and private mode toggling.
class LedgerViewModel extends ChangeNotifier {
  final LocalDbService _db;

  List<Account> _accounts = [];
  List<TransactionRecord> _transactions = [];
  List<Category> _categories = [];
  UserProfile? _profile;

  bool _isPrivateMode = false;
  bool _isLoading = false;

  double _savingsPercentage = 0.0;
  double _survivalIndex = 0.0;
  double _healthScore = 0.0;

  LedgerViewModel(this._db);

  List<Account> get accounts => _accounts;
  List<TransactionRecord> get transactions => _transactions;
  List<Category> get categories => _categories;
  UserProfile? get profile => _profile;
  bool get isPrivateMode => _isPrivateMode;
  bool get isLoading => _isLoading;
  double get savingsPercentage => _savingsPercentage;
  double get survivalIndex => _survivalIndex;
  double get healthScore => _healthScore;

  /// Total value across all accounts (in base currency — simplified)
  double get totalBalance => _accounts.fold(0.0, (s, a) => s + a.currentValue);

  /// Income this calendar month
  double get monthIncome {
    final now = DateTime.now();
    return _transactions
        .where((t) => t.type == TransactionType.income &&
            t.date.month == now.month && t.date.year == now.year)
        .fold(0.0, (s, t) => s + t.value);
  }

  /// Expenses this calendar month
  double get monthExpenses {
    final now = DateTime.now();
    return _transactions
        .where((t) => t.type == TransactionType.expense &&
            t.date.month == now.month && t.date.year == now.year)
        .fold(0.0, (s, t) => s + t.value);
  }

  /// Active recurring subscriptions detected from transaction history
  List<TransactionRecord> get activeSubscriptions {
    final Map<String, List<TransactionRecord>> byTitle = {};
    for (final tx in _transactions) {
      if (tx.type != TransactionType.expense) continue;
      final key = tx.title.toLowerCase().trim();
      byTitle.putIfAbsent(key, () => []).add(tx);
    }
    // Keep only titles that appear in at least 2 different months
    final List<TransactionRecord> recurring = [];
    for (final entry in byTitle.entries) {
      final months = entry.value.map((t) => '${t.date.year}-${t.date.month}').toSet();
      if (months.length >= 2) {
        // Return the most recent occurrence
        final sorted = List<TransactionRecord>.from(entry.value)
          ..sort((a, b) => b.date.compareTo(a.date));
        recurring.add(sorted.first);
      }
    }
    recurring.sort((a, b) => b.date.compareTo(a.date));
    return recurring;
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    _profile = await _db.getProfile();
    _isPrivateMode = _profile?.isPrivateMode ?? false;
    await refresh();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    _accounts = await _db.getAccounts();
    _transactions = await _db.getTransactions();
    _categories = await _db.getCategories();
    _recalculateHealth();
    notifyListeners();
  }

  void _recalculateHealth() {
    final service = FinanceHealthService.instance;
    _savingsPercentage = service.calculateSavingsPercentage(monthIncome, monthExpenses);
    _survivalIndex = service.calculateSurvivalIndex(_accounts, _transactions);
    _healthScore = service.calculateWeightedHealthScore(_savingsPercentage, _survivalIndex);
  }

  void togglePrivateMode() {
    _isPrivateMode = !_isPrivateMode;
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    await _db.deleteTransaction(id);
    await refresh();
  }

  Future<void> deleteAccount(String id) async {
    await _db.deleteAccount(id);
    await refresh();
  }

  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Account? getAccountById(String id) {
    try {
      return _accounts.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}
