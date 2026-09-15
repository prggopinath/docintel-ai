import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class OriginalDocumentPreviewScreen extends StatelessWidget {
  const OriginalDocumentPreviewScreen({
    super.key,
    required this.filePath,
    required this.fileName,
    required this.documentType,
  });

  final String filePath;
  final String fileName;
  final String documentType;

  bool get _isPdf {
    return documentType.toLowerCase() == 'pdf' ||
        filePath.toLowerCase().endsWith('.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final file = File(filePath);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.data != true) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'The original file is no longer available on this device.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (_isPdf) {
            return PdfViewPinch(
              controller: PdfControllerPinch(
                document: PdfDocument.openFile(filePath),
              ),
            );
          }

          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 5,
            child: Center(
              child: Image.file(
                file,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Unable to preview this image.',
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}