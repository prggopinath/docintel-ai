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

  Uint8List? _imageBytes;
  Uint8List? _croppedBytes;

  double _brightness = 0;
  double _contrast = 0;

  int _rotationQuarterTurns = 0;

  bool _autoEnhanceEnabled = false;
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
      final bytes = await _imageService.loadForEditing(
        widget.imagePath,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _imageBytes = bytes;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to load image: $error'),
        ),
      );
    }
  }

  void _resetAdjustments() {
    setState(() {
      _brightness = 0;
      _contrast = 0;
      _rotationQuarterTurns = 0;
      _autoEnhanceEnabled = false;
    });
  }

  void _rotate() {
    setState(() {
      _rotationQuarterTurns =
          (_rotationQuarterTurns + 1) % 4;
    });
  }

  void _startCrop() {
    final bytes = _imageBytes;

    if (bytes == null || _isSaving) {
      return;
    }

    setState(() {
      _cropMode = true;
    });
  }

  void _cancelCrop() {
    setState(() {
      _cropMode = false;
    });
  }

  void _applyCrop() {
    if (!_cropMode || _isSaving) {
      return;
    }

    _cropController.crop();
  }

  void _handleCropResult(CropResult result) {
    switch (result) {
      case CropSuccess(:final croppedImage):
        setState(() {
          _croppedBytes = croppedImage;
          _cropMode = false;
        });

      case CropFailure(:final cause):
        setState(() {
          _cropMode = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Crop failed: $cause'),
          ),
        );
    }
  }

  Future<void> _useThisScan() async {
    final sourceBytes = _imageBytes;

    if (sourceBytes == null || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final finalPath = await _imageService.saveFinalImage(
        sourceBytes: sourceBytes,
        croppedBytes: _croppedBytes,
        rotationQuarterTurns: _rotationQuarterTurns,
        brightness: _brightness,
        contrast: _contrast,
        autoEnhance: _autoEnhanceEnabled,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context, finalPath);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not prepare scan: $error'),
        ),
      );
    }
  }

  Widget _buildImagePreview() {
    final bytes = _imageBytes;

    if (bytes == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    Widget image = Image.memory(
      _croppedBytes ?? bytes,
      fit: BoxFit.contain,
      gaplessPlayback: true,
    );

    image = Transform.rotate(
      angle: _rotationQuarterTurns * 1.57079632679,
      child: image,
    );

    final brightnessValue =
        (_brightness * 0.25).clamp(-0.25, 0.25);

    final contrastValue =
        (1.0 + _contrast * 0.5).clamp(0.5, 1.5);

    final colorMatrix = <double>[
      contrastValue,
      0,
      0,
      0,
      brightnessValue * 255,
      0,
      contrastValue,
      0,
      0,
      brightnessValue * 255,
      0,
      0,
      contrastValue,
      0,
      brightnessValue * 255,
      0,
      0,
      0,
      1,
      0,
    ];

    image = ColorFiltered(
      colorFilter: ColorFilter.matrix(colorMatrix),
      child: image,
    );

    if (_autoEnhanceEnabled) {
      image = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          1.08, 0, 0, 0, 0,
          0, 1.08, 0, 0, 0,
          0, 0, 1.08, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: image,
      );
    }

    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: image,
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
        onTap: _isSaving ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context)
                    .colorScheme
                    .primaryContainer
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

  Widget _buildSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
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
            Text(value.toStringAsFixed(1)),
          ],
        ),
        Slider(
          min: -1,
          max: 1,
          divisions: 20,
          value: value,
          onChanged: _isSaving ? null : onChanged,
        ),
      ],
    );
  }

  Widget _buildCropView() {
    final bytes = _imageBytes;

    if (bytes == null) {
      return const SizedBox.shrink();
    }

    return Crop(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.documentType} Scan'),
        actions: [
          if (!_cropMode)
            IconButton(
              tooltip: 'Reset adjustments',
              onPressed: _isSaving ? null : _resetAdjustments,
              icon: const Icon(Icons.restart_alt),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Expanded(
                  child: _cropMode
                      ? _buildCropView()
                      : _buildImagePreview(),
                ),
                if (_cropMode)
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        8,
                        16,
                        12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isSaving
                                  ? null
                                  : _cancelCrop,
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _isSaving
                                  ? null
                                  : _applyCrop,
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
                                selected: _autoEnhanceEnabled,
                                onTap: () {
                                  setState(() {
                                    _autoEnhanceEnabled =
                                        !_autoEnhanceEnabled;
                                  });
                                },
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
                          ),
                          _buildSlider(
                            label: 'Contrast',
                            value: _contrast,
                            onChanged: (value) {
                              setState(() {
                                _contrast = value;
                              });
                            },
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _isSaving
                                  ? null
                                  : _useThisScan,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.check_circle_outline,
                                    ),
                              label: Text(
                                _isSaving
                                    ? 'Preparing Scan...'
                                    : 'Use This Scan',
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