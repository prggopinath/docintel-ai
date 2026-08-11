import 'package:flutter/material.dart';

import '../../../services/storage/document_repository.dart';
import '../../../shared/models/document_model.dart';

class DocumentTestScreen extends StatefulWidget {
  const DocumentTestScreen({super.key});

  @override
  State<DocumentTestScreen> createState() => _DocumentTestScreenState();
}

class _DocumentTestScreenState extends State<DocumentTestScreen> {
  final DocumentRepository _repository = DocumentRepository();

  List<DocumentModel> _documents = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final documents = await _repository.getAll();

    if (!mounted) return;

    setState(() {
      _documents = documents;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Saved Documents"),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _documents.isEmpty
              ? const Center(
                  child: Text("No documents saved."),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _documents.length,
                  itemBuilder: (context, index) {
                    final document = _documents[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(
                          document.type == "pdf"
                              ? Icons.picture_as_pdf
                              : Icons.image,
                        ),
                        title: Text(document.name),
                        subtitle: Text(
                          "${document.source} • ${document.createdAt}",
                        ),
                        trailing: Text(
                          "${document.extractedText.length} chars",
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}