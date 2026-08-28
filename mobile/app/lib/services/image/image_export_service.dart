import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

class ImageExportService {
  Future<bool> saveImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Image',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['png'],
      bytes: bytes,
    );

    return outputPath != null;
  }

  Future<void> shareImage({
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
            mimeType: 'image/png',
          ),
        ],
        subject: fileName,
        text: 'Converted PDF page',
      ),
    );
  }
}