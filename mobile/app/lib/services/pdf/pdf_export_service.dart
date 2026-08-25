import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

class PdfExportService {
  Future<bool> savePdf({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save PDF',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (outputPath == null) {
      return false;
    }

    final outputFile = File(outputPath);

    await outputFile.writeAsBytes(bytes);

    return true;
  }

  Future<void> sharePdf({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final tempDirectory = Directory.systemTemp;

    final file = File(
      '${tempDirectory.path}/$fileName',
    );

    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            file.path,
            mimeType: 'application/pdf',
          ),
        ],
        subject: fileName,
        text: 'PDF document',
      ),
    );
  }
}