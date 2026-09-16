import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../../../services/ai/ai_service.dart';
import '../../../services/export/text_docx_export_service.dart';
import '../../../services/export/text_pdf_export_service.dart';
import '../../../services/storage/document_repository.dart';
import '../../../services/text/text_export_service.dart';
import '../../../shared/models/document_model.dart';

class DocumentDetailScreen extends StatefulWidget {
  const DocumentDetailScreen({
    super.key,
    required this.document,
  });

  final DocumentModel document;

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  final AiService _aiService = AiService();
  final DocumentRepository _repository = DocumentRepository();
  final TextExportService _textExportService = TextExportService();
  final TextPdfExportService _pdfExportService = TextPdfExportService();
  final TextDocxExportService _docxExportService = TextDocxExportService();

  bool _isExportingPdf = false;
  bool _isExportingDocx = false;
  bool _isGeneratingSummary = false;
  bool _isExportingText = false;

  late String? _summary;

  @override
  void initState() {
    super.initState();
    _summary = widget.document.summary;
  }

  bool get _hasOriginalFile {
    final path = widget.document.filePath;
    return path != null && path.trim().isNotEmpty;
  }

  bool get _isPdf {
    final path = widget.document.filePath?.toLowerCase() ?? '';

    return widget.document.type.toLowerCase() == 'pdf' ||
        path.endsWith('.pdf');
  }

