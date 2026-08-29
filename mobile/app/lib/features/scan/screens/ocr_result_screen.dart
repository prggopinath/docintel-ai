import 'package:flutter/material.dart';

import '../../../services/ai/ai_service.dart';
import '../../../services/document/document_service.dart';
import '../../../shared/models/scan_result.dart';

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

  bool _isLoading = false;
  bool _isSaving = false;

  bool _isSaved = false;

  String? _summary;
  String? _error;

  Future<void> _generateSummary() async {
    setState(() {
      _isLoading = true;
      _summary = null;
      _error = null;
    });

    try {
      final response =
          await _aiService.generateSummary(widget.result.text);

      if (!mounted) return;

      setState(() {
        _isLoading = false;

        if (response.success) {
          _summary = response.summary;
        } else {
          _error =
              response.error ?? 'Unable to generate summary.';
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

  Widget _buildSummarySection() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _error!,
            style: const TextStyle(
              color: Colors.red,
            ),
          ),
        ),
      );
    }

    if (_summary != null) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _summary!,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _generateSummary,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Generate AI Summary'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;

    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR Result'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.documentType,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 4),

            Text(
              result.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium,
            ),

            const SizedBox(height: 24),

            const Text(
              'Extracted Text',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  result.text.isEmpty
                      ? 'No text detected.'
                      : result.text,
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'AI Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            _buildSummarySection(),

            const SizedBox(height: 24),

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
                      : 'Save Document',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}