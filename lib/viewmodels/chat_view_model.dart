import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../services/model_manager.dart';
import '../services/image_service.dart';
import '../services/local_db_service.dart';

class ChatViewModel extends ChangeNotifier {
  final ModelManager _modelManager;
  final ImageService _imageService;
  final List<ChatMessage> _messages = [];
  final List<ChatSession> _sessions = [];
  ChatSession? _currentSession;
  bool _isGenerating = false;
  String? _errorMessage;
  String? _contextPrompt;
  String _assistantMode = 'standard'; // 'standard' or 'roast'

  static const String _historyKey = 'velo_chat_history';

  ChatViewModel(this._modelManager, this._imageService) {
    _loadSessions();
  }

  List<ChatMessage> get messages => _messages;
  List<ChatSession> get sessions => _sessions;
  ChatSession? get currentSession => _currentSession;
  bool get isGenerating => _isGenerating;
  String? get errorMessage => _errorMessage;
  bool get hasMessages => _messages.isNotEmpty;
  String? get contextPrompt => _contextPrompt;
  String get assistantMode => _assistantMode;

  void setContext(String context) {
    _contextPrompt = context;
    if (_messages.isEmpty) {
      _messages.add(ChatMessage.system(
        content: 'I have parsed some financial records for you. Ask me anything about them!\n\n$context',
      ));
      notifyListeners();
    }
  }

  void toggleAssistantMode(String mode) {
    _assistantMode = mode;
    notifyListeners();
  }

  void clearContext() {
    _contextPrompt = null;
    notifyListeners();
  }

  Future<void> createNewSession({String? initialTitle}) async {
    final newSession = ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: initialTitle ?? 'New Chat',
      createdAt: DateTime.now(),
    );
    _sessions.insert(0, newSession);
    _currentSession = newSession;
    _messages.clear();
    notifyListeners();
    await _saveSessionsList();
    await _saveCurrentSessionMessages();
  }

  Future<void> selectSession(String sessionId) async {
    final session = _sessions.firstWhere((s) => s.id == sessionId);
    _currentSession = session;
    await _loadCurrentSessionMessages();
  }

  Future<void> deleteSession(String sessionId) async {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index == -1) return;

    _sessions.removeAt(index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('velo_chat_session_messages_$sessionId');
    await _saveSessionsList();

    if (_currentSession?.id == sessionId) {
      if (_sessions.isNotEmpty) {
        _currentSession = _sessions.first;
        await _loadCurrentSessionMessages();
      } else {
        await createNewSession();
      }
    } else {
      notifyListeners();
    }
  }

  Future<String> _buildSystemPrompt() async {
    final accounts = await LocalDbService.instance.getAccounts();
    final recentTx = await LocalDbService.instance.getTransactions();
    final budgets = await LocalDbService.instance.getBudgets();
    
    final accountsSummary = accounts.isEmpty 
        ? "No accounts created yet."
        : accounts.map((a) => "- ${a.name} (${a.type}): ${a.currentValue} ${a.currency}").join('\n');
        
    final recentTxSummary = recentTx.isEmpty
        ? "No transaction records added yet."
        : recentTx.take(10).map((t) => "- ${t.date.toIso8601String().substring(0,10)}: ${t.title} (${t.type.name}) -> ${t.value}").join('\n');
        
    final budgetsSummary = budgets.isEmpty
        ? "No budget limits configured."
        : budgets.map((b) => "- ${b.title}: Limit ${b.limitAmount}, Spent ${b.currentAmount}").join('\n');
    
    String modePrompt = "";
    if (_assistantMode == 'roast') {
      modePrompt = "Adopt a witty, sarcastic, and sassy 'Roast Mode' personality. Lightheartedly mock the user's spending patterns or budget compliance based on their data. Keep it highly entertaining but still provide sound financial advice. Be punchy and humorous!";
    } else {
      modePrompt = "Adopt a professional, helpful, and constructive financial advisor personality. Help the user optimize their saving percentage, plan their budget, and analyze cash flow clearly.";
    }

    return """
You are Velo, a secure, privacy-first, on-device AI financial assistant. Your goal is to help users manage accounts, analyze transaction history, track active subscriptions, plan budgets, and answer personal finance questions. Keep answers concise, practical, and focused strictly on money, budgeting, and wealth. Do not answer questions outside of finance.

User's offline on-device financial records:
ACCOUNTS:
$accountsSummary

BUDGET LIMITS:
$budgetsSummary

RECENT TRANSACTIONS:
$recentTxSummary

INSTRUCTION:
$modePrompt
""";
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || _isGenerating) return;
    _errorMessage = null;

    final systemPrompt = await _buildSystemPrompt();
    final List<ChatMessage> history = [];
    history.add(ChatMessage.system(content: systemPrompt));
    history.addAll(_messages);

    final userMsg = ChatMessage.user(content: content.trim());
    _messages.add(userMsg);
    notifyListeners();

    if (_currentSession != null && _currentSession!.title == 'New Chat' && _messages.length == 1) {
      final firstMsg = content.trim();
      final words = firstMsg.split(' ');
      final title = words.take(4).join(' ') + (words.length > 4 ? '...' : '');
      _currentSession!.title = title;
      await _saveSessionsList();
    }

    _isGenerating = true;
    notifyListeners();

    try {
      final response = await _modelManager.generateResponse(
        content.trim(),
        history: history,
      );
      if (response != null) {
        _messages.add(ChatMessage.ai(content: response));
      } else {
        _setError('Failed to generate response');
      }
    } catch (e) {
      _setError('Error: $e');
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
    await _saveCurrentSessionMessages();
  }

  Future<void> sendMultimodalMessage(String content, String imagePath) async {
    if (_isGenerating) return;
    _errorMessage = null;

    final systemPrompt = await _buildSystemPrompt();
    final List<ChatMessage> history = [];
    history.add(ChatMessage.system(content: systemPrompt));
    history.addAll(_messages);

    final userMsg = ChatMessage.user(content: content.trim(), imagePath: imagePath);
    _messages.add(userMsg);
    notifyListeners();

    if (_currentSession != null && _currentSession!.title == 'New Chat' && _messages.length == 1) {
      final firstMsg = content.trim().isEmpty ? "Analyzed Document" : content.trim();
      final words = firstMsg.split(' ');
      final title = words.take(4).join(' ') + (words.length > 4 ? '...' : '');
      _currentSession!.title = title;
      await _saveSessionsList();
    }

    _isGenerating = true;
    notifyListeners();

    try {
      final bytes = await _imageService.getBytes(imagePath);
      if (bytes == null) throw Exception('Failed to read image');

      final prompt = content.trim().isEmpty
          ? 'Analyze this financial document or receipt. Extract all transactions, values, and merchant names.'
          : content.trim();

      final response = await _modelManager.generateMultimodalResponse(
        prompt, bytes,
        history: history,
      );
      if (response != null) {
        _messages.add(ChatMessage.ai(content: response));
      } else {
        _setError('Failed to generate response');
      }
    } catch (e) {
      _setError('Error: $e');
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
    await _saveCurrentSessionMessages();
  }

  Future<String?> pickImage() async {
    return await _imageService.pickFromGallery();
  }

  Future<String?> takePhoto() async {
    return await _imageService.pickFromCamera();
  }

  Future<void> clearConversation() async {
    _messages.clear();
    _errorMessage = null;
    notifyListeners();
    await _saveCurrentSessionMessages();
  }

  Future<void> _loadSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Migrate legacy single-chat history
      final oldRaw = prefs.getString(_historyKey);
      if (oldRaw != null) {
        final List<dynamic> oldList = jsonDecode(oldRaw);
        if (oldList.isNotEmpty) {
          final migratedSession = ChatSession(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: 'Saved Conversation',
            createdAt: DateTime.now(),
          );
          _sessions.add(migratedSession);
          final List<ChatMessage> migratedMessages = oldList.map((m) => ChatMessage.fromJson(m)).toList();
          _messages.addAll(migratedMessages);
          await prefs.setString('velo_chat_session_messages_${migratedSession.id}', jsonEncode(oldList));
          await _saveSessionsList();
          await prefs.remove(_historyKey);
          _currentSession = migratedSession;
          await createNewSession();
          return;
        }
        await prefs.remove(_historyKey);
      }

      final sessionsRaw = prefs.getString('velo_chat_sessions_list');
      if (sessionsRaw != null) {
        final List<dynamic> list = jsonDecode(sessionsRaw);
        _sessions.clear();
        for (final item in list) {
          _sessions.add(ChatSession.fromJson(item));
        }
      }

      if (_sessions.isEmpty) {
        await createNewSession();
      } else {
        final newestSession = _sessions.first;
        final newestKey = 'velo_chat_session_messages_${newestSession.id}';
        final newestRaw = prefs.getString(newestKey);
        final hasMessages = newestRaw != null && newestRaw != '[]' && newestRaw.isNotEmpty;

        if (!hasMessages) {
          _currentSession = newestSession;
          _messages.clear();
          notifyListeners();
        } else {
          await createNewSession();
        }
      }
    } catch (_) {}
  }

  Future<void> _saveSessionsList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _sessions.map((s) => s.toJson()).toList();
      await prefs.setString('velo_chat_sessions_list', jsonEncode(list));
    } catch (_) {}
  }

  Future<void> _saveCurrentSessionMessages() async {
    if (_currentSession == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _messages.map((m) => m.toJson()).toList();
      await prefs.setString('velo_chat_session_messages_${_currentSession!.id}', jsonEncode(list));
    } catch (_) {}
  }

  Future<void> _loadCurrentSessionMessages() async {
    if (_currentSession == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('velo_chat_session_messages_${_currentSession!.id}');
      _messages.clear();
      if (raw != null) {
        final List<dynamic> list = jsonDecode(raw);
        for (final item in list) {
          _messages.add(ChatMessage.fromJson(item));
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  void _setError(String msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
