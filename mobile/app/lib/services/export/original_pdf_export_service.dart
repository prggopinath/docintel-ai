import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class OriginalPdfExportService {
  Future<Uint8List> createFromImage(String imagePath) async {
    final imageBytes = await File(imagePath).readAsBytes();
    final image = pw.MemoryImage(imageBytes);

    final document = pw.Document();

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(12),
        build: (context) {
          return pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain));
        },
      ),
    );

    return document.save();
  }

  Future<Uint8List> createFromText({
    required String text,
    required String title,
  }) async {
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text(title)),
          pw.Paragraph(text: text),
        ],
      ),
    );

    return document.save();
  }
}
