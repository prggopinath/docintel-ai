import 'dart:io';

import 'package:flutter/material.dart';

import '../../../services/pdf/pdf_generation_service.dart';
import '../../../services/scanner/image_picker_service.dart';
import 'pdf_preview_screen.dart';

class CreatePdfScreen extends StatefulWidget {
  const CreatePdfScreen({super.key});

  @override
  State<CreatePdfScreen> createState() => _CreatePdfScreenState();
}

class _CreatePdfScreenState extends State<CreatePdfScreen> {
  final ImagePickerService _imagePickerService = ImagePickerService();

  final PdfGenerationService _pdfGenerationService =
      PdfGenerationService();

  final List<String> _imagePaths = [];

  bool _isCreating = false;

  Future<void> _addFromCamera() async {
    try {
      final image = await _imagePickerService.pickFromCamera();

      if (!mounted || image == null) return;

      setState(() {
        _imagePaths.add(image.path);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to capture image: $e'),
        ),
      );
    }
  }

  Future<void> _addFromGallery() async {
    try {
      final image = await _imagePickerService.pickFromGallery();

      if (!mounted || image == null) return;

      setState(() {
        _imagePaths.add(image.path);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to select image: $e'),
        ),
      );
    }
  }

  void _removePage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
    });
  }

  void _reorderPages(int oldIndex, int newIndex) {
    setState(() {
      final imagePath = _imagePaths.removeAt(oldIndex);
      _imagePaths.insert(newIndex, imagePath);
    });
  }

  Future<void> _createPdf() async {
    if (_imagePaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one page first.'),
        ),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final pdfBytes =
          await _pdfGenerationService.generatePdfBytesFromImages(
        imagePaths: _imagePaths,
      );

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfPreviewScreen(
            imagePaths: _imagePaths,
            pdfBytes: pdfBytes,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to create PDF: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create PDF'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _imagePaths.isEmpty
                ? const Center(
                    child: Text(
                      'No pages added yet.\nAdd images to create a PDF.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _imagePaths.length,
                    onReorderItem: _reorderPages,
                    itemBuilder: (context, index) {
                      final imagePath = _imagePaths[index];

                      return Card(
                        key: ValueKey(imagePath),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: SizedBox(
                            width: 60,
                            height: 80,
                            child: Image.file(
                              File(imagePath),
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text('Page ${index + 1}'),
                          subtitle: const Text('Drag to reorder'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Delete page',
                                icon: const Icon(
                                  Icons.delete_outline,
                                ),
                                onPressed: _isCreating
                                    ? null
                                    : () => _removePage(index),
                              ),
                              const Icon(
                                Icons.drag_handle,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              _isCreating ? null : _addFromCamera,
                          icon: const Icon(
                            Icons.camera_alt_outlined,
                          ),
                          label: const Text('Camera'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              _isCreating ? null : _addFromGallery,
                          icon: const Icon(
                            Icons.photo_library_outlined,
                          ),
                          label: const Text('Gallery'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isCreating ? null : _createPdf,
                      icon: _isCreating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.picture_as_pdf_outlined,
                            ),
                      label: Text(
                        _isCreating
                            ? 'Creating PDF...'
                            : 'Create PDF (${_imagePaths.length} pages)',
                      ),
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