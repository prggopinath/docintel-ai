import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class TextPdfExportService {
  Future<Uint8List> createPdf({
    required String text,
    required String title,
  }) async {
    final document = pw.Document();

    final lines = text.split('\n');

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 20),

            pw.Text(
              'Extracted Text',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 12),

            ...lines.map(
              (line) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Text(
                  line,
                  style: const pw.TextStyle(
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ];
        },
      ),
    );

    return document.save();
  }
}