class ScanResult {
  final String text;
  final String filePath;
  final String fileName;
  final String type;
  final String source;
  final String documentType;

  const ScanResult({
    required this.text,
    required this.filePath,
    required this.fileName,
    required this.type,
    required this.source,
    required this.documentType,
  });

  ScanResult copyWith({
    String? text,
    String? filePath,
    String? fileName,
    String? type,
    String? source,
    String? documentType,
  }) {
    return ScanResult(
      text: text ?? this.text,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      type: type ?? this.type,
      source: source ?? this.source,
      documentType: documentType ?? this.documentType,
    );
  }
}