import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../services/pdf/pdf_export_service.dart';
import '../../../services/pdf/pdf_generation_service.dart';

class PdfPreviewScreen extends StatefulWidget {
  const PdfPreviewScreen({
    super.key,
    required this.imagePath,
  });

  final String imagePath;

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  final PdfGenerationService _pdfGenerationService =
      PdfGenerationService();

  final PdfExportService _pdfExportService =
      PdfExportService();

  Uint8List? _pdfBytes;
  bool _isLoading = true;
  bool _isExporting = false;

  final String _fileName =
      'document_${DateTime.now().millisecondsSinceEpoch}.pdf';

  @override
  void initState() {
    super.initState();
    _generatePdf();
  }

  Future<void> _generatePdf() async {
    try {
      final bytes =
          await _pdfGenerationService.generatePdfBytesFromImage(
        imagePath: widget.imagePath,
      );

      if (!mounted) return;

      setState(() {
        _pdfBytes = bytes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to generate PDF: $e'),
        ),
      );
    }
  }

  Future<void> _savePdf() async {
    if (_pdfBytes == null) return;

    setState(() {
      _isExporting = true;
    });

    try {
      final saved = await _pdfExportService.savePdf(
        bytes: _pdfBytes!,
        fileName: _fileName,
      );

      if (!mounted) return;

      if (saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF saved successfully.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to save PDF: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _sharePdf() async {
    if (_pdfBytes == null) return;

    setState(() {
      _isExporting = true;
    });

    try {
      await _pdfExportService.sharePdf(
        bytes: _pdfBytes!,
        fileName: _fileName,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to share PDF: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Preview'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _pdfBytes == null
              ? const Center(
                  child: Text('Unable to generate PDF preview.'),
                )
              : Column(
                  children: [
                    Expanded(
                      child: PdfPreview(
                        canChangePageFormat: false,
                        canChangeOrientation: false,
                        canDebug: false,
                        allowPrinting: true,
                        allowSharing: false,
                        pdfFileName: _fileName,
                        build: (format) async => _pdfBytes!,
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isExporting
                                    ? null
                                    : _savePdf,
                                icon: const Icon(
                                  Icons.save_alt_outlined,
                                ),
                                label: const Text('Save PDF'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _isExporting
                                    ? null
                                    : _sharePdf,
                                icon: const Icon(Icons.share_outlined),
                                label: const Text('Share'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}