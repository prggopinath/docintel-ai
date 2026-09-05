import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/ai/ai_service.dart';
import '../../../services/document/document_service.dart';
import '../../../shared/models/scan_result.dart';

import 'package:file_picker/file_picker.dart';

import '../../../services/export/text_pdf_export_service.dart';

class OcrResultScreen extends StatefulWidget {
  const OcrResultScreen({
    super.key,
    required this.result,
  });

  final ScanResult result;

  @override
  State<OcrResultScreen> createState() => _OcrResultScreenState();
}

class _OcrResultScreenState extends State<OcrResultScreen> {
  final AiService _aiService = AiService();
  final DocumentService _documentService = DocumentService();
  final TextPdfExportService _pdfExportService =
    TextPdfExportService();

  bool _isExportingPdf = false;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isSaved = false;

  String? _summary;
  String? _error;
  
  Future<void> _exportAsPdf() async {
    if (_isExportingPdf) return;

    if (widget.result.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No extracted text available.'),
        ),
      );
      return;
    }

    setState(() {
      _isExportingPdf = true;
    });

    try {
      final bytes = await _pdfExportService.createPdf(
        text: widget.result.text,
        title: widget.result.fileName,
      );

      if (!mounted) return;

      final fileName = _createExportFileName(
        widget.result.fileName,
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

      setState(() {
        _isExportingPdf = false;
      });

      if (outputPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF exported successfully.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isExportingPdf = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to export PDF: $e'),
        ),
      );
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

    return '$baseName.$extension';
  }

  Future<void> _generateSummary() async {
    setState(() {
      _isLoading = true;
      _summary = null;
      _error = null;
    });

    try {
      final response = await _aiService.generateSummary(
        widget.result.text,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;

        if (response.success) {
          _summary = response.summary;
        } else {
          _error = response.error ?? 'Unable to generate summary.';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = 'Unable to generate summary: $e';
      });
    }
  }

  Future<void> _saveDocument() async {
    if (_isSaved) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _documentService.createAndSaveDocument(
        name: widget.result.fileName,
        type: widget.result.type,
        source: widget.result.source,
        documentType: widget.result.documentType,
        extractedText: widget.result.text,
        filePath: widget.result.filePath,
        summary: _summary,
      );

      if (!mounted) return;

      setState(() {
        _isSaved = true;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document saved successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to save document: $e'),
        ),
      );
    }
  }

  Future<void> _showExportOptions() async {
    final exportType = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Export Extracted Text',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Choose the format you want to export.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

                const SizedBox(height: 20),

                _ExportOption(
                  icon: Icons.picture_as_pdf_outlined,
                  title: 'PDF',
                  subtitle: 'Create a PDF document',
                  onTap: () {
                    Navigator.pop(context, 'pdf');
                  },
                ),

                _ExportOption(
                  icon: Icons.description_outlined,
                  title: 'DOCX',
                  subtitle: 'Create an editable Word document',
                  onTap: () {
                    Navigator.pop(context, 'docx');
                  },
                ),

                _ExportOption(
                  icon: Icons.image_outlined,
                  title: 'Image',
                  subtitle: 'Create a PNG image',
                  onTap: () {
                    Navigator.pop(context, 'image');
                  },
                ),

                _ExportOption(
                  icon: Icons.copy_outlined,
                  title: 'Copy Text',
                  subtitle: 'Copy extracted text to clipboard',
                  onTap: () {
                    Navigator.pop(context, 'copy');
                  },
                ),

                _ExportOption(
                  icon: Icons.share_outlined,
                  title: 'Share Text',
                  subtitle: 'Share extracted text',
                  onTap: () {
                    Navigator.pop(context, 'share');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || exportType == null) return;

    switch (exportType) {
      case 'pdf':
        await _exportAsPdf();
        break;

      case 'docx':
        _showComingSoon('DOCX export');
        break;

      case 'image':
        _showComingSoon('Image export');
        break;

      case 'copy':
        await _copyText();
        break;

      case 'share':
        await _shareText();
        break;
    }
  }

  Future<void> _copyText() async {
    if (widget.result.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No extracted text available.'),
        ),
      );
      return;
    }

    await Clipboard.setData(
      ClipboardData(
        text: widget.result.text,
      ),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Extracted text copied to clipboard.'),
      ),
    );
  }

  Future<void> _shareText() async {
    if (widget.result.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No extracted text available.'),
        ),
      );
      return;
    }

    await Clipboard.setData(
      ClipboardData(
        text: widget.result.text,
      ),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Text copied. File sharing will be available with export formats.',
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is being prepared.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR Result'),
        actions: [
          IconButton(
            tooltip: 'Export',
            icon: const Icon(Icons.ios_share_outlined),
            onPressed: _showExportOptions,
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
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      child: Icon(
                        Icons.document_scanner_outlined,
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.result.documentType,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            widget.result.fileName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

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

                IconButton(
                  tooltip: 'Copy text',
                  icon: const Icon(Icons.copy_outlined),
                  onPressed: _copyText,
                ),

                IconButton(
                  tooltip: 'Export',
                  icon: const Icon(Icons.ios_share_outlined),
                  onPressed: _showExportOptions,
                ),
              ],
            ),

            const SizedBox(height: 12),

            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  widget.result.text.isEmpty
                      ? 'No text detected.'
                      : widget.result.text,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),

            const SizedBox(height: 28),

            Text(
              'AI Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            if (_summary == null && !_isLoading)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _generateSummary,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Generate AI Summary'),
                ),
              ),

            if (_isLoading)
              const Card(
                elevation: 0,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 16),
                      Text('Generating AI summary...'),
                    ],
                  ),
                ),
              ),

            if (_error != null)
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ),

            if (_summary != null)
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _summary!,
                        style: theme.textTheme.bodyMedium,
                      ),

                      const SizedBox(height: 16),

                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed:
                              _isLoading ? null : _generateSummary,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Regenerate'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSaving || _isSaved
                    ? null
                    : _saveDocument,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        _isSaved
                            ? Icons.check
                            : Icons.save_outlined,
                      ),
                label: Text(
                  _isSaved
                      ? 'Document Saved'
                      : _isSaving
                          ? 'Saving...'
                          : 'Save Document',
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

class _ExportOption extends StatelessWidget {
  const _ExportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(
          Icons.chevron_right,
        ),
        onTap: onTap,
      ),
    );
  }
}