import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../services/pdf/pdf_generation_service.dart';

class PdfPreviewScreen extends StatelessWidget {
  const PdfPreviewScreen({
    super.key,
    required this.imagePath,
  });

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final pdfService = PdfGenerationService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Preview'),
      ),
      body: PdfPreview(
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        allowPrinting: true,
        allowSharing: true,
        pdfFileName: 'document.pdf',
        build: (format) async {
          final Uint8List bytes =
              await pdfService.generatePdfBytesFromImage(
            imagePath: imagePath,
          );

          return bytes;
        },
      ),
    );
  }
}