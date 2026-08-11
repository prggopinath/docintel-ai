import 'package:flutter/material.dart';

import '../controllers/scan_controller.dart';
import 'ocr_result_screen.dart';
import 'scan_processing_screen.dart';

class ScanOptionsScreen extends StatefulWidget {
  const ScanOptionsScreen({super.key});

  @override
  State<ScanOptionsScreen> createState() => _ScanOptionsScreenState();
}

class _ScanOptionsScreenState extends State<ScanOptionsScreen> {
  final ScanController _scanController = ScanController();

  bool _isProcessing = false;

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _processScan({
    required Future<String?> Function() scanFunction,
    required String title,
    required String message,
    required String emptyMessage,
    required String errorPrefix,
  }) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final text = await scanFunction();

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      if (text == null || text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(emptyMessage),
          ),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OcrResultScreen(text: text),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$errorPrefix: $e"),
        ),
      );
    }
  }

  Future<void> _scanFromCamera() {
    return _processScan(
      scanFunction: _scanController.scanFromCamera,
      title: "Scanning Document",
      message: "Reading the document using your camera...",
      emptyMessage: "No text detected.",
      errorPrefix: "OCR Error",
    );
  }

  Future<void> _scanFromGallery() {
    return _processScan(
      scanFunction: _scanController.scanFromGallery,
      title: "Processing Image",
      message: "Extracting text from the selected image...",
      emptyMessage: "No text detected.",
      errorPrefix: "OCR Error",
    );
  }

  Future<void> _scanFromPdf() {
    return _processScan(
      scanFunction: _scanController.scanFromPdf,
      title: "Processing PDF",
      message: "Extracting text from your PDF document...",
      emptyMessage: "No text found in this PDF.",
      errorPrefix: "PDF Error",
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
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: _isProcessing ? null : onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isProcessing) {
      return const ScanProcessingScreen(
        title: "Processing Document",
        message: "Please wait while Docurator extracts the text.",
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Choose Scan Source"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildOption(
              icon: Icons.camera_alt_outlined,
              title: "Camera",
              subtitle: "Capture a new document",
              onTap: _scanFromCamera,
            ),
            _buildOption(
              icon: Icons.photo_library_outlined,
              title: "Gallery",
              subtitle: "Select an image from your gallery",
              onTap: _scanFromGallery,
            ),
            _buildOption(
              icon: Icons.picture_as_pdf_outlined,
              title: "PDF",
              subtitle: "Select a PDF document",
              onTap: _scanFromPdf,
            ),
          ],
        ),
      ),
    );
  }
}