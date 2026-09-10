import 'package:image_picker/image_picker.dart';

import '../../../shared/models/scan_result.dart';
import '../../../services/ocr/text_recognition_service.dart';
import '../../../services/pdf/pdf_ocr_service.dart';
import '../../../services/pdf/pdf_picker_service.dart';
import '../../../services/pdf/pdf_text_service.dart';
import '../../../services/scanner/image_picker_service.dart';

class ScanController {
  final ImagePickerService _imagePickerService =
      ImagePickerService();

  final TextRecognitionService _textRecognitionService =
      TextRecognitionService();

  final PdfPickerService _pdfPickerService =
      PdfPickerService();

  final PdfTextService _pdfTextService =
      PdfTextService();

  final PdfOcrService _pdfOcrService =
      PdfOcrService();

  Future<XFile?> pickImageFromCamera() async {
    return await _imagePickerService.pickFromCamera();
  }

  Future<XFile?> pickImageFromGallery() async {
    return await _imagePickerService.pickFromGallery();
  }

  Future<ScanResult> scanImage({
    required String path,
    required String fileName,
    required String source,
    required String documentType,
  }) async {
    final text = await _textRecognitionService.recognizeText(path);

    return ScanResult(
      text: text,
      filePath: path,
      fileName: fileName,
      type: 'image',
      source: source,
      documentType: documentType,
    );
  }

  // Kept for compatibility with any existing callers.
  Future<ScanResult?> scanFromCamera({
    required String documentType,
  }) async {
    final XFile? image =
        await _imagePickerService.pickFromCamera();

    if (image == null) {
      return null;
    }

    return scanImage(
      path: image.path,
      fileName: image.name,
      source: 'camera',
      documentType: documentType,
    );
  }

  // Kept for compatibility with any existing callers.
  Future<ScanResult?> scanFromGallery({
    required String documentType,
  }) async {
    final XFile? image =
        await _imagePickerService.pickFromGallery();

    if (image == null) {
      return null;
    }

    return scanImage(
      path: image.path,
      fileName: image.name,
      source: 'gallery',
      documentType: documentType,
    );
  }

  Future<ScanResult?> scanFromPdf({
    String documentType = 'Other',
  }) async {
    final path = await _pdfPickerService.pickPdf();

    if (path == null) {
      return null;
    }

    final fileName = path.split('/').last;

    // First try direct text extraction.
    final extractedText =
        await _pdfTextService.extractText(path);

    if (extractedText.trim().isNotEmpty) {
      return ScanResult(
        text: extractedText,
        filePath: path,
        fileName: fileName,
        type: 'pdf',
        source: 'pdf',
        documentType: documentType,
      );
    }

    // If no embedded text exists, use scanned PDF OCR.
    final ocrText =
        await _pdfOcrService.extractText(path);

    return ScanResult(
      text: ocrText,
      filePath: path,
      fileName: fileName,
      type: 'pdf',
      source: 'pdf',
      documentType: documentType,
    );
  }

  Future<void> dispose() async {
    await _textRecognitionService.dispose();
    await _pdfOcrService.dispose();
  }

  Future<XFile?> pickImageForPdfFromGallery() async {
    return await _imagePickerService.pickFromGallery();
  }

  Future<XFile?> pickImageForPdfFromCamera() async {
    return await _imagePickerService.pickFromCamera();
  }
}