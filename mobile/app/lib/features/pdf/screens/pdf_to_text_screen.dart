import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../services/pdf/pdf_ocr_service.dart';
import '../../../services/pdf/pdf_text_service.dart';
import '../../../services/text/text_export_service.dart';

class PdfToTextScreen extends StatefulWidget {
  const PdfToTextScreen({super.key});

  @override
  State<PdfToTextScreen> createState() => _PdfToTextScreenState();
}

class _PdfToTextScreenState extends State<PdfToTextScreen> {
  final PdfTextService _pdfTextService = PdfTextService();
  final PdfOcrService _pdfOcrService = PdfOcrService();
  final TextExportService _textExportService = TextExportService();

  String _extractedText = '';
  String? _fileName;

  bool _isLoading = false;
  bool _isExporting = false;

  Future<void> _selectPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null || result.files.single.path == null) {
        return;
      }

      final path = result.files.single.path!;

      setState(() {
        _isLoading = true;
        _extractedText = '';
        _fileName = result.files.single.name;
      });

      // First try normal PDF text extraction.
      var text = await _pdfTextService.extractText(path);

      // If the PDF has no embedded text, use OCR.
      if (text.trim().isEmpty) {
        text = await _pdfOcrService.extractText(path);
      }

      if (!mounted) return;

      setState(() {
        _extractedText = text;
        _isLoading = false;
      });

      if (text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No text could be extracted from this PDF.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to extract text: $e'),
        ),
      );
    }
  }

  Future<void> _saveText() async {
    if (_extractedText.trim().isEmpty) return;

    setState(() {
      _isExporting = true;
    });

    try {
      final baseName = _fileName
              ?.replaceFirst(
                RegExp(r'\.pdf$', caseSensitive: false),
                '',
              ) ??
          'document';

      final saved = await _textExportService.saveText(
        text: _extractedText,
        fileName: '$baseName.txt',
      );

      if (!mounted) return;

      if (saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Text saved successfully.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to save text: $e'),
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

  Future<void> _shareText() async {
    if (_extractedText.trim().isEmpty) return;

    setState(() {
      _isExporting = true;
    });

    try {
      final baseName = _fileName
              ?.replaceFirst(
                RegExp(r'\.pdf$', caseSensitive: false),
                '',
              ) ??
          'document';

      await _textExportService.shareText(
        text: _extractedText,
        fileName: '$baseName.txt',
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to share text: $e'),
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
  void dispose() {
    _pdfOcrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF to Text'),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Extracting text...'),
                ],
              ),
            )
          : _extractedText.isEmpty
              ? _buildEmptyState()
              : _buildTextView(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.text_snippet_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            const Text(
              'Convert PDF to Text',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Extract text from a PDF and save or share it as a TXT file.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _selectPdf,
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Select PDF'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextView() {
    return Column(
      children: [
        if (_fileName != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              _fileName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        Expanded(
          child: Card(
            margin: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                _extractedText,
              ),
            ),
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
                    onPressed:
                        _isExporting ? null : _saveText,
                    icon: const Icon(
                      Icons.save_alt_outlined,
                    ),
                    label: const Text('Save TXT'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed:
                        _isExporting ? null : _shareText,
                    icon: const Icon(
                      Icons.share_outlined,
                    ),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}