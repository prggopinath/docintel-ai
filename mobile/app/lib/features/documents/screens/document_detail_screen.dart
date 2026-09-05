import 'package:flutter/material.dart';

import '../../../services/ai/ai_service.dart';
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

  late String? _summary;

  bool _isGeneratingSummary = false;
  bool _isExportingText = false;

  @override
  void initState() {
    super.initState();
    _summary = widget.document.summary;
  }

  Future<void> _generateSummary() async {
    if (_isGeneratingSummary) return;

    if (widget.document.extractedText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No extracted text available for summarization.'),
        ),
      );
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.error?.isNotEmpty == true
                  ? response.error!
                  : 'Unable to generate summary.',
            ),
          ),
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI summary generated successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isGeneratingSummary = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI Summary Error: $e'),
        ),
      );
    }
  }

  Future<void> _exportText() async {
    if (_isExportingText) return;

    if (widget.document.extractedText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No extracted text available to export.'),
        ),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Extracted text exported successfully.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isExportingText = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to export text: $e'),
        ),
      );
    }
  }

  Future<void> _shareText() async {
    if (widget.document.extractedText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No extracted text available to share.'),
        ),
      );
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to share text: $e'),
        ),
      );
    }
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
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to delete document: $e'),
        ),
      );
    }
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
                child: Row(
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
                    if (widget.document.filePath != null &&
                        widget.document.filePath!.isNotEmpty)
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
                    onPressed:
                        _isExportingText ? null : _exportText,
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