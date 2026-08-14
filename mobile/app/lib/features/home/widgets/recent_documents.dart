import 'package:flutter/material.dart';

import '../../../features/documents/screens/document_detail_screen.dart';
import '../../../services/storage/document_repository.dart';
import '../../../shared/models/document_model.dart';

class RecentDocuments extends StatefulWidget {
  const RecentDocuments({super.key});

  @override
  State<RecentDocuments> createState() => _RecentDocumentsState();
}

class _RecentDocumentsState extends State<RecentDocuments> {
  final DocumentRepository _repository = DocumentRepository();

  List<DocumentModel> _documents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _deleteDocument(DocumentModel document) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Document?'),
          content: Text(
            'Delete "${document.name}" permanently?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await _repository.delete(document.id);

      if (!mounted) return;

      await _loadDocuments();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document deleted.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to delete document: $e'),
        ),
      );
    }
  }

  Future<void> _loadDocuments() async {
    try {
      final documents = await _repository.getAll();

      if (!mounted) return;

      setState(() {
        _documents = documents.take(5).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return "Just now";
    }

    if (difference.inMinutes < 60) {
      return "${difference.inMinutes} min ago";
    }

    if (difference.inHours < 24) {
      return "${difference.inHours} hr ago";
    }

    if (difference.inDays == 1) {
      return "Yesterday";
    }

    if (difference.inDays < 7) {
      return "${difference.inDays} days ago";
    }

    return "${date.day}/${date.month}/${date.year}";
  }

  IconData _getDocumentIcon(DocumentModel document) {
    if (document.type == "pdf") {
      return Icons.picture_as_pdf_outlined;
    }

    return Icons.image_outlined;
  }

  Future<void> _openDocument(DocumentModel document) async {
    final deleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentDetailScreen(
          document: document,
        ),
      ),
    );

    if (deleted == true && mounted) {
      await _loadDocuments();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Card(
        elevation: 0,
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_documents.isEmpty) {
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
                icon: const Icon(
                  Icons.document_scanner_outlined,
                ),
                label: const Text("Scan First Document"),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _documents.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final document = _documents[index];

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            leading: CircleAvatar(
              child: Icon(
                _getDocumentIcon(document),
              ),
            ),
            title: Text(
              document.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              "${document.source} • ${_formatDate(document.createdAt)}",
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'open') {
                  await _openDocument(document);
                }

                if (value == 'delete') {
                  await _deleteDocument(document);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem<String>(
                  value: 'open',
                  child: ListTile(
                    leading: Icon(Icons.open_in_new),
                    title: Text('Open'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline),
                    title: Text('Delete'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}