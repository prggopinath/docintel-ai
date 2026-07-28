import 'package:image_picker/image_picker.dart';

import '../../../services/scanner/image_picker_service.dart';
import '../../../services/ocr/text_recognition_service.dart';

class ScanController {
  final ImagePickerService _imagePickerService = ImagePickerService();
  final TextRecognitionService _textRecognitionService =
      TextRecognitionService();

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

  Future<void> dispose() async {
    await _textRecognitionService.dispose();
  }
}