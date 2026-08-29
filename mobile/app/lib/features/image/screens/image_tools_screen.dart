import 'package:flutter/material.dart';

import '../../pdf/screens/create_pdf_screen.dart';
import '../../scan/controllers/scan_controller.dart';
import '../../scan/screens/ocr_result_screen.dart';

class ImageToolsScreen extends StatefulWidget {
  const ImageToolsScreen({super.key});

  @override
  State<ImageToolsScreen> createState() => _ImageToolsScreenState();
}

class _ImageToolsScreenState extends State<ImageToolsScreen> {
  final ScanController _scanController = ScanController();

  bool _isProcessing = false;

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _imageToText() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await _scanController.scanFromGallery();

      if (!mounted) return;

      if (result == null) {
        return;
      }

      if (result.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No text detected.'),
          ),
        );
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OcrResultScreen(
            text: result.text,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OCR Error: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _openCreatePdf() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreatePdfScreen(),
      ),
    );
  }

  Widget _buildToolCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor:
              theme.colorScheme.primaryContainer,
          child: Icon(
            icon,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Tools'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Image Tools',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Convert and extract information from images.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

                const SizedBox(height: 24),

                _buildToolCard(
                  context: context,
                  icon: Icons.picture_as_pdf_outlined,
                  title: 'Image to PDF',
                  subtitle:
                      'Create a PDF from one or more images.',
                  onTap: _openCreatePdf,
                ),

                _buildToolCard(
                  context: context,
                  icon: Icons.text_snippet_outlined,
                  title: 'Image to Text',
                  subtitle:
                      'Extract text from an image using OCR.',
                  onTap: _isProcessing
                      ? () {}
                      : _imageToText,
                ),
              ],
            ),
          ),

          if (_isProcessing)
            const ColoredBox(
              color: Colors.black26,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Extracting text...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}