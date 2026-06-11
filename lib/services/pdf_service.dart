import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

class PdfService {
  static final PdfService instance = PdfService._();
  PdfService._();

  /// Extract text from a text-based PDF using Syncfusion PDF library.
  Future<String> extractText(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return '';
      
      final bytes = await file.readAsBytes();
      final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
      final sf.PdfTextExtractor extractor = sf.PdfTextExtractor(document);
      final String text = extractor.extractText();
      document.dispose();
      
      return text.trim();
    } catch (e) {
      return 'Error extracting text from PDF: $e';
    }
  }
}
