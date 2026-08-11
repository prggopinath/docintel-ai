import 'dart:io';

import 'pdf_page_renderer_service.dart';
import '../ocr/text_recognition_service.dart';

class PdfOcrService {
  final PdfPageRendererService _renderer = PdfPageRendererService();
  final TextRecognitionService _textRecognitionService =
      TextRecognitionService();

  Future<String> extractText(String pdfPath) async {
    final pageImages = await _renderer.renderPages(pdfPath);

    if (pageImages.isEmpty) {
      return '';
    }

    final tempDirectory = await Directory.systemTemp.createTemp(
      'docurator_pdf_ocr_',
    );

    final StringBuffer extractedText = StringBuffer();

    try {
      for (int i = 0; i < pageImages.length; i++) {
        final imageFile = File(
          '${tempDirectory.path}/page_${i + 1}.png',
        );

        await imageFile.writeAsBytes(pageImages[i]);

        final text = await _textRecognitionService.recognizeText(
          imageFile.path,
        );

        if (text.trim().isNotEmpty) {
          extractedText.writeln(text);
        }
      }

      return extractedText.toString().trim();
    } finally {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    }
  }

  Future<void> dispose() async {
    await _textRecognitionService.dispose();
  }
}