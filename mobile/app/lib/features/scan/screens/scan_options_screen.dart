import 'package:flutter/material.dart';

import '../controllers/scan_controller.dart';
import 'ocr_result_screen.dart';

class ScanOptionsScreen extends StatefulWidget {
  const ScanOptionsScreen({super.key});

  @override
  State<ScanOptionsScreen> createState() => _ScanOptionsScreenState();
}

class _ScanOptionsScreenState extends State<ScanOptionsScreen> {
  final ScanController _scanController = ScanController();

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _scanFromCamera() async {
    try {
      final text = await _scanController.scanFromCamera();

      if (!mounted) return;

      if (text == null || text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No text detected."),
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("OCR Error: $e"),
        ),
      );
    }
  }
   
  Future<void> _scanFromGallery() async {
    try {
      final text = await _scanController.scanFromGallery();

      if (!mounted) return;

      if (text == null || text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No text detected."),
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("OCR Error: $e"),
        ),
      );
    }
  }
  
  Future<void> _scanFromPdf() async {
    try {
      final text = await _scanController.scanFromPdf();

      if (!mounted) return;

      if (text == null || text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No text found in this PDF."),
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("PDF Error: $e"),
        ),
      );
    }
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
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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