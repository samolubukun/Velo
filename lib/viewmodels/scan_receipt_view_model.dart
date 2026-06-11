import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/transaction_record.dart';
import '../services/model_manager.dart';
import '../services/image_service.dart';
import '../services/local_db_service.dart';
import '../services/pdf_service.dart';

class ScanReceiptViewModel extends ChangeNotifier {
  final ModelManager _modelManager;
  final ImageService _imageService;
  final LocalDbService _db;
  final PdfService _pdfService = PdfService.instance;

  File? _imageFile;
  File? _pdfFile;
  bool _isAnalyzing = false;
  bool _isPdfMode = false;

  TransactionRecord? _parsedTransaction; // for single receipt scan
  List<TransactionRecord> _parsedTransactions = []; // for bulk PDF statement entries
  String? _errorMessage;

  ScanReceiptViewModel(this._modelManager, this._imageService, this._db);

  File? get imageFile => _imageFile;
  File? get pdfFile => _pdfFile;
  bool get isAnalyzing => _isAnalyzing;
  bool get isPdfMode => _isPdfMode;
  bool get hasImage => _imageFile != null;
  bool get hasPdf => _pdfFile != null;
  bool get hasResult => _parsedTransaction != null || _parsedTransactions.isNotEmpty;
  TransactionRecord? get parsedTransaction => _parsedTransaction;
  List<TransactionRecord> get parsedTransactions => _parsedTransactions;
  String? get errorMessage => _errorMessage;

  void toggleMode(bool isPdf) {
    _isPdfMode = isPdf;
    clearAll();
  }

