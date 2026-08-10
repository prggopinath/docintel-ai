import 'package:file_picker/file_picker.dart';

class PdfPickerService {
  Future<String?> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.single.path == null) {
      return null;
    }

    return result.files.single.path;
  }
}