import '../../shared/models/document_model.dart';
import 'document_database_service.dart';

class DocumentRepository {
  final DocumentDatabaseService _databaseService =
      DocumentDatabaseService();

  Future<void> save(DocumentModel document) async {
    await _databaseService.saveDocument(document);
  }

  Future<List<DocumentModel>> getAll() async {
    return _databaseService.getDocuments();
  }

  Future<DocumentModel?> getById(String id) async {
    return _databaseService.getDocument(id);
  }

  Future<void> delete(String id) async {
    await _databaseService.deleteDocument(id);
  }

  Future<void> close() async {
    await _databaseService.close();
  }

  Future<void> updateSummary(
    String id,
    String summary,
  ) async {
    await _databaseService.updateSummary(
      id,
      summary,
    );
  }
}