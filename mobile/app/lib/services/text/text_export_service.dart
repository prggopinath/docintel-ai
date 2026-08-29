import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

class TextExportService {
  Future<bool> saveText({
    required String text,
    required String fileName,
  }) async {
    final bytes = Uint8List.fromList(
      text.codeUnits,
    );

    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Text',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['txt'],
      bytes: bytes,
    );

    return outputPath != null;
  }

  Future<void> shareText({
    required String text,
    required String fileName,
  }) async {
    final tempDirectory = Directory.systemTemp;

    final file = File(
      '${tempDirectory.path}/$fileName',
    );

    await file.writeAsString(text);

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            file.path,
            mimeType: 'text/plain',
          ),
        ],
        subject: fileName,
        text: 'Extracted document text',
      ),
    );
  }
}