  Future<void> pickImage() async {
    final path = await _imageService.pickFromGallery();
    if (path != null) {
      _imageFile = File(path);
      _pdfFile = null;
      _parsedTransaction = null;
      _parsedTransactions.clear();
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<void> takePhoto() async {
    final path = await _imageService.pickFromCamera();
    if (path != null) {
      _imageFile = File(path);
      _pdfFile = null;
      _parsedTransaction = null;
      _parsedTransactions.clear();
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<void> selectPdf(String path) async {
    _pdfFile = File(path);
    _imageFile = null;
    _parsedTransaction = null;
    _parsedTransactions.clear();
    _errorMessage = null;
    notifyListeners();
    await analyzePdf();
  }

  Future<void> analyzeImage() async {
    if (_imageFile == null || _isAnalyzing) return;
    _isAnalyzing = true;
    _errorMessage = null;
    _parsedTransaction = null;
    notifyListeners();

    try {
      final bytes = await _imageFile!.readAsBytes();
      const prompt = '''
Analyze this receipt image. Extract and return ONLY valid JSON with this exact structure:
{
  "merchant": "Merchant Name",
  "amount": 12.34,
  "date": "YYYY-MM-DD",
  "notes": "Extracted items summary or notes"
}
If date is not readable, default to the current date. Return ONLY valid raw JSON. Do not write markdown, code blocks, or explanations.''';

      final response = await _modelManager.generateMultimodalResponse(prompt, bytes);
      if (response != null) {
        final tx = await _parseSingleReceiptJson(response);
        if (tx != null) {
          _parsedTransaction = tx;
        } else {
          _setError('Could not extract receipt details. Make sure the receipt values and merchant name are clearly visible.');
        }
      } else {
        _setError('OCR parsing failed. Ensure the local AI model is downloaded and running.');
      }
    } catch (e) {
      _setError('Error analyzing receipt: $e');
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  Future<void> analyzePdf() async {
    if (_pdfFile == null || _isAnalyzing) return;
    _isAnalyzing = true;
    _errorMessage = null;
    _parsedTransactions.clear();
    notifyListeners();

    try {
      final text = await _pdfService.extractText(_pdfFile!.path);
      if (text.isEmpty || text.startsWith('Error')) {
        throw Exception(text.isEmpty ? 'No readable text found in PDF.' : text);
      }

      // Keep context small by taking first 6000 characters of text
      final safeText = text.length > 6000 ? text.substring(0, 6000) : text;

      final prompt = '''
You are a bank statement parser. Extract all transaction items from the following statement. Output ONLY a valid JSON array of transaction objects:
[
  {
    "date": "YYYY-MM-DD",
    "title": "Merchant / description",
    "value": 12.34,
    "type": "expense"
  }
]
Return ONLY the raw JSON list. No explanation, notes or preamble.
Statement:
$safeText''';

      final response = await _modelManager.generateResponse(prompt);
      if (response != null) {
        final list = await _parseBulkTransactionsJson(response);
        if (list.isNotEmpty) {
          _parsedTransactions = list;
        } else {
          _setError('No transactions parsed from PDF statement. Confirm the file format.');
        }
      } else {
        _setError('PDF analysis failed. Ensure the local AI model is loaded.');
      }
    } catch (e) {
      _setError('Error parsing PDF statement: $e');
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

  Future<TransactionRecord?> _parseSingleReceiptJson(String raw) async {
    try {
      String json = raw.trim();
      final start = json.indexOf('{');
      final end = json.lastIndexOf('}');
      if (start != -1 && end != -1 && end > start) {
        json = json.substring(start, end + 1);
      }
      final data = jsonDecode(json) as Map<String, dynamic>;

      final accounts = await _db.getAccounts();
      if (accounts.isEmpty) return null;
      final defaultAccount = accounts.first;

      final categories = await _db.getCategories();
      final defaultCategory = categories.firstWhere((c) => c.id == 'cat_food', orElse: () => categories.first);

      DateTime txDate = DateTime.now();
      if (data['date'] != null) {
        try {
          txDate = DateTime.parse(data['date'].toString());
        } catch (_) {}
      }

      return TransactionRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        value: _parseDouble(data['amount']),
        title: data['merchant'] ?? 'Receipt Purchase',
        notes: data['notes'] ?? 'Scanned receipt image',
        type: TransactionType.expense,
        date: txDate,
        categoryId: defaultCategory.id,
        accountId: defaultAccount.id,
        imagePath: _imageFile?.path ?? '',
      );
    } catch (e) {
      debugPrint('Error parsing receipt JSON: $e');
      return null;
    }
  }

  Future<List<TransactionRecord>> _parseBulkTransactionsJson(String raw) async {
    try {
      String json = raw.trim();
      final start = json.indexOf('[');
      final end = json.lastIndexOf(']');
      if (start != -1 && end != -1 && end > start) {
        json = json.substring(start, end + 1);
      }
      final List<dynamic> dataList = jsonDecode(json);

      final accounts = await _db.getAccounts();
      if (accounts.isEmpty) return [];
      final defaultAccount = accounts.first;

      final categories = await _db.getCategories();
      final otherCategory = categories.firstWhere((c) => c.id == 'cat_other', orElse: () => categories.first);

      final List<TransactionRecord> records = [];
      int offset = 0;
      for (final item in dataList) {
        DateTime txDate = DateTime.now();
        if (item['date'] != null) {
          try {
            txDate = DateTime.parse(item['date'].toString());
          } catch (_) {}
        }

        final typeStr = item['type']?.toString().toLowerCase() ?? 'expense';
        final type = typeStr == 'income' ? TransactionType.income : TransactionType.expense;

        // basic semantic category heuristic based on merchant name
        final title = item['title'] ?? 'Bank Transaction';
        var catId = otherCategory.id;
        for (final c in categories) {
          if (title.toString().toLowerCase().contains(c.name.split(' ')[0].toLowerCase())) {
            catId = c.id;
            break;
          }
        }

        records.add(TransactionRecord(
          id: '${DateTime.now().microsecondsSinceEpoch}_$offset',
          value: _parseDouble(item['value']).abs(),
          title: title,
          notes: 'Imported from bank statement PDF',
          type: type,
          date: txDate,
          categoryId: catId,
          accountId: defaultAccount.id,
        ));
        offset++;
      }
      return records;
    } catch (e) {
      debugPrint('Error parsing bulk PDF JSON: $e');
      return [];
    }
  }

  Future<void> saveSingleReceipt(String accountId, String categoryId, String title, double amount) async {
    if (_parsedTransaction == null) return;
    
    final finalTx = _parsedTransaction!.copyWith(
      accountId: accountId,
      categoryId: categoryId,
      title: title,
      value: amount,
      date: DateTime.now(),
    );

    await _db.saveTransaction(finalTx);
    clearAll();
  }

  Future<void> saveBulkTransactions(String accountId) async {
    if (_parsedTransactions.isEmpty) return;

    for (final tx in _parsedTransactions) {
      final finalTx = tx.copyWith(accountId: accountId);
      await _db.saveTransaction(finalTx);
    }
    clearAll();
  }

  void updateBulkTransactionCategory(int index, String categoryId) {
    if (index >= 0 && index < _parsedTransactions.length) {
      _parsedTransactions[index] = _parsedTransactions[index].copyWith(categoryId: categoryId);
      notifyListeners();
    }
  }

  void clearAll() {
    _imageFile = null;
    _pdfFile = null;
    _parsedTransaction = null;
    _parsedTransactions.clear();
    _errorMessage = null;
    _isAnalyzing = false;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    notifyListeners();
  }
}
