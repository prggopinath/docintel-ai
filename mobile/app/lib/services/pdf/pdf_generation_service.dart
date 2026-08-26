import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfGenerationService {
  Future<File> createPdfFromImage({
    required String imagePath,
    required String outputPath,
  }) async {
    final imageFile = File(imagePath);
    final imageBytes = await imageFile.readAsBytes();

    final document = pw.Document();

    final image = pw.MemoryImage(imageBytes);

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return pw.Center(
            child: pw.Image(
              image,
              fit: pw.BoxFit.contain,
            ),
          );
        },
      ),
    );

    final outputFile = File(outputPath);

    await outputFile.writeAsBytes(
      await document.save(),
    );

    return outputFile;
  }

  Future<Uint8List> generatePdfBytesFromImages({
    required List<String> imagePaths,
  }) async {
    final document = pw.Document();

    for (final imagePath in imagePaths) {
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();

      final image = pw.MemoryImage(imageBytes);

      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (context) {
            return pw.Center(
              child: pw.Image(
                image,
                fit: pw.BoxFit.contain,
              ),
            );
          },
        ),
      );
    }

    return document.save();
  }

  Future<Uint8List> generatePdfBytesFromImage({
    required String imagePath,
  }) async {
    final imageFile = File(imagePath);
    final imageBytes = await imageFile.readAsBytes();

    final document = pw.Document();

    final image = pw.MemoryImage(imageBytes);

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return pw.Center(
            child: pw.Image(
              image,
              fit: pw.BoxFit.contain,
            ),
          );
        },
      ),
    );

    return document.save();
  }
}