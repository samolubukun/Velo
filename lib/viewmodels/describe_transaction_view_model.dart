import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/transaction_record.dart';
import '../models/account.dart';
import '../services/model_manager.dart';
import '../services/local_db_service.dart';

class DescribeTransactionViewModel extends ChangeNotifier {
  final ModelManager _modelManager;
  final LocalDbService _db;

  bool _isAnalyzing = false;
  String? _description;
  String? _analysisResult;
  TransactionRecord? _transactionRecord;
  String? _errorMessage;

  DescribeTransactionViewModel(this._modelManager, this._db);

  bool get isAnalyzing => _isAnalyzing;
  String? get description => _description;
  String? get analysisResult => _analysisResult;
  TransactionRecord? get transactionRecord => _transactionRecord;
  String? get errorMessage => _errorMessage;
  bool get hasResult => _transactionRecord != null;

  Future<void> analyze(String description) async {
    if (description.trim().isEmpty || _isAnalyzing) return;
    _description = description.trim();
    _isAnalyzing = true;
    _errorMessage = null;
    _analysisResult = null;
    _transactionRecord = null;
    notifyListeners();

    try {
      final prompt = '''
You are a financial parsing assistant. Analyze this natural language transaction description and extract details into valid JSON:

Input: "${description.trim()}"

Return ONLY this JSON structure with realistic extractions:
{
  "title": "Merchant or Description",
  "value": 12.34,
  "type": "expense",
  "category": "Food & Dining",
  "notes": "additional context or details"
}

Field descriptions:
- "value": numeric amount of the transaction.
- "type": must be "expense", "income", or "transfer".
- "category": must be one of: "Salary & Income", "Food & Dining", "Housing & Rent", "Utilities & Bills", "Shopping & Apparel", "Travel & Transit", "Entertainment", "Other Expenses".
- "notes": additional descriptive notes or details parsed from text.

Numbers must be output as regular numeric values, NOT wrapped in double quotes. Return ONLY the JSON block. Do not write explanation, notes or preamble.''';

      final response = await _modelManager.generateResponse(prompt);
      if (response != null) {
        _analysisResult = response;
        final parsed = await _parseTransactionJson(response);
        if (parsed != null) {
          _transactionRecord = parsed;
        } else {
          _setError('Could not extract transaction details. Try being more descriptive (e.g., "Spent \$23 on petrol today").');
        }
      } else {
        _setError('Analysis failed. Ensure the AI model is downloaded and ready.');
      }
    } catch (e) {
      _setError('Analysis error: $e');
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) {
      final cleaned = val.replaceAll(RegExp(r'[^0-9.-]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  Future<TransactionRecord?> _parseTransactionJson(String raw) async {
    try {
      String json = raw;
      final start = raw.indexOf('{');
      final end = raw.lastIndexOf('}');
      if (start != -1 && end != -1 && end > start) {
        json = raw.substring(start, end + 1);
      }
      final data = jsonDecode(json) as Map<String, dynamic>;

      // Resolve category matching database seeds
      final categories = await _db.getCategories();
      final parsedCatName = data['category']?.toString() ?? 'Other Expenses';
      final matchedCat = categories.firstWhere(
        (c) => c.name.toLowerCase().contains(parsedCatName.toLowerCase()) || 
               parsedCatName.toLowerCase().contains(c.name.toLowerCase()),
        orElse: () => categories.firstWhere((c) => c.id == 'cat_other'),
      );

      // Resolve account. Default to first current account.
      final accounts = await _db.getAccounts();
      if (accounts.isEmpty) {
        // Seed a default Chase account so transaction saves cleanly
        await _db.saveAccount(const Account(
          id: 'acc_checking',
          name: 'Primary Current',
          initialValue: 1000.0,
          currentValue: 1000.0,
          type: 'normal',
        ));
      }
      final freshAccounts = await _db.getAccounts();
      final selectedAccount = freshAccounts.first;

      final typeStr = data['type']?.toString().toLowerCase() ?? 'expense';
      final type = switch (typeStr) {
        'income' => TransactionType.income,
        'transfer' => TransactionType.transfer,
        _ => TransactionType.expense,
      };

      return TransactionRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        value: _parseDouble(data['value']),
        title: data['title'] ?? 'Transaction',
        notes: data['notes'] ?? '',
        type: type,
        date: DateTime.now(),
        categoryId: matchedCat.id,
        accountId: selectedAccount.id,
      );
    } catch (e) {
      debugPrint('JSON parse error: $e');
      return null;
    }
  }

  Future<void> saveTransaction() async {
    if (_transactionRecord == null) return;
    await _db.saveTransaction(_transactionRecord!);
    clearResults();
  }

  void clearResults() {
    _description = null;
    _analysisResult = null;
    _transactionRecord = null;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    notifyListeners();
  }
}
