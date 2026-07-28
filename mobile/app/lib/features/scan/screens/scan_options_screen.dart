import 'package:flutter/material.dart';

class ScanOptionsScreen extends StatelessWidget {
  const ScanOptionsScreen({super.key});

  Widget _option(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 34),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title integration coming next'),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Choose Source"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _option(
              context,
              Icons.camera_alt_outlined,
              "Camera",
              "Capture a new document",
            ),
            const SizedBox(height: 16),
            _option(
              context,
              Icons.photo_library_outlined,
              "Gallery",
              "Import from gallery",
            ),
            const SizedBox(height: 16),
            _option(
              context,
              Icons.picture_as_pdf_outlined,
              "PDF",
              "Import PDF document",
            ),
          ],
        ),
      ),
    );
  }
}