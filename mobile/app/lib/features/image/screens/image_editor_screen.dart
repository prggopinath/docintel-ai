
import 'dart:typed_data';

import 'package:document_scan/document_scan.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

import '../../../services/image/image_processing_service.dart';
import '../../scan/controllers/scan_controller.dart';
import '../../scan/screens/document_crop_screen.dart';

enum ImageEditorMode {
  document,
  object,
}

class ImageEditorScreen extends StatefulWidget {
  const ImageEditorScreen({
    super.key,
    required this.imagePath,
    this.initialMode = ImageEditorMode.document,
  });

  final String imagePath;
  final ImageEditorMode initialMode;

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  final ImageProcessingService _processingService =
      ImageProcessingService();

  final ScanController _scanController = ScanController();

  late String _workingPath;

  Uint8List? _imageBytes;

  double _brightness = 0;
  double _contrast = 0;

  int _rotationQuarterTurns = 0;

  bool _autoEnhance = false;
  bool _isLoading = true;
  bool _isApplying = false;

  
  @override
  void initState() {
    super.initState();

    _workingPath = widget.imagePath;

    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final bytes =
          await _processingService.loadForEditing(_workingPath);

      if (!mounted) return;

      setState(() {
        _imageBytes = bytes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      _showMessage('Unable to load image: $e');
    }
  }

  Future<void> _cropDocument() async {
    if (_isLoading || _isApplying) return;

    setState(() => _isLoading = true);

    try {
      final DocumentCorners? corners =
          await _scanController.detectDocumentCorners(_workingPath);

      if (!mounted) return;

      if (corners == null) {
        _showMessage(
          'No document boundaries detected. Try Object mode or continue without cropping.',
        );
        return;
      }

      final DocumentCorners? selectedCorners =
          await Navigator.push<DocumentCorners>(
        context,
        MaterialPageRoute(
          builder: (_) => DocumentCropScreen(
            imagePath: _workingPath,
            initialCorners: corners,
          ),
        ),
      );

      if (!mounted || selectedCorners == null) return;

      final cropped = await _scanController.cropImageWithCorners(
        imagePath: _workingPath,
        corners: selectedCorners,
      );

      if (!mounted) return;

      if (cropped == null) {
        _showMessage('Unable to crop the document.');
        return;
      }

      _workingPath = cropped.path;

      await _reloadImage();
    } catch (e) {
      if (mounted) {
        _showMessage('Document cropping failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cropObject() async {
    if (_isLoading || _isApplying) return;

    setState(() => _isLoading = true);

    try {
      final CroppedFile? croppedFile =
          await ImageCropper().cropImage(
        sourcePath: _workingPath,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 95,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: false,
          ),
        ],
      );

      if (!mounted || croppedFile == null) return;

      _workingPath = croppedFile.path;

      await _reloadImage();
    } catch (e) {
      if (mounted) {
        _showMessage('Image cropping failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _reloadImage() async {
    final bytes =
        await _processingService.loadForEditing(_workingPath);

    if (!mounted) return;

    setState(() {
      _imageBytes = bytes;
      _brightness = 0;
      _contrast = 0;
      _rotationQuarterTurns = 0;
      _autoEnhance = false;
    });
  }

  void _rotateLeft() {
    setState(() {
      _rotationQuarterTurns =
          (_rotationQuarterTurns - 1) % 4;
    });
  }

  void _rotateRight() {
    setState(() {
      _rotationQuarterTurns =
          (_rotationQuarterTurns + 1) % 4;
    });
  }

  void _resetAdjustments() {
    setState(() {
      _brightness = 0;
      _contrast = 0;
      _rotationQuarterTurns = 0;
      _autoEnhance = false;
    });
  }

  Future<void> _applyChanges() async {
    if (_imageBytes == null || _isApplying) return;

    setState(() => _isApplying = true);

    try {
      final outputPath =
          await _processingService.saveFinalImage(
        sourceBytes: _imageBytes!,
        rotationQuarterTurns: _rotationQuarterTurns,
        brightness: _brightness,
        contrast: _contrast,
        autoEnhance: _autoEnhance,
      );

      if (!mounted) return;

      Navigator.pop(context, outputPath);
    } catch (e) {
      if (mounted) {
        _showMessage('Unable to apply changes: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isApplying = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Editor'),
        actions: [
          IconButton(
            tooltip: 'Reset adjustments',
            onPressed: _isLoading ? null : _resetAdjustments,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _imageBytes == null
              ? const Center(child: Text('Unable to display image'))
              : Column(
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        color: Colors.black,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(12),
                        child: RotatedBox(
                          quarterTurns: _rotationQuarterTurns,
                          child: Image.memory(
                            _imageBytes!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    _buildEditorControls(),
                  ],
                ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildEditorControls() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Crop mode',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isApplying
                      ? null
                      : () {
                          setState(() {
                           
                          });
                          _cropDocument();
                        },
                  icon: const Icon(Icons.document_scanner),
                  label: const Text('Document'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isApplying
                      ? null
                      : () {
                          setState(() {
                            
                          });
                          _cropObject();
                        },
                  icon: const Icon(Icons.crop),
                  label: const Text('Object / Free crop'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          _buildSlider(
            title: 'Brightness',
            value: _brightness,
            onChanged: (value) {
              setState(() => _brightness = value);
            },
          ),
          _buildSlider(
            title: 'Contrast',
            value: _contrast,
            onChanged: (value) {
              setState(() => _contrast = value);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Auto Enhance'),
            subtitle: const Text('Improve image clarity and contrast'),
            value: _autoEnhance,
            onChanged: (value) {
              setState(() => _autoEnhance = value);
            },
          ),
          Row(
            children: [
              const Text(
                'Rotate',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Rotate left',
                onPressed: _rotateLeft,
                icon: const Icon(Icons.rotate_left),
              ),
              IconButton(
                tooltip: 'Rotate right',
                onPressed: _rotateRight,
                icon: const Icon(Icons.rotate_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String title,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text('${(value * 100).round()}%'),
          ],
        ),
        Slider(
          min: -1,
          max: 1,
          divisions: 40,
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isApplying
                    ? null
                    : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _isApplying || _imageBytes == null
                    ? null
                    : _applyChanges,
                icon: _isApplying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check),
                label: const Text('Apply'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
