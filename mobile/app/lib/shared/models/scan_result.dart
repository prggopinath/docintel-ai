class ScanResult {
  final String text;
  final String filePath;
  final String fileName;
  final String type;
  final String source;

  const ScanResult({
    required this.text,
    required this.filePath,
    required this.fileName,
    required this.type,
    required this.source,
  });
}