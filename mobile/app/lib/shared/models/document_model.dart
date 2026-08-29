class DocumentModel {
  final String id;

  final String name;

  final String type;

  final String source;

  final String documentType;

  final DateTime createdAt;

  final String extractedText;

  final String? summary;

  final String? filePath;

  const DocumentModel({
    required this.id,
    required this.name,
    required this.type,
    required this.source,
    required this.documentType,
    required this.createdAt,
    required this.extractedText,
    this.summary,
    this.filePath,
  });

  DocumentModel copyWith({
    String? id,
    String? name,
    String? type,
    String? source,
    String? documentType,
    DateTime? createdAt,
    String? extractedText,
    String? summary,
    String? filePath,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      source: source ?? this.source,
      documentType: documentType ?? this.documentType,
      createdAt: createdAt ?? this.createdAt,
      extractedText: extractedText ?? this.extractedText,
      summary: summary ?? this.summary,
      filePath: filePath ?? this.filePath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'source': source,
      'documentType': documentType,
      'createdAt': createdAt.toIso8601String(),
      'extractedText': extractedText,
      'summary': summary,
      'filePath': filePath,
    };
  }

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      source: json['source'] as String,
      documentType:
          json['documentType'] as String? ?? 'Other',
      createdAt: DateTime.parse(
        json['createdAt'] as String,
      ),
      extractedText:
          json['extractedText'] as String,
      summary: json['summary'] as String?,
      filePath: json['filePath'] as String?,
    );
  }
}