import 'package:image_picker/image_picker.dart';

import '../../../services/ocr/text_recognition_service.dart';
import '../../../services/pdf/pdf_ocr_service.dart';
import '../../../services/pdf/pdf_picker_service.dart';
import '../../../services/pdf/pdf_text_service.dart';
import '../../../services/scanner/image_picker_service.dart';

class ScanController {
  final ImagePickerService _imagePickerService = ImagePickerService();
  final TextRecognitionService _textRecognitionService =
      TextRecognitionService();

  final PdfPickerService _pdfPickerService = PdfPickerService();
  final PdfTextService _pdfTextService = PdfTextService();
  final PdfOcrService _pdfOcrService = PdfOcrService();

  Future<String?> scanFromCamera() async {
    final XFile? image = await _imagePickerService.pickFromCamera();

    if (image == null) {
      return null;
    }

    return await _textRecognitionService.recognizeText(image.path);
  }

  Future<String?> scanFromGallery() async {
    final XFile? image = await _imagePickerService.pickFromGallery();

    if (image == null) {
      return null;
    }

    return await _textRecognitionService.recognizeText(image.path);
  }

  Future<String?> scanFromPdf() async {
    final path = await _pdfPickerService.pickPdf();

    if (path == null) {
      return null;
    }

    // First try direct text extraction.
    final extractedText = await _pdfTextService.extractText(path);

    if (extractedText.trim().isNotEmpty) {
      return extractedText;
    }

    // If no text exists, treat the PDF as a scanned document.
    final ocrText = await _pdfOcrService.extractText(path);

    if (ocrText.trim().isEmpty) {
      return null;
    }

    return ocrText;
  }

  Future<void> dispose() async {
    await _textRecognitionService.dispose();
    await _pdfOcrService.dispose();
  }
}