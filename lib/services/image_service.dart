import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageService {
  static const int _maxWidth = 1024;
  static const int _maxHeight = 1024;
  static const int _quality = 85;

  final ImagePicker _picker = ImagePicker();

  Future<String?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: _maxWidth.toDouble(),
        maxHeight: _maxHeight.toDouble(),
        imageQuality: _quality,
      );
      if (image != null) return _processAndSave(image);
    } catch (e) {
      debugPrint('pickFromGallery error: $e');
    }
    return null;
  }

  Future<String?> pickFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: _maxWidth.toDouble(),
        maxHeight: _maxHeight.toDouble(),
        imageQuality: _quality,
      );
      if (image != null) return _processAndSave(image);
    } catch (e) {
      debugPrint('pickFromCamera error: $e');
    }
    return null;
  }

  Future<String?> _processAndSave(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final original = img.decodeImage(bytes);
      if (original == null) return null;

      img.Image processed = original;
      if (original.width > _maxWidth || original.height > _maxHeight) {
        processed = img.copyResize(
          original,
          width: original.width > original.height ? _maxWidth : null,
          height: original.height > original.width ? _maxHeight : null,
        );
      }

      final compressed = Uint8List.fromList(img.encodeJpg(processed, quality: _quality));
      return _saveToAppDir(compressed, p.extension(file.path));
    } catch (e) {
      debugPrint('Image processing error: $e');
      return null;
    }
  }

  Future<String> _saveToAppDir(Uint8List bytes, String ext) async {
    final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/velo_images');
    if (!await dir.exists()) await dir.create(recursive: true);
    final path = '${dir.path}/img_${DateTime.now().millisecondsSinceEpoch}$ext';
    await File(path).writeAsBytes(bytes);
    return path;
  }

  Future<Uint8List?> getBytes(String? path) async {
    if (path == null) return null;
    try {
      final file = File(path);
      return file.existsSync() ? await file.readAsBytes() : null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> delete(String? path) async {
    if (path == null) return false;
    try {
      final file = File(path);
      if (file.existsSync()) { await file.delete(); return true; }
    } catch (_) {}
    return false;
  }
}
