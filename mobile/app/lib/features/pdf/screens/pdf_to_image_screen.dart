import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../services/pdf/pdf_page_renderer_service.dart';
import 'image_preview_screen.dart';

class PdfToImageScreen extends StatefulWidget {
  const PdfToImageScreen({super.key});

  @override
  State<PdfToImageScreen> createState() => _PdfToImageScreenState();
}

class _PdfToImageScreenState extends State<PdfToImageScreen> {
  final PdfPageRendererService _pdfPageRendererService =
      PdfPageRendererService();

  List<Uint8List> _pageImages = [];

  bool _isLoading = false;
  String? _fileName;

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
        _pageImages = [];
        _fileName = result.files.single.name;
      });

      final images =
          await _pdfPageRendererService.renderPages(path);

      if (!mounted) return;

      setState(() {
        _pageImages = images;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to convert PDF: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF to Image'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _selectPdf,
        icon: const Icon(Icons.picture_as_pdf_outlined),
        label: Text(
          _pageImages.isEmpty ? 'Select PDF' : 'Choose Another PDF',
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Converting PDF pages...'),
                ],
              ),
            )
          : _pageImages.isEmpty
              ? _buildEmptyState(context)
              : _buildPagesGrid(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            const Text(
              'Convert PDF to Images',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select a PDF to convert each page into an image.',
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

  Widget _buildPagesGrid() {
    return Column(
      children: [
        if (_fileName != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '$_fileName • ${_pageImages.length} pages',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _pageImages.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.7,
            ),
            itemBuilder: (context, index) {
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ImagePreviewScreen(
                          imageBytes: _pageImages[index],
                          fileName: 'page_${index + 1}.png',
                        ),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Expanded(
                        child: Image.memory(
                          _pageImages[index],
                          width: double.infinity,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          'Page ${index + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}