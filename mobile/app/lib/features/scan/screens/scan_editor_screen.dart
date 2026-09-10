import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

import '../../../services/image/image_processing_service.dart';

class ScanEditorScreen extends StatefulWidget {
  const ScanEditorScreen({
    super.key,
    required this.imagePath,
    required this.documentType,
  });

  final String imagePath;
  final String documentType;

  @override
  State<ScanEditorScreen> createState() => _ScanEditorScreenState();
}

class _ScanEditorScreenState extends State<ScanEditorScreen> {
  final ImageProcessingService _imageService =
      ImageProcessingService();

  final CropController _cropController = CropController();

  Uint8List? _sourceBytes;
  Uint8List? _previewBytes;

  double _brightness = 0;
  double _contrast = 0;

  bool _cropMode = false;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final bytes = await _imageService.prepareForEditing(
        widget.imagePath,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _sourceBytes = bytes;
        _previewBytes = bytes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to prepare image: $e'),
        ),
      );
    }
  }

  Future<Uint8List> _commitCurrentAdjustments() async {
    final source = _sourceBytes;

    if (source == null) {
      throw StateError('Image is not loaded.');
    }

    if (_brightness == 0 && _contrast == 0) {
      return source;
    }

    return _imageService.adjust(
      bytes: source,
      brightness: _brightness,
      contrast: _contrast,
    );
  }

  Future<void> _updatePreview() async {
    final source = _sourceBytes;

    if (source == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final preview = await _imageService.adjust(
        bytes: source,
        brightness: _brightness,
        contrast: _contrast,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _previewBytes = preview;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image adjustment failed: $e'),
        ),
      );
    }
  }

  Future<void> _autoEnhance() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final adjusted = await _commitCurrentAdjustments();
      final enhanced = await _imageService.autoEnhance(adjusted);

      if (!mounted) {
        return;
      }

      setState(() {
        _sourceBytes = enhanced;
        _previewBytes = enhanced;
        _brightness = 0;
        _contrast = 0;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Auto enhance failed: $e'),
        ),
      );
    }
  }

  Future<void> _rotate() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final adjusted = await _commitCurrentAdjustments();
      final rotated = await _imageService.rotate(adjusted);

      if (!mounted) {
        return;
      }

      setState(() {
        _sourceBytes = rotated;
        _previewBytes = rotated;
        _brightness = 0;
        _contrast = 0;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rotation failed: $e'),
        ),
      );
    }
  }

  Future<void> _startCrop() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final adjusted = await _commitCurrentAdjustments();

      if (!mounted) {
        return;
      }

      setState(() {
        _sourceBytes = adjusted;
        _previewBytes = adjusted;
        _brightness = 0;
        _contrast = 0;
        _cropMode = true;
        _isLoading = false;
      });

      _cropController.image = adjusted;
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open crop tool: $e'),
        ),
      );
    }
  }

  void _applyCrop() {
    _cropController.crop();
  }

  void _cancelCrop() {
    setState(() {
      _cropMode = false;
    });
  }

  void _handleCropResult(CropResult result) {
    switch (result) {
      case CropSuccess(:final croppedImage):
        setState(() {
          _sourceBytes = croppedImage;
          _previewBytes = croppedImage;
          _cropMode = false;
          _brightness = 0;
          _contrast = 0;
        });
      case CropFailure(:final cause):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Crop failed: $cause'),
          ),
        );
    }
  }

  Future<void> _useThisScan() async {
    final source = _sourceBytes;

    if (source == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final finalBytes = await _commitCurrentAdjustments();

      final path = await _imageService.saveToTemporaryFile(
        bytes: finalBytes,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context, path);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not prepare scan: $e'),
        ),
      );
    }
  }

  Widget _buildPreview() {
    final bytes = _previewBytes;

    if (bytes == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_cropMode) {
      return Crop(
        key: ValueKey(bytes),
        image: bytes,
        controller: _cropController,
        interactive: true,
        baseColor: Colors.black,
        maskColor: Colors.black54,
        radius: 8,
        progressIndicator: const CircularProgressIndicator(),
        cornerDotBuilder: (size, edgeAlignment) {
          return const DotControl(
            color: Colors.white,
          );
        },
        onCropped: _handleCropResult,
      );
    }

    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: Image.memory(
        bytes,
        fit: BoxFit.contain,
        gaplessPlayback: true,
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required ValueChanged<double> onChangeEnd,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              value.toStringAsFixed(1),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        Slider(
          min: -1,
          max: 1,
          divisions: 20,
          value: value,
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
        ),
      ],
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: _isLoading || _isSaving ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).dividerColor,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.documentType} Scan'),
        actions: [
          if (!_cropMode)
            IconButton(
              tooltip: 'Reset adjustments',
              onPressed: _isLoading || _isSaving
                  ? null
                  : () {
                      setState(() {
                        _brightness = 0;
                        _contrast = 0;
                        _previewBytes = _sourceBytes;
                      });
                    },
              icon: const Icon(Icons.restart_alt),
            ),
        ],
      ),
      body: _isLoading && _sourceBytes == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: _buildPreview(),
                      ),
                      if (_isLoading)
                        const Positioned.fill(
                          child: ColoredBox(
                            color: Colors.black26,
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_cropMode)
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : _cancelCrop,
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _isLoading ? null : _applyCrop,
                              icon: const Icon(Icons.check),
                              label: const Text('Apply Crop'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        12,
                        10,
                        12,
                        12,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _buildToolButton(
                                icon: Icons.auto_fix_high,
                                label: 'Auto Enhance',
                                onTap: _autoEnhance,
                              ),
                              const SizedBox(width: 8),
                              _buildToolButton(
                                icon: Icons.crop,
                                label: 'Crop',
                                onTap: _startCrop,
                              ),
                              const SizedBox(width: 8),
                              _buildToolButton(
                                icon: Icons.rotate_right,
                                label: 'Rotate',
                                onTap: _rotate,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildSlider(
                            label: 'Brightness',
                            value: _brightness,
                            onChanged: (value) {
                              setState(() {
                                _brightness = value;
                              });
                            },
                            onChangeEnd: (_) => _updatePreview(),
                          ),
                          _buildSlider(
                            label: 'Contrast',
                            value: _contrast,
                            onChanged: (value) {
                              setState(() {
                                _contrast = value;
                              });
                            },
                            onChangeEnd: (_) => _updatePreview(),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed:
                                  _isLoading || _isSaving
                                      ? null
                                      : _useThisScan,
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Use This Scan'),
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