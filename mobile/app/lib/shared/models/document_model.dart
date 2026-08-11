class DocumentModel {
  final String id;
  final String name;
  final String type;
  final String source;
  final DateTime createdAt;
  final String extractedText;
  final String? summary;

  const DocumentModel({
    required this.id,
    required this.name,
    required this.type,
    required this.source,
    required this.createdAt,
    required this.extractedText,
    this.summary,
  });

  DocumentModel copyWith({
    String? id,
    String? name,
    String? type,
    String? source,
    DateTime? createdAt,
    String? extractedText,
    String? summary,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      extractedText: extractedText ?? this.extractedText,
      summary: summary ?? this.summary,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'source': source,
      'createdAt': createdAt.toIso8601String(),
      'extractedText': extractedText,
      'summary': summary,
    };
  }

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      source: json['source'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      extractedText: json['extractedText'] as String,
      summary: json['summary'] as String?,
    );
  }
}