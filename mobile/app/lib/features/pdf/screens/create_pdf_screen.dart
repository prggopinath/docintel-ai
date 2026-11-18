
import 'dart:io';

import 'package:document_scan/document_scan.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../services/pdf/pdf_generation_service.dart';
import '../../../services/scanner/image_picker_service.dart';

import '../../scan/controllers/scan_controller.dart';
import '../../scan/screens/document_crop_screen.dart';

import 'pdf_preview_screen.dart';

class CreatePdfScreen extends StatefulWidget {
  const CreatePdfScreen({super.key});

  @override
  State<CreatePdfScreen> createState() => _CreatePdfScreenState();
}

class _CreatePdfScreenState extends State<CreatePdfScreen> {
  final ImagePickerService _imagePickerService = ImagePickerService();

  final ScanController _scanController = ScanController();

  final PdfGenerationService _pdfGenerationService =
      PdfGenerationService();

  final List<String> _imagePaths = [];

  bool _isCreating = false;
  bool _isAddingPage = false;

  // Full-image boundaries used when automatic detection finds no corners.
  DocumentCorners get _defaultCorners => DocumentCorners(
        topLeft: (x: 0.0, y: 0.0),
        topRight: (x: 1.0, y: 0.0),
        bottomRight: (x: 1.0, y: 1.0),
        bottomLeft: (x: 0.0, y: 1.0),
        confidence: 0.0,
      );

  Future<void> _addFromCamera() async {
    try {
      final image = await _imagePickerService.pickFromCamera();

      if (!mounted || image == null) return;

      await _addImageWithCrop(image);
    } catch (e) {
      if (!mounted) return;

      _showMessage('Unable to capture image: $e');
    }
  }

  Future<void> _addFromGallery() async {
    try {
      final image = await _imagePickerService.pickFromGallery();

      if (!mounted || image == null) return;

      await _addImageWithCrop(image);
    } catch (e) {
      if (!mounted) return;

      _showMessage('Unable to select image: $e');
    }
  }

  // Detect boundaries, open the existing crop editor,
  // and apply perspective correction before adding the page.
  Future<void> _addImageWithCrop(XFile image) async {
    if (_isAddingPage || _isCreating) return;

    setState(() {
      _isAddingPage = true;
    });

    try {
      final detectedCorners =
          await _scanController.detectDocumentCorners(image.path);

      if (!mounted) return;

      final initialCorners = detectedCorners ?? _defaultCorners;

      final DocumentCorners? selectedCorners =
          await Navigator.push<DocumentCorners?>(
        context,
        MaterialPageRoute(
          builder: (_) => DocumentCropScreen(
            imagePath: image.path,
            initialCorners: initialCorners,
          ),
        ),
      );

      // User cancelled cropping.
      if (!mounted || selectedCorners == null) return;

      // Apply actual crop and perspective correction.
      final croppedImage =
          await _scanController.cropImageWithCorners(
        imagePath: image.path,
        corners: selectedCorners,
      );

      if (!mounted) return;

      if (croppedImage == null) {
        _showMessage('Unable to crop image. Please try again.');
        return;
      }

      setState(() {
        _imagePaths.add(croppedImage.path);
      });

      _showMessage('Page added successfully.');
    } catch (e) {
      if (!mounted) return;

      _showMessage('Unable to process image: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isAddingPage = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
      _showMessage('Add at least one page first.');
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

      _showMessage('Unable to create PDF: $e');
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
    final isBusy = _isCreating || _isAddingPage;

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
                                icon: const Icon(Icons.delete_outline),
                                onPressed:
                                    isBusy ? null : () => _removePage(index),
                              ),
                              const Icon(Icons.drag_handle),
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
                  if (_isAddingPage) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    const Text('Preparing document crop...'),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isBusy ? null : _addFromCamera,
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Camera'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isBusy ? null : _addFromGallery,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Gallery'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isBusy ? null : _createPdf,
                      icon: _isCreating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.picture_as_pdf_outlined),
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
