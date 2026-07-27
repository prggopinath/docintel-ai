import 'package:flutter/material.dart';

class RecentDocuments extends StatelessWidget {
  const RecentDocuments({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 48,
              color: theme.colorScheme.primary,
            ),

            const SizedBox(height: 16),

            Text(
              "No documents yet",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Scan or import a document to get started.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.document_scanner_outlined),
              label: const Text("Scan First Document"),
            ),
          ],
        ),
      ),
    );
  }
}