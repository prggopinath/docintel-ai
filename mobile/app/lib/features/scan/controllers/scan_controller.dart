import 'package:image_picker/image_picker.dart';

import '../../../services/pdf/pdf_picker_service.dart';
import '../../../services/pdf/pdf_text_service.dart';
import '../../../services/scanner/image_picker_service.dart';
import '../../../services/ocr/text_recognition_service.dart';

class ScanController {
  final ImagePickerService _imagePickerService = ImagePickerService();
  final TextRecognitionService _textRecognitionService =
      TextRecognitionService();

  final PdfPickerService _pdfPickerService = PdfPickerService();
  final PdfTextService _pdfTextService = PdfTextService();

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

    final text = await _pdfTextService.extractText(path);

    if (text.trim().isEmpty) {
      return null;
    }

    return text;
  }

  Future<void> dispose() async {
    await _textRecognitionService.dispose();
  }
}