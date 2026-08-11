import 'dart:typed_data';

import 'package:pdfx/pdfx.dart';

class PdfPageRendererService {
  Future<List<Uint8List>> renderPages(String path) async {
    final document = await PdfDocument.openFile(path);

    final List<Uint8List> images = [];

    try {
      for (int pageNumber = 1;
          pageNumber <= document.pagesCount;
          pageNumber++) {
        final page = await document.getPage(pageNumber);

        try {
          final image = await page.render(
            width: page.width * 2,
            height: page.height * 2,
            format: PdfPageImageFormat.png,
          );

          if (image != null) {
            images.add(image.bytes);
          }
        } finally {
          await page.close();
        }
      }
    } finally {
      await document.close();
    }

    return images;
  }
}