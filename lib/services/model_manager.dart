import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart' hide DownloadProgress, Message, MessageType;
import 'package:flutter_gemma/core/message.dart' as gemma_message;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/model_status.dart';
import '../models/chat_message.dart';

class ModelManager extends ChangeNotifier {
  ModelStatus _status = ModelStatus.notDownloaded;
  DownloadProgress _downloadProgress = DownloadProgress.initial();
  String? _errorMessage;
  InferenceModel? _inferenceModel;
  InferenceChat? _chat;
  bool _supportsImages = false;
  
  // Updated to use Gemma 4 E2B IT model with multimodal capabilities
  final ModelInfo _modelInfo = const ModelInfo(
    name: 'Gemma 4 E2B IT (LiteRT-LM)',
    version: 'E2B-IT-LiteRT-LM',
    sizeInBytes: 2780000000, // ~2.59GB for the litertlm model
    downloadUrl: 'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm',
    description: 'Gemma 4 E2B Instruction-Tuned model with multimodal capabilities (text + image) optimized for on-device mobile and desktop platforms via LiteRT-LM',
  );

  // Better model configuration based on Gemma 4 E2B LiteRT-LM
  static const String _modelUrl = 'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm';
  String _modelFilename = 'gemma-4-E2B-it.litertlm';
  static const String _skipSetupKey = 'velo_skip_model_setup';
  static const String _tokenKey = 'hf_token';
  bool _setupSkipped = false;
  String? _modelPathOverride;
  bool get setupSkipped => _setupSkipped;

  // Getters
  ModelStatus get status => _status;
  DownloadProgress get downloadProgress => _downloadProgress;
  String? get errorMessage => _errorMessage;
  ModelInfo get modelInfo => _modelInfo;
  bool get isReady => _status == ModelStatus.ready;
  bool get isDownloading => _status == ModelStatus.downloading;
  bool get needsDownload => _status == ModelStatus.notDownloaded;
  bool get supportsImages => _supportsImages;

