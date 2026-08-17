import 'package:image_picker/image_picker.dart';

import '../../../shared/models/scan_result.dart';
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

  Future<ScanResult?> scanFromCamera() async {
    final XFile? image = await _imagePickerService.pickFromCamera();

    if (image == null) {
      return null;
    }

    final text = await _textRecognitionService.recognizeText(
      image.path,
    );

    return ScanResult(
      text: text,
      filePath: image.path,
      fileName: image.name,
      type: 'image',
      source: 'camera',
    );
  }

  Future<ScanResult?> scanFromGallery() async {
    final XFile? image = await _imagePickerService.pickFromGallery();

    if (image == null) {
      return null;
    }

    final text = await _textRecognitionService.recognizeText(
      image.path,
    );

    return ScanResult(
      text: text,
      filePath: image.path,
      fileName: image.name,
      type: 'image',
      source: 'gallery',
    );
  }

  Future<ScanResult?> scanFromPdf() async {
    final path = await _pdfPickerService.pickPdf();

    if (path == null) {
      return null;
    }

    final fileName = path.split('/').last;

    // First try direct text extraction.
    final extractedText = await _pdfTextService.extractText(path);

    if (extractedText.trim().isNotEmpty) {
      return ScanResult(
        text: extractedText,
        filePath: path,
        fileName: fileName,
        type: 'pdf',
        source: 'pdf',
      );
    }

    // If no embedded text exists, use scanned PDF OCR.
    final ocrText = await _pdfOcrService.extractText(path);

    return ScanResult(
      text: ocrText,
      filePath: path,
      fileName: fileName,
      type: 'pdf',
      source: 'pdf',
    );
  }

  Future<void> dispose() async {
    await _textRecognitionService.dispose();
    await _pdfOcrService.dispose();
  }

  Future<XFile?> pickImageForPdf() async {
  return await _imagePickerService.pickFromGallery();
  }
}