import 'package:read_pdf_text/read_pdf_text.dart';

class PdfTextService {
  Future<String> extractText(String path) async {
    final text = await ReadPdfText.getPDFtext(path);

    return text.trim();
  }
}