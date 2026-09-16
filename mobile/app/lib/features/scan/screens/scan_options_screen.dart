import 'package:flutter/material.dart';

import '../controllers/scan_controller.dart';
import 'ocr_result_screen.dart';

class ScanOptionsScreen extends StatefulWidget {
  const ScanOptionsScreen({
    super.key,
    required this.documentType,
  });

  final String documentType;

  @override
  State<ScanOptionsScreen> createState() => _ScanOptionsScreenState();
}

class _ScanOptionsScreenState extends State<ScanOptionsScreen> {
  final ScanController _scanController = ScanController();

  bool _isProcessing = false;

  bool get _requiresFrontAndBack {
    return widget.documentType.toLowerCase() == 'id card';
  }

  String get _scanGuidance {
    switch (widget.documentType.toLowerCase()) {
      case 'invoice':
        return 'Place the complete invoice inside the frame. Make sure the invoice number, date, vendor details, and total amount are visible.';

      case 'receipt':
        return 'Capture the complete receipt clearly. Avoid shadows and ensure the date, items, and total amount are readable.';

      case 'book':
        return 'Keep the book page flat and capture the complete page without cutting off the edges.';

      case 'notes':
        return 'Place your handwritten or printed notes on a flat surface with sufficient lighting.';

      case 'id card':
        return 'Capture the front and back sides of the ID card separately. Keep the card fully visible and aligned inside the frame.';

      case 'certificate':
        return 'Capture the complete certificate, including its title, name, date, seal, and signature.';

      case 'business card':
        return 'Capture the entire business card and ensure the name, phone number, email, and company details are visible.';

      case 'research paper':
        return 'Capture one complete page at a time. Keep the page flat and ensure the text is sharp and readable.';

      case 'other':
      default:
        return 'Place the document inside the frame and make sure all important text is visible and readable.';
    }
  }

  Future<void> _scanFromCamera() async {
    if (_requiresFrontAndBack) {
      await _scanIdCardFromCamera();
      return;
    }

    await _processSingleScan(fromCamera: true);
  }

  Future<void> _scanFromGallery() async {
    if (_requiresFrontAndBack) {
      await _scanIdCardFromGallery();
      return;
    }

    await _processSingleScan(fromCamera: false);
  }

  Future<void> _processSingleScan({
    required bool fromCamera,
  }) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final result = fromCamera
          ? await _scanController.scanFromCamera(
              documentType: widget.documentType,
            )
          : await _scanController.scanFromGallery(
              documentType: widget.documentType,
            );

      if (!mounted || result == null) {
        return;
      }

      if (result.text.trim().isEmpty) {
        _showMessage('No text detected. Please try again.');
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OcrResultScreen(result: result),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage('OCR Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _scanIdCardFromCamera() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final frontResult = await _scanController.scanFromCamera(
        documentType: '${widget.documentType} - Front',
      );

      if (!mounted || frontResult == null) {
        return;
      }

      if (frontResult.text.trim().isEmpty) {
        _showMessage('No text detected on the front side.');
        return;
      }

      final shouldContinue = await _showBackSideConfirmation();

      if (!shouldContinue || !mounted) {
        return;
      }

      final backResult = await _scanController.scanFromCamera(
        documentType: '${widget.documentType} - Back',
      );

      if (!mounted || backResult == null) {
        return;
      }

      final combinedText = _combineTexts(
        frontResult.text,
        backResult.text,
      );

      if (combinedText.trim().isEmpty) {
        _showMessage('No text detected on the ID card.');
        return;
      }

      final combinedResult = frontResult.copyWith(
        text: combinedText,
        documentType: widget.documentType,
      );

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OcrResultScreen(result: combinedResult),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage('ID card scanning failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _scanIdCardFromGallery() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final frontResult = await _scanController.scanFromGallery(
        documentType: '${widget.documentType} - Front',
      );

      if (!mounted || frontResult == null) {
        return;
      }

      if (frontResult.text.trim().isEmpty) {
        _showMessage('No text detected on the front side.');
        return;
      }

      final shouldContinue = await _showBackSideConfirmation();

      if (!shouldContinue || !mounted) {
        return;
      }

      final backResult = await _scanController.scanFromGallery(
        documentType: '${widget.documentType} - Back',
      );

      if (!mounted || backResult == null) {
        return;
      }

      final combinedText = _combineTexts(
        frontResult.text,
        backResult.text,
      );

      if (combinedText.trim().isEmpty) {
        _showMessage('No text detected on the ID card.');
        return;
      }

      final combinedResult = frontResult.copyWith(
        text: combinedText,
        documentType: widget.documentType,
      );

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OcrResultScreen(result: combinedResult),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage('ID card scanning failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<bool> _showBackSideConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Front side captured'),
          content: const Text(
            'The front side has been captured. '
            'Now capture the back side of the ID card.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Capture Back'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  String _combineTexts(String frontText, String backText) {
    final front = frontText.trim();
    final back = backText.trim();

    if (front.isEmpty) return back;
    if (back.isEmpty) return front;

    return '''
--- FRONT SIDE ---
$front

--- BACK SIDE ---
$back
''';
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        leading: Icon(
          icon,
          size: 34,
          color: Colors.blue,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
        ),
        onTap: _isProcessing ? null : onTap,
      ),
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.documentType} Scan'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.documentType,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _requiresFrontAndBack
                              ? Icons.flip_camera_android_outlined
                              : Icons.document_scanner_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _scanGuidance,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildOption(
                  icon: Icons.camera_alt_outlined,
                  title: _requiresFrontAndBack
                      ? 'Camera - Front and Back'
                      : 'Camera',
                  subtitle: _requiresFrontAndBack
                      ? 'Capture both sides of the ID card'
                      : 'Capture a new document',
                  onTap: _scanFromCamera,
                ),
                _buildOption(
                  icon: Icons.photo_library_outlined,
                  title: _requiresFrontAndBack
                      ? 'Gallery - Front and Back'
                      : 'Gallery',
                  subtitle: _requiresFrontAndBack
                      ? 'Select front and back images'
                      : 'Select an image from your gallery',
                  onTap: _scanFromGallery,
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
                        Text('Processing document...'),
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