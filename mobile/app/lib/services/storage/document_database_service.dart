import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../shared/models/document_model.dart';

class DocumentDatabaseService {
  static const String _databaseName = 'docurator.db';

  // Version 3 adds the documentType column.
  static const int _databaseVersion = 3;

  static const String _tableName = 'documents';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);

    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            source TEXT NOT NULL,
            documentType TEXT NOT NULL DEFAULT 'Other',
            createdAt TEXT NOT NULL,
            extractedText TEXT NOT NULL,
            summary TEXT,
            filePath TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Version 2: add filePath.
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE $_tableName ADD COLUMN filePath TEXT',
          );
        }

        // Version 3: add documentType.
        if (oldVersion < 3) {
          await db.execute(
            '''
            ALTER TABLE $_tableName
            ADD COLUMN documentType TEXT NOT NULL DEFAULT 'Other'
            ''',
          );
        }
      },
    );
  }

  Future<void> saveDocument(DocumentModel document) async {
    final db = await database;

    await db.insert(
      _tableName,
      document.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DocumentModel>> getDocuments() async {
    final db = await database;

    final rows = await db.query(
      _tableName,
      orderBy: 'createdAt DESC',
    );

    return rows.map(DocumentModel.fromJson).toList();
  }

  Future<DocumentModel?> getDocument(String id) async {
    final db = await database;

    final rows = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return DocumentModel.fromJson(rows.first);
  }

  Future<void> deleteDocument(String id) async {
    final db = await database;

    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<void> updateSummary(
    String id,
    String summary,
  ) async {
    final db = await database;

    await db.update(
      _tableName,
      {
        'summary': summary,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}