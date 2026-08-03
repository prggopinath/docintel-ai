import 'package:flutter/material.dart';

import '../../../services/ai/ai_service.dart';

class OcrResultScreen extends StatefulWidget {
  const OcrResultScreen({
    super.key,
    required this.text,
  });

  final String text;

  @override
  State<OcrResultScreen> createState() => _OcrResultScreenState();
}

class _OcrResultScreenState extends State<OcrResultScreen> {
  final AiService _aiService = AiService();

  bool _isLoading = false;
  String? _summary;
  String? _error;

  Future<void> _generateSummary() async {
    setState(() {
      _isLoading = true;
      _summary = null;
      _error = null;
    });

    final response = await _aiService.generateSummary(widget.text);

    if (!mounted) return;

    setState(() {
      _isLoading = false;

      if (response.success) {
        _summary = response.summary;
      } else {
        _error = response.error ?? "Unable to generate summary.";
      }
    });
  }

  Widget _buildSummarySection() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.red),
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
            style: const TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _generateSummary,
        icon: const Icon(Icons.auto_awesome),
        label: const Text("Generate AI Summary"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("OCR Result"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Extracted Text",
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
                  widget.text.isEmpty
                      ? "No text detected."
                      : widget.text,
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              "AI Summary",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            _buildSummarySection(),
          ],
        ),
      ),
    );
  }
}