import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/account.dart';
import '../models/budget_limit.dart';
import '../models/transaction_record.dart';

class LocalDbService {
  static const _profileKey = 'velo_user_profile';
  static const _accountsKey = 'velo_accounts';
  static const _transactionsKey = 'velo_transactions';
  static const _budgetsKey = 'velo_budgets';
  static const _categoriesKey = 'velo_categories';
  static const _tagsKey = 'velo_tags';
  static const _exchangeRatesKey = 'velo_exchange_rates';

  static final LocalDbService instance = LocalDbService._();
  LocalDbService._();

  // --- Initialize and Seed Default Data ---
  Future<void> initializeDatabase() async {
    final prefs = await SharedPreferences.getInstance();

    // Seed Categories if empty
    if (!prefs.containsKey(_categoriesKey)) {
      final defaultCategories = [
        const Category(id: 'cat_income', name: 'Salary & Income', type: 'I', colorValue: 0xFF10B981, iconName: 'monetization_on'),
        const Category(id: 'cat_food', name: 'Food & Dining', type: 'E', colorValue: 0xFFC87D55, iconName: 'restaurant'),
        const Category(id: 'cat_housing', name: 'Housing & Rent', type: 'E', colorValue: 0xFF3498DB, iconName: 'home'),
        const Category(id: 'cat_utilities', name: 'Utilities & Bills', type: 'E', colorValue: 0xFFF1C40F, iconName: 'flash_on'),
        const Category(id: 'cat_shopping', name: 'Shopping & Apparel', type: 'E', colorValue: 0xFF9B59B6, iconName: 'shopping_bag'),
        const Category(id: 'cat_travel', name: 'Travel & Transit', type: 'E', colorValue: 0xFF1ABC9C, iconName: 'directions_car'),
        const Category(id: 'cat_entertainment', name: 'Entertainment', type: 'E', colorValue: 0xFFE74C3C, iconName: 'movie'),
        const Category(id: 'cat_other', name: 'Other Expenses', type: 'E', colorValue: 0xFF7F8C8D, iconName: 'payment'),
      ];
      await prefs.setString(_categoriesKey, jsonEncode(defaultCategories.map((c) => c.toJson()).toList()));
    }

    // Seed Exchange Rates if empty
    if (!prefs.containsKey(_exchangeRatesKey)) {
      final defaultRates = {
        'USD_EUR': 0.92,
        'EUR_USD': 1.09,
        'USD_TRY': 32.50,
        'TRY_USD': 0.031,
        'USD_GBP': 0.78,
        'GBP_USD': 1.28,
        'EUR_TRY': 35.30,
        'TRY_EUR': 0.028,
        'USD_NGN': 1540.00,
        'NGN_USD': 0.00065,
        'EUR_NGN': 1670.00,
        'NGN_EUR': 0.00060,
        'GBP_NGN': 1940.00,
        'NGN_GBP': 0.00052,
        'USD_CAD': 1.36,
        'CAD_USD': 0.74,
        'USD_AUD': 1.52,
        'AUD_USD': 0.66,
        'EUR_CAD': 1.48,
        'EUR_AUD': 1.65,
      };
      await prefs.setString(_exchangeRatesKey, jsonEncode(defaultRates));
    }
  }

  // --- Exchange Rates Helpers ---
  Future<double> getExchangeRate(String from, String to) async {
    if (from == to) return 1.0;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_exchangeRatesKey);
    if (raw == null) return 1.0;
    final Map<String, dynamic> rates = jsonDecode(raw);
    final key = '${from}_${to}';
    if (rates.containsKey(key)) {
      return (rates[key] ?? 1.0).toDouble();
    }
    // Fallback search inverse
    final invKey = '${to}_${from}';
    if (rates.containsKey(invKey)) {
      final rate = (rates[invKey] ?? 1.0).toDouble();
      return rate > 0 ? 1.0 / rate : 1.0;
    }
    return 1.0; // Default flat conversion
  }

  // --- User Profile ---
  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  Future<UserProfile?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null) return null;
    return UserProfile.fromJson(jsonDecode(raw));
  }

  Future<bool> hasProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_profileKey);
  }

  // --- Accounts Table ---
  Future<List<Account>> getAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_accountsKey);
    if (raw == null) return [];
    final List<dynamic> list = jsonDecode(raw);
    return list.map((e) => Account.fromJson(e)).toList();
  }

  Future<void> saveAccount(Account account) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await getAccounts();
    final idx = accounts.indexWhere((a) => a.id == account.id);
    if (idx != -1) {
      accounts[idx] = account;
    } else {
      accounts.add(account);
    }
    await prefs.setString(_accountsKey, jsonEncode(accounts.map((a) => a.toJson()).toList()));
  }

  Future<void> deleteAccount(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await getAccounts();
    accounts.removeWhere((a) => a.id == id);
    await prefs.setString(_accountsKey, jsonEncode(accounts.map((a) => a.toJson()).toList()));
  }

  // --- Categories Table ---
  Future<List<Category>> getCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_categoriesKey);
    if (raw == null) return [];
    final List<dynamic> list = jsonDecode(raw);
    return list.map((e) => Category.fromJson(e)).toList();
  }

  Future<void> saveCategory(Category category) async {
    final prefs = await SharedPreferences.getInstance();
    final categories = await getCategories();
    categories.add(category);
    await prefs.setString(_categoriesKey, jsonEncode(categories.map((c) => c.toJson()).toList()));
  }

  // --- Tags Table ---
  Future<List<String>> getTags() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_tagsKey) ?? ['groceries', 'salary', 'entertainment', 'bills', 'rent'];
  }

  Future<void> saveTag(String tag) async {
    final prefs = await SharedPreferences.getInstance();
    final tags = await getTags();
    if (!tags.contains(tag)) {
      tags.add(tag);
      await prefs.setStringList(_tagsKey, tags);
    }
  }

  Future<void> deleteTag(String tag) async {
    final prefs = await SharedPreferences.getInstance();
    final tags = await getTags();
    tags.remove(tag);
    await prefs.setStringList(_tagsKey, tags);
  }

  // --- Transactions Table ---
  Future<List<TransactionRecord>> getTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_transactionsKey);
    if (raw == null) return [];
    final List<dynamic> list = jsonDecode(raw);
    final txs = list.map((e) => TransactionRecord.fromJson(e)).toList();
    txs.sort((a, b) => b.date.compareTo(a.date)); // descending date
    return txs;
  }

  Future<void> saveTransaction(TransactionRecord tx) async {
    final prefs = await SharedPreferences.getInstance();
    final txs = await getTransactions();
    final accounts = await getAccounts();

    final idx = txs.indexWhere((t) => t.id == tx.id);
    double oldValueDiff = 0.0;
    String? oldAccountId;
    TransactionType? oldType;

    if (idx != -1) {
      // Edit mode: determine diff
      final oldTx = txs[idx];
      oldValueDiff = oldTx.value;
      oldAccountId = oldTx.accountId;
      oldType = oldTx.type;
      txs[idx] = tx;
    } else {
      txs.add(tx);
    }

    // Revert old transaction value from account balance
    if (oldAccountId != null && oldType != null) {
      final accIdx = accounts.indexWhere((a) => a.id == oldAccountId);
      if (accIdx != -1) {
        final acc = accounts[accIdx];
        double balance = acc.currentValue;
        if (oldType == TransactionType.expense) {
          balance += oldValueDiff; // Revert spending
        } else if (oldType == TransactionType.income) {
          balance -= oldValueDiff; // Revert earning
        }
        accounts[accIdx] = acc.copyWith(currentValue: balance);
      }
    }

    // Apply new transaction value to account balance
    final accIdx = accounts.indexWhere((a) => a.id == tx.accountId);
    if (accIdx != -1) {
      final acc = accounts[accIdx];
      double balance = acc.currentValue;
      if (tx.type == TransactionType.expense) {
        balance -= tx.value;
      } else if (tx.type == TransactionType.income) {
        balance += tx.value;
      }
      accounts[accIdx] = acc.copyWith(currentValue: balance);
    }

    // If transfer type, update target account as well
    if (tx.type == TransactionType.transfer && tx.targetAccountId != null) {
      final targetIdx = accounts.indexWhere((a) => a.id == tx.targetAccountId);
      if (targetIdx != -1) {
        final targetAcc = accounts[targetIdx];
        double balance = targetAcc.currentValue + tx.value;
        accounts[targetIdx] = targetAcc.copyWith(currentValue: balance);
      }
    }

    // Save lists
    await prefs.setString(_transactionsKey, jsonEncode(txs.map((t) => t.toJson()).toList()));
    await prefs.setString(_accountsKey, jsonEncode(accounts.map((a) => a.toJson()).toList()));

    // Recalculate Budgets spent amounts
    await _recalculateBudgets();
  }

  Future<void> deleteTransaction(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final txs = await getTransactions();
    final accounts = await getAccounts();

    final idx = txs.indexWhere((t) => t.id == id);
    if (idx == -1) return;

    final tx = txs[idx];
    txs.removeAt(idx);

    // Revert balance
    final accIdx = accounts.indexWhere((a) => a.id == tx.accountId);
    if (accIdx != -1) {
      final acc = accounts[accIdx];
      double balance = acc.currentValue;
      if (tx.type == TransactionType.expense) {
        balance += tx.value;
      } else if (tx.type == TransactionType.income) {
        balance -= tx.value;
      }
      accounts[accIdx] = acc.copyWith(currentValue: balance);
    }

    await prefs.setString(_transactionsKey, jsonEncode(txs.map((t) => t.toJson()).toList()));
    await prefs.setString(_accountsKey, jsonEncode(accounts.map((a) => a.toJson()).toList()));

    await _recalculateBudgets();
  }

  // --- Budgets Table ---
  Future<List<BudgetLimit>> getBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_budgetsKey);
    if (raw == null) return [];
    final List<dynamic> list = jsonDecode(raw);
    return list.map((e) => BudgetLimit.fromJson(e)).toList();
  }

  Future<void> saveBudget(BudgetLimit budget) async {
    final prefs = await SharedPreferences.getInstance();
    final budgets = await getBudgets();
    final idx = budgets.indexWhere((b) => b.id == budget.id);
    if (idx != -1) {
      budgets[idx] = budget;
    } else {
      budgets.add(budget);
    }
    await prefs.setString(_budgetsKey, jsonEncode(budgets.map((b) => b.toJson()).toList()));
    await _recalculateBudgets();
  }

  Future<void> deleteBudget(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final budgets = await getBudgets();
    budgets.removeWhere((b) => b.id == id);
    await prefs.setString(_budgetsKey, jsonEncode(budgets.map((b) => b.toJson()).toList()));
  }

  Future<void> _recalculateBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final budgets = await getBudgets();
    final txs = await getTransactions();
    final categories = await getCategories();

    final now = DateTime.now();
    final updatedBudgets = <BudgetLimit>[];

    for (final b in budgets) {
      double spent = 0.0;
      // Filter transactions that fall within budget scope
      for (final tx in txs) {
        if (tx.type != TransactionType.expense) continue;

        // Check account scoping
        if (b.accountIds.isNotEmpty && !b.accountIds.contains(tx.accountId)) continue;

        // Check category scoping (with smart fallback if categoryIds is empty)
        bool matches = false;
        if (b.categoryIds.isNotEmpty) {
          matches = b.categoryIds.contains(tx.categoryId);
        } else {
          final bTitle = b.title.trim().toLowerCase();
          final txTitle = tx.title.toLowerCase();
          final txCat = categories.firstWhere((c) => c.id == tx.categoryId, orElse: () => const Category(id: '', name: '', type: 'E'));
          final catName = txCat.name.toLowerCase();

          if (bTitle == 'total' || bTitle == 'overall' || bTitle == 'all' || bTitle == 'monthly' || bTitle == 'budget') {
            matches = true;
          } else {
            matches = txTitle.contains(bTitle) || catName.contains(bTitle);
          }
        }
        if (!matches) continue;

        // Check date interval based on period
        bool dateMatches = false;
        final difference = now.difference(tx.date).inDays;

        if (b.period == 'daily' && difference == 0) {
          dateMatches = true;
        } else if (b.period == 'weekly' && difference <= 7) {
          dateMatches = true;
        } else if (b.period == 'monthly' && now.month == tx.date.month && now.year == tx.date.year) {
          dateMatches = true;
        } else if (b.period == 'yearly' && now.year == tx.date.year) {
          dateMatches = true;
        }

        if (dateMatches) {
          spent += tx.value;
        }
      }
      updatedBudgets.add(b.copyWith(currentAmount: spent));
    }
    await prefs.setString(_budgetsKey, jsonEncode(updatedBudgets.map((b) => b.toJson()).toList()));
  }

  // --- CSV Export Data Portability ---
  Future<String> exportTransactionsToCsv() async {
    final txs = await getTransactions();
    final categories = await getCategories();
    final accounts = await getAccounts();

    final buffer = StringBuffer();
    // Header
    buffer.writeln('ID,Date,Title,Value,Type,Status,Category,Account,Notes');

    for (final tx in txs) {
      final cat = categories.firstWhere((c) => c.id == tx.categoryId, orElse: () => const Category(id: '', name: 'N/A', type: 'E'));
      final acc = accounts.firstWhere((a) => a.id == tx.accountId, orElse: () => const Account(id: '', name: 'N/A', initialValue: 0, currentValue: 0, type: 'normal'));

      final dateStr = tx.date.toIso8601String().substring(0, 10);
      final notesCleaned = tx.notes.replaceAll('"', '""');

      buffer.writeln(
        '${tx.id},'
        '$dateStr,'
        '"${tx.title.replaceAll('"', '""')}",'
        '${tx.value},'
        '${tx.type.name},'
        '${tx.status.name},'
        '"${cat.name}",'
        '"${acc.name}",'
        '"$notesCleaned"'
      );
    }
    return buffer.toString();
  }
}