  void skipSetup() {
    _setupSkipped = true;
    notifyListeners();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool(_skipSetupKey, true);
    });
  }

  void resetSkipSetup() {
    _setupSkipped = false;
    notifyListeners();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool(_skipSetupKey, false);
    });
  }

  ModelManager({bool initialSetupSkipped = false}) {
    _setupSkipped = initialSetupSkipped;
    SharedPreferences.getInstance().then((prefs) {
      _setupSkipped = prefs.getBool(_skipSetupKey) ?? false;
      notifyListeners();
    });
    _checkModelStatus();
  }

  Future<void> _checkModelStatus() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final extDir = await getExternalStorageDirectory();
      
      final gemma4File = File('${directory.path}/gemma-4-E2B-it.litertlm');
      final gemma3File = File('${directory.path}/gemma-3n-E2B-it-int4.litertlm');

      if (gemma4File.existsSync()) {
        if (kDebugMode) print('Model found in private storage: ${gemma4File.path}');
        _modelFilename = 'gemma-4-E2B-it.litertlm';
        _modelPathOverride = gemma4File.path;
        _supportsImages = true;
        _status = ModelStatus.downloadComplete;
        notifyListeners();
        await _initializeModel();
        return;
      }

      if (extDir != null) {
        final extGemma4 = File('${extDir.path}/gemma-4-E2B-it.litertlm');
        if (extGemma4.existsSync()) {
          if (kDebugMode) print('Model found in external package storage: ${extGemma4.path}');
          _modelFilename = 'gemma-4-E2B-it.litertlm';
          _modelPathOverride = extGemma4.path;
          _supportsImages = true;
          _status = ModelStatus.downloadComplete;
          notifyListeners();
          await _initializeModel();
          return;
        }
      }

      if (gemma3File.existsSync()) {
        if (kDebugMode) print('Model found in private storage: ${gemma3File.path}');
        _modelFilename = 'gemma-3n-E2B-it-int4.litertlm';
        _modelPathOverride = gemma3File.path;
        _supportsImages = true;
        _status = ModelStatus.downloadComplete;
        notifyListeners();
        await _initializeModel();
        return;
      }

      if (extDir != null) {
        final extGemma3 = File('${extDir.path}/gemma-3n-E2B-it-int4.litertlm');
        if (extGemma3.existsSync()) {
          if (kDebugMode) print('Model found in external package storage: ${extGemma3.path}');
          _modelFilename = 'gemma-3n-E2B-it-int4.litertlm';
          _modelPathOverride = extGemma3.path;
          _supportsImages = true;
          _status = ModelStatus.downloadComplete;
          notifyListeners();
          await _initializeModel();
          return;
        }
      }

      // Check public Downloads folder as a convenience path
      final movedGemma4 = await _checkAndMoveFromDownloads(
        '/storage/emulated/0/Download/gemma-4-E2B-it.litertlm',
        '${directory.path}/gemma-4-E2B-it.litertlm'
      );
      if (movedGemma4) {
        if (kDebugMode) print('Gemma 4 model moved from Downloads to private storage');
        _modelFilename = 'gemma-4-E2B-it.litertlm';
        _modelPathOverride = '${directory.path}/gemma-4-E2B-it.litertlm';
        _supportsImages = true;
        _status = ModelStatus.downloadComplete;
        notifyListeners();
        await _initializeModel();
        return;
      }

      final movedGemma3 = await _checkAndMoveFromDownloads(
        '/storage/emulated/0/Download/gemma-3n-E2B-it-int4.litertlm',
        '${directory.path}/gemma-3n-E2B-it-int4.litertlm'
      );
      if (movedGemma3) {
        if (kDebugMode) print('Gemma 3N model moved from Downloads to private storage');
        _modelFilename = 'gemma-3n-E2B-it-int4.litertlm';
        _modelPathOverride = '${directory.path}/gemma-3n-E2B-it-int4.litertlm';
        _supportsImages = true;
        _status = ModelStatus.downloadComplete;
        notifyListeners();
        await _initializeModel();
        return;
      }

      _status = ModelStatus.notDownloaded;
      notifyListeners();
    } catch (e) {
      _setError('Failed to check model status: $e');
      if (kDebugMode) print('Model status check error: $e');
    }
  }

  /// Checks if the model was manually placed in the phone's Downloads folder.
  /// If found, copies it to private app storage so the app can use it.
  Future<bool> _checkAndMoveFromDownloads(String sourcePath, String destinationPath) async {
    try {
      final downloadsFile = File(sourcePath);
      if (downloadsFile.existsSync()) {
        final size = await downloadsFile.length();
        if (size < 100000) return false; // Ignore tiny/incomplete files

        if (kDebugMode) print('Found model in Downloads: $sourcePath. Copying to private storage...');
        _status = ModelStatus.downloading; // Show activity during copy
        notifyListeners();

        await downloadsFile.copy(destinationPath);
        return true;
      }
    } catch (e) {
      if (kDebugMode) print('Error checking Downloads folder: $e');
    }
    return false;
  }

  ModelType get _currentModelType {
    final name = _modelFilename.toLowerCase();
    if (name.contains('gemma-4') || name.contains('gemma4')) {
      return ModelType.gemma4;
    }
    return ModelType.gemmaIt;
  }

  Future<String> _getModelFilePath() async {
    if (_modelPathOverride != null) {
      return _modelPathOverride!;
    }
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_modelFilename';
  }

  Future<String?> getAuthToken() async {
    // First try to get token from environment variables
    try {
      final envToken = dotenv.env['HF_TOKEN'];
      if (envToken != null && envToken.isNotEmpty) {
        if (kDebugMode) {
          print('Using HF_TOKEN from environment variables');
        }
        return envToken;
      }
    } catch (_) {
      if (kDebugMode) {
        print('dotenv is not initialized or HF_TOKEN is missing');
      }
    }
    
    // Fall back to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_tokenKey);
    if (kDebugMode) {
      print('Using token from SharedPreferences: ${savedToken != null ? 'found' : 'not found'}');
    }
    return savedToken;
  }

  Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<bool> checkModelExists() async {
    try {
      final filePath = await _getModelFilePath();
      final file = File(filePath);
      
      if (!file.existsSync()) return false;
      
      // Check if file size matches expected (basic validation)
      final fileSize = await file.length();
      return fileSize > 100000; // At least 100KB to be considered valid
    } catch (e) {
      if (kDebugMode) {
        print('Error checking model existence: $e');
      }
      return false;
    }
  }

  Future<void> downloadModel({String? authToken}) async {
    if (_status == ModelStatus.downloading) return;

    resetSkipSetup();

    try {
      _status = ModelStatus.downloading;
      _downloadProgress = DownloadProgress.initial();
      _errorMessage = null;
      notifyListeners();

      // Check if model already exists
      if (await checkModelExists()) {
        _status = ModelStatus.downloadComplete;
        notifyListeners();
        await _initializeModel();
        return;
      }

      // Use provided token or get saved token
      final token = authToken ?? await getAuthToken();
      
      if (token == null || token.isEmpty) {
        throw Exception(
          'Hugging Face authentication token is required. '
          'Please provide your Hugging Face token to download the model.\n\n'
          'You can get a token from: https://huggingface.co/settings/tokens'
        );
      }

      await _downloadModelFile(token);
      
      _status = ModelStatus.downloadComplete;
      notifyListeners();
      
      await _initializeModel();
    } catch (e) {
      _setError('Failed to download model: $e');
      if (kDebugMode) {
        print('Model download error: $e');
      }
    }
  }

  Future<void> _downloadModelFile(String token) async {
    http.StreamedResponse? response;
    IOSink? fileSink;

    try {
      final filePath = await _getModelFilePath();
      final file = File(filePath);

      // Check if file already exists and get partial download size
      int downloadedBytes = 0;
      if (file.existsSync()) {
        downloadedBytes = await file.length();
      }

      // Create HTTP request with authentication
      final request = http.Request('GET', Uri.parse(_modelUrl));
      request.headers['Authorization'] = 'Bearer $token';
      
      // Resume download if partially downloaded
      if (downloadedBytes > 0) {
        request.headers['Range'] = 'bytes=$downloadedBytes-';
      }

      // Send request
      response = await request.send();
      
      if (response.statusCode == 200 || response.statusCode == 206) {
        final contentLength = response.contentLength ?? 0;
        final totalBytes = downloadedBytes + contentLength;
        fileSink = file.openWrite(mode: FileMode.append);

        int received = downloadedBytes;

        // Download with progress tracking
        await for (final chunk in response.stream) {
          fileSink.add(chunk);
          received += chunk.length;

          // Update progress
          final progress = totalBytes > 0 ? received / totalBytes : 0.0;
          _downloadProgress = DownloadProgress(
            bytesDownloaded: received,
            totalBytes: totalBytes,
            percentage: progress * 100,
          );
          notifyListeners();
        }
      } else {
        // Handle different error codes
        String errorMessage = 'Download failed with status ${response.statusCode}';
        
        if (response.statusCode == 401) {
          errorMessage = 'Authentication failed. Please check your Hugging Face token and ensure it has the correct permissions.';
        } else if (response.statusCode == 403) {
          errorMessage = 'Access denied. Please ensure your token has read access to the repository.';
        } else if (response.statusCode == 404) {
          errorMessage = 'Model file not found. The model URL may be incorrect.';
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error downloading model: $e');
      }
      rethrow;
    } finally {
      if (fileSink != null) {
        await fileSink.close();
      }
    }
  }

  Future<void> _initializeModel() async {
    try {
      _status = ModelStatus.initializing;
      notifyListeners();

      // Register the model file with flutter_gemma
      final filePath = await _getModelFilePath();
      final modelType = _currentModelType;
      
      if (kDebugMode) {
        print('Installing model with type: $modelType');
      }

      await FlutterGemma.installModel(
        modelType: modelType,
        fileType: ModelFileType.litertlm,
      )
        .fromFile(filePath)
        .install();
      
      // Create the inference model with multimodal support
      _inferenceModel = await FlutterGemma.getActiveModel(
        maxTokens: 4096,
        preferredBackend: PreferredBackend.gpu,
        supportImage: _supportsImages,
        maxNumImages: _supportsImages ? 1 : 0,
      );

      // Create a chat instance for conversation management with image support
      _chat = await _inferenceModel!.createChat(
        temperature: 0.8,
        topK: 40,
        supportImage: _supportsImages,
      );

      _status = ModelStatus.ready;
      _errorMessage = null;
      notifyListeners();
      
      if (kDebugMode) {
        print('Model initialized successfully');
      }
    } catch (e) {
      _setError('Failed to initialize model: $e');
      if (kDebugMode) {
        print('Model initialization error: $e');
      }
    }
  }

  Future<List<gemma_message.Message>> _convertToGemmaMessages(List<ChatMessage> history) async {
    final List<gemma_message.Message> converted = [];
    for (final msg in history) {
      final isUser = msg.type == MessageType.user;
      
      if (msg.hasImage && msg.imagePath != null) {
        try {
          final file = File(msg.imagePath!);
          if (file.existsSync()) {
            final bytes = await file.readAsBytes();
            converted.add(gemma_message.Message.withImage(
              text: msg.content,
              imageBytes: bytes,
              isUser: isUser,
            ));
            continue;
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error reading image bytes for history replay: $e');
          }
        }
      }
      
      converted.add(gemma_message.Message.text(
        text: msg.content,
        isUser: isUser,
      ));
    }
    return converted;
  }

  Future<String?> generateResponse(String prompt, {List<ChatMessage> history = const []}) async {
    if (_status != ModelStatus.ready || _chat == null) {
      throw Exception('Model is not ready. Current status: $_status');
    }

    try {
      if (kDebugMode) {
        print('[ModelManager] Replaying conversation history of length: ${history.length}');
      }
      
      // Convert history to gemma messages
      final gemmaHistory = await _convertToGemmaMessages(history);
      
      // Recreate the native session and seed it with the history to bypass persistent context locks
      await _chat!.clearHistory(replayHistory: gemmaHistory);

      // Create a message using the flutter_gemma Message class
      final message = gemma_message.Message.text(
        text: prompt,
        isUser: true,
      );

      // Add the message to the chat
      await _chat!.addQueryChunk(message);

      // Generate and return the response
      final modelResponse = await _chat!.generateChatResponse();
      final response = _extractText(modelResponse);
      
      if (kDebugMode) {
        print('Generated response: $response');
      }
      
      return response;
    } catch (e) {
      _setError('Failed to generate response: $e');
      if (kDebugMode) {
        print('Response generation error: $e');
      }
      return null;
    }
  }

  /// Generate response for multimodal input (text + image)
  Future<String?> generateMultimodalResponse(
    String prompt,
    Uint8List imageBytes, {
    List<ChatMessage> history = const [],
  }) async {
    if (_status != ModelStatus.ready || _chat == null) {
      throw Exception('Model is not ready. Current status: $_status');
    }

    try {
      if (kDebugMode) {
        print('[ModelManager] Replaying multimodal conversation history of length: ${history.length}');
      }

      // Convert history to gemma messages
      final gemmaHistory = await _convertToGemmaMessages(history);

      // Recreate the native session and seed it with the history to bypass persistent context locks
      await _chat!.clearHistory(replayHistory: gemmaHistory);

      // Create a multimodal message using the flutter_gemma Message class
      final message = gemma_message.Message.withImage(
        text: prompt,
        imageBytes: imageBytes,
        isUser: true,
      );

      // Add the message to the chat
      await _chat!.addQueryChunk(message);

      // Generate and return the response
      final modelResponse = await _chat!.generateChatResponse();
      final response = _extractText(modelResponse);
      
      if (kDebugMode) {
        print('Generated multimodal response: $response');
      }
      
      return response;
    } catch (e) {
      _setError('Failed to generate multimodal response: $e');
      if (kDebugMode) {
        print('Multimodal response generation error: $e');
      }
      return null;
    }
  }

  Future<void> clearModel() async {
    try {
      // Close existing model and chat instances
      if (_chat != null) {
        _chat = null;
      }
      
      if (_inferenceModel != null) {
        await _inferenceModel!.close();
        _inferenceModel = null;
      }
      
      // Delete the model file
      final filePath = await _getModelFilePath();
      final file = File(filePath);
      if (file.existsSync()) {
        await file.delete();
      }
      
      _status = ModelStatus.notDownloaded;
      _downloadProgress = DownloadProgress.initial();
      _errorMessage = null;
      notifyListeners();
      
      if (kDebugMode) {
        print('Model cleared successfully');
      }
    } catch (e) {
      _setError('Failed to clear model: $e');
      if (kDebugMode) {
        print('Model clear error: $e');
      }
    }
  }

  String? _extractText(ModelResponse modelResponse) {
    if (modelResponse is TextResponse) {
      return modelResponse.token;
    } else if (modelResponse is ThinkingResponse) {
      return modelResponse.content;
    }
    return modelResponse.toString();
  }

  void _setError(String message) {
    _status = ModelStatus.error;
    _errorMessage = message;
    _downloadProgress = DownloadProgress.error(message);
    notifyListeners();
    
    if (kDebugMode) {
      print('ModelManager Error: $message');
    }
  }

  void clearError() {
    _errorMessage = null;
    if (_status == ModelStatus.error) {
      _status = ModelStatus.notDownloaded;
    }
    notifyListeners();
  }
}
