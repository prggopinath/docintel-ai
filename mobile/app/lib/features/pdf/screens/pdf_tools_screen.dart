import 'package:flutter/material.dart';

import 'create_pdf_screen.dart';
import 'pdf_to_image_screen.dart';
import 'pdf_to_text_screen.dart';

class PdfToolsScreen extends StatelessWidget {
  const PdfToolsScreen({super.key});

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
        title: const Text('PDF Tools'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PDF Tools',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 8),

            Text(
              'Create, convert and work with your PDF documents.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 24),

            _buildToolCard(
              context: context,
              icon: Icons.picture_as_pdf_outlined,
              title: 'Create PDF',
              subtitle:
                  'Create a multi-page PDF from camera or gallery images.',
              onTap: () {
                _openScreen(
                  context,
                  const CreatePdfScreen(),
                );
              },
            ),

            _buildToolCard(
              context: context,
              icon: Icons.image_outlined,
              title: 'PDF to Image',
              subtitle:
                  'Convert PDF pages into PNG images.',
              onTap: () {
                _openScreen(
                  context,
                  const PdfToImageScreen(),
                );
              },
            ),

            _buildToolCard(
              context: context,
              icon: Icons.text_snippet_outlined,
              title: 'PDF to Text',
              subtitle:
                  'Extract text from PDF documents.',
              onTap: () {
                _openScreen(
                  context,
                  const PdfToTextScreen(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}