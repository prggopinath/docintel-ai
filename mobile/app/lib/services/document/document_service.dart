import '../../shared/models/document_model.dart';
import '../storage/document_repository.dart';

class DocumentService {
  final DocumentRepository _repository = DocumentRepository();

  Future<DocumentModel> createAndSaveDocument({
    required String name,
    required String type,
    required String source,
    required String extractedText,
    String? summary,
  }) async {
    final document = DocumentModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      type: type,
      source: source,
      createdAt: DateTime.now(),
      extractedText: extractedText,
      summary: summary,
    );

    await _repository.save(document);

    return document;
  }

  Future<List<DocumentModel>> getDocuments() async {
    return _repository.getAll();
  }

  Future<DocumentModel?> getDocument(String id) async {
    return _repository.getById(id);
  }

  Future<void> deleteDocument(String id) async {
    await _repository.delete(id);
  }
}