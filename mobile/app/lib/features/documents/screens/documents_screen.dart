import 'package:flutter/material.dart';

import '../../../services/storage/document_repository.dart';
import '../../../shared/models/document_model.dart';
import 'document_detail_screen.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final DocumentRepository _repository = DocumentRepository();

  List<DocumentModel> _documents = [];
  List<DocumentModel> _filteredDocuments = [];

  bool _isLoading = true;

  String _searchQuery = '';
  String _selectedType = 'All';
  String _sortOrder = 'Newest';

  final List<String> _documentTypes = [
    'All',
    'Invoice',
    'Receipt',
    'Book',
    'Notes',
    'ID Card',
    'Certificate',
    'Business Card',
    'Research Paper',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    try {
      final documents = await _repository.getAll();

      if (!mounted) return;

      setState(() {
        _documents = documents;
        _isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to load documents: $e'),
        ),
      );
    }
  }

  void _applyFilters() {
    List<DocumentModel> results = List.from(_documents);

    if (_selectedType != 'All') {
      results = results
          .where(
            (document) =>
                document.documentType.toLowerCase() ==
                _selectedType.toLowerCase(),
          )
          .toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();

      results = results.where((document) {
        return document.name.toLowerCase().contains(query) ||
            document.extractedText.toLowerCase().contains(query) ||
            document.documentType.toLowerCase().contains(query);
      }).toList();
    }

    if (_sortOrder == 'Newest') {
      results.sort(
        (a, b) => b.createdAt.compareTo(a.createdAt),
      );
    } else {
      results.sort(
        (a, b) => a.createdAt.compareTo(b.createdAt),
      );
    }

    setState(() {
      _filteredDocuments = results;
    });
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

    if (!mounted) return;

    if (deleted == true) {
      await _loadDocuments();
    }
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  IconData _getDocumentIcon(DocumentModel document) {
    switch (document.documentType.toLowerCase()) {
      case 'invoice':
        return Icons.receipt_long_outlined;
      case 'receipt':
        return Icons.receipt_outlined;
      case 'book':
        return Icons.menu_book_outlined;
      case 'notes':
        return Icons.note_alt_outlined;
      case 'id card':
        return Icons.badge_outlined;
      case 'certificate':
        return Icons.workspace_premium_outlined;
      case 'business card':
        return Icons.contact_page_outlined;
      case 'research paper':
        return Icons.article_outlined;
      default:
        if (document.type.toLowerCase() == 'pdf') {
          return Icons.picture_as_pdf_outlined;
        }

        return Icons.image_outlined;
    }
  }

  Widget _buildDocumentCard(DocumentModel document) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
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
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${document.documentType} • '
            '${document.source} • '
            '${_formatDate(document.createdAt)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        onTap: () => _openDocument(document),
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
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasFilters =
        _searchQuery.trim().isNotEmpty || _selectedType != 'All';

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                hasFilters
                    ? Icons.search_off_outlined
                    : Icons.folder_open_outlined,
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                hasFilters
                    ? 'No matching documents'
                    : 'No documents yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                hasFilters
                    ? 'Try changing your search or filter.'
                    : 'Your scanned and imported documents will appear here.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadDocuments,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Document Library',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      '${_documents.length} '
                      '${_documents.length == 1 ? 'document' : 'documents'}',
                      style: theme.textTheme.bodyMedium,
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search documents...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                tooltip: 'Clear search',
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                  _applyFilters();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onChanged: (value) {
                        _searchQuery = value;
                        _applyFilters();
                      },
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedType,
                            decoration: InputDecoration(
                              labelText: 'Type',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            items: _documentTypes
                                .map(
                                  (type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;

                              setState(() {
                                _selectedType = value;
                              });

                              _applyFilters();
                            },
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _sortOrder,
                            decoration: InputDecoration(
                              labelText: 'Sort',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Newest',
                                child: Text('Newest'),
                              ),
                              DropdownMenuItem(
                                value: 'Oldest',
                                child: Text('Oldest'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;

                              setState(() {
                                _sortOrder = value;
                              });

                              _applyFilters();
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    if (_filteredDocuments.isEmpty)
                      _buildEmptyState()
                    else
                      ..._filteredDocuments.map(_buildDocumentCard),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}