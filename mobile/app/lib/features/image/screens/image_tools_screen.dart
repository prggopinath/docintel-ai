import 'package:flutter/material.dart';

import '../../pdf/screens/create_pdf_screen.dart';
import '../../scan/screens/document_type_screen.dart';

class ImageToolsScreen extends StatelessWidget {
  const ImageToolsScreen({super.key});

  void _openScreen(
    BuildContext context,
    Widget screen,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => screen,
      ),
    );
  }

  Widget _buildToolCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor:
              theme.colorScheme.primaryContainer,
          child: Icon(
            icon,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Tools'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Image Tools',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 8),

            Text(
              'Convert and work with your images.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 24),

            _buildToolCard(
              context: context,
              icon: Icons.picture_as_pdf_outlined,
              title: 'Image to PDF',
              subtitle:
                  'Create a PDF from one or more images.',
              onTap: () {
                _openScreen(
                  context,
                  const CreatePdfScreen(),
                );
              },
            ),

            _buildToolCard(
              context: context,
              icon: Icons.text_snippet_outlined,
              title: 'Image to Text',
              subtitle:
                  'Extract text from an image using OCR.',
              onTap: () {
                _openScreen(
                  context,
                  const DocumentTypeScreen(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}