  Future<void> _previewOriginalDocument() async {
    final filePath = widget.document.filePath;

    if (filePath == null || filePath.trim().isEmpty) {
      _showMessage('Original file path is not available.');
      return;
    }

    final file = File(filePath);

    if (!await file.exists()) {
      if (!mounted) return;
      _showMessage('The original file is no longer available.');
      return;
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _OriginalDocumentPreviewScreen(
          filePath: filePath,
          fileName: widget.document.name,
          isPdf: _isPdf,
        ),
      ),
    );
  }

  Future<void> _exportAsPdf() async {
    if (_isExportingPdf) return;

    final text = widget.document.extractedText.trim();

    if (text.isEmpty) {
      _showMessage('No extracted text available.');
      return;
    }

    setState(() {
      _isExportingPdf = true;
    });

    try {
      final bytes = await _pdfExportService.createPdf(
        text: widget.document.extractedText,
        title: widget.document.name,
      );

      final fileName = _createExportFileName(
        widget.document.name,
        'pdf',
      );

      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save PDF',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        bytes: Uint8List.fromList(bytes),
      );

      if (!mounted) return;

      if (outputPath != null) {
        _showMessage('PDF exported successfully.');
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('PDF export failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isExportingPdf = false;
        });
      }
    }
  }

  Future<void> _exportAsDocx() async {
    if (_isExportingDocx) return;

    final text = widget.document.extractedText.trim();

    if (text.isEmpty) {
      _showMessage('No extracted text available.');
      return;
    }

    setState(() {
      _isExportingDocx = true;
    });

    try {
      final fileName = _createExportFileName(
        widget.document.name,
        'docx',
      );

      final bytes = await _docxExportService.createDocx(
        text: widget.document.extractedText,
        title: fileName.replaceAll('.docx', ''),
      );

      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save DOCX',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['docx'],
        bytes: bytes,
      );

      if (!mounted) return;

      if (outputPath != null) {
        _showMessage('DOCX exported successfully.');
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('DOCX export failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isExportingDocx = false;
        });
      }
    }
  }

  Future<void> _generateSummary() async {
    if (_isGeneratingSummary) return;

    if (widget.document.extractedText.trim().isEmpty) {
      _showMessage('No extracted text available for summarization.');
      return;
    }

    setState(() {
      _isGeneratingSummary = true;
    });

    try {
      final response = await _aiService.generateSummary(
        widget.document.extractedText,
      );

      if (!mounted) return;

      if (!response.success || response.summary.trim().isEmpty) {
        setState(() {
          _isGeneratingSummary = false;
        });

        _showMessage(
          response.error?.isNotEmpty == true
              ? response.error!
              : 'Unable to generate summary.',
        );

        return;
      }

      await _repository.updateSummary(
        widget.document.id,
        response.summary,
      );

      if (!mounted) return;

      setState(() {
        _summary = response.summary;
        _isGeneratingSummary = false;
      });

      _showMessage('AI summary generated successfully.');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isGeneratingSummary = false;
      });

      _showMessage('AI Summary Error: $e');
    }
  }

  Future<void> _exportText() async {
    if (_isExportingText) return;

    if (widget.document.extractedText.trim().isEmpty) {
      _showMessage('No extracted text available to export.');
      return;
    }

    setState(() {
      _isExportingText = true;
    });

    try {
      final fileName = _createTextFileName(widget.document.name);

      final saved = await _textExportService.saveText(
        text: widget.document.extractedText,
        fileName: fileName,
      );

      if (!mounted) return;

      setState(() {
        _isExportingText = false;
      });

      if (saved) {
        _showMessage('Extracted text exported successfully.');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isExportingText = false;
      });

      _showMessage('Unable to export text: $e');
    }
  }

  Future<void> _shareText() async {
    if (widget.document.extractedText.trim().isEmpty) {
      _showMessage('No extracted text available to share.');
      return;
    }

    try {
      final fileName = _createTextFileName(widget.document.name);

      await _textExportService.shareText(
        text: widget.document.extractedText,
        fileName: fileName,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage('Unable to share text: $e');
    }
  }

  String _createExportFileName(
    String originalName,
    String extension,
  ) {
    final lastDot = originalName.lastIndexOf('.');

    final baseName = lastDot > 0
        ? originalName.substring(0, lastDot)
        : originalName;

    final sanitizedName = baseName
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .trim();

    return '${sanitizedName.isEmpty ? 'document' : sanitizedName}.$extension';
  }

  String _createTextFileName(String originalName) {
    final lastDot = originalName.lastIndexOf('.');

    final baseName = lastDot > 0
        ? originalName.substring(0, lastDot)
        : originalName;

    return '$baseName.txt';
  }

  Future<void> _deleteDocument() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Document?'),
          content: const Text(
            'This document and its extracted text will be permanently deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await _repository.delete(widget.document.id);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _showMessage('Unable to delete document: $e');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatCharacterCount(int count) {
    return '$count ${count == 1 ? 'character' : 'characters'}';
  }

  IconData _getDocumentIcon() {
    if (widget.document.type.toLowerCase() == 'pdf') {
      return Icons.picture_as_pdf_outlined;
    }

    return Icons.image_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extractedText = widget.document.extractedText;
    final hasText = extractedText.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document'),
        actions: [
          IconButton(
            tooltip: 'Delete document',
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteDocument,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          child: Icon(
                            _getDocumentIcon(),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            widget.document.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_hasOriginalFile) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _previewOriginalDocument,
                          icon: const Icon(Icons.preview_outlined),
                          label: const Text(
                            'Preview Original Document',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Document Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _InfoRow(
                      label: 'Type',
                      value: widget.document.type.toUpperCase(),
                    ),
                    _InfoRow(
                      label: 'Document',
                      value: widget.document.documentType,
                    ),
                    _InfoRow(
                      label: 'Source',
                      value: widget.document.source,
                    ),
                    _InfoRow(
                      label: 'Created',
                      value: _formatDate(widget.document.createdAt),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Storage',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        child: Icon(Icons.storage_outlined),
                      ),
                      title: Text('Extracted text'),
                      subtitle: Text(
                        'Stored securely in the app database.',
                      ),
                    ),
                    const Divider(),
                    _InfoRow(
                      label: 'Characters',
                      value: _formatCharacterCount(
                        widget.document.extractedText.length,
                      ),
                    ),
                    if (_hasOriginalFile)
                      _InfoRow(
                        label: 'Original file',
                        value: widget.document.filePath!,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Extracted Text',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (hasText)
                  IconButton(
                    tooltip: 'Export TXT',
                    onPressed: _isExportingText ? null : _exportText,
                    icon: _isExportingText
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.download_outlined),
                  ),
                if (hasText)
                  IconButton(
                    tooltip: 'Share text',
                    onPressed: _shareText,
                    icon: const Icon(Icons.share_outlined),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  hasText ? extractedText : 'No text extracted.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
            if (hasText) ...[
              const SizedBox(height: 16),
              Text(
                'Export As',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isExportingPdf ? null : _exportAsPdf,
                      icon: _isExportingPdf
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.picture_as_pdf_outlined),
                      label: Text(
                        _isExportingPdf ? 'Exporting...' : 'PDF',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isExportingDocx ? null : _exportAsDocx,
                      icon: _isExportingDocx
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.description_outlined),
                      label: Text(
                        _isExportingDocx ? 'Exporting...' : 'DOCX',
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'AI Summary',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed:
                      _isGeneratingSummary ? null : _generateSummary,
                  icon: _isGeneratingSummary
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    _isGeneratingSummary
                        ? 'Generating...'
                        : _summary?.isNotEmpty == true
                            ? 'Regenerate'
                            : 'Summarize',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _summary?.isNotEmpty == true
                      ? _summary!
                      : 'No AI summary yet. Tap Summarize to generate one.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _OriginalDocumentPreviewScreen extends StatelessWidget {
  const _OriginalDocumentPreviewScreen({
    required this.filePath,
    required this.fileName,
    required this.isPdf,
  });

  final String filePath;
  final String fileName;
  final bool isPdf;

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
      body: isPdf
          ? PdfViewPinch(
              controller: PdfControllerPinch(
                document: PdfDocument.openFile(filePath),
              ),
            )
          : InteractiveViewer(
              minScale: 0.5,
              maxScale: 5,
              child: Center(
                child: Image.file(
                  file,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text('Unable to preview this image.'),
                    );
                  },
                ),
              ),
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}