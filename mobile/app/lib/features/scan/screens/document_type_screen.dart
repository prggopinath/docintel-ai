import 'package:flutter/material.dart';
import 'scan_options_screen.dart';

class DocumentTypeScreen extends StatelessWidget {
  const DocumentTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final documentTypes = [
      ('📄', 'Invoice'),
      ('🧾', 'Receipt'),
      ('📚', 'Book'),
      ('📝', 'Notes'),
      ('🪪', 'ID Card'),
      ('🎓', 'Certificate'),
      ('💼', 'Business Card'),
      ('📑', 'Research Paper'),
      ('📦', 'Other'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Document Type'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.builder(
          itemCount: documentTypes.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemBuilder: (context, index) {
            final item = documentTypes[index];

            return Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                   Navigator.push(
                     context,
                     MaterialPageRoute(
                       builder: (_) => const ScanOptionsScreen(),
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.$1,
                      style: const TextStyle(fontSize: 36),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      item.$2,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}