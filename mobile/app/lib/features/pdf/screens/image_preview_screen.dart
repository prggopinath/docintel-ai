import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../services/image/image_export_service.dart';

class ImagePreviewScreen extends StatefulWidget {
  const ImagePreviewScreen({
    super.key,
    required this.imageBytes,
    required this.fileName,
  });

  final Uint8List imageBytes;
  final String fileName;

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  final ImageExportService _imageExportService =
      ImageExportService();

  bool _isExporting = false;

  Future<void> _saveImage() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final saved = await _imageExportService.saveImage(
        bytes: widget.imageBytes,
        fileName: widget.fileName,
      );

      if (!mounted) return;

      if (saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image saved successfully.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to save image: $e'),
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

  Future<void> _shareImage() async {
    setState(() {
      _isExporting = true;
    });

    try {
      await _imageExportService.shareImage(
        bytes: widget.imageBytes,
        fileName: widget.fileName,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to share image: $e'),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Preview'),
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: Center(
                child: Image.memory(
                  widget.imageBytes,
                  fit: BoxFit.contain,
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
                          _isExporting ? null : _saveImage,
                      icon: const Icon(Icons.save_alt_outlined),
                      label: const Text('Save Image'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed:
                          _isExporting ? null : _shareImage,
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Share'),
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