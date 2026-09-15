import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

class ImageProcessingService {
  static const int maxProcessingDimension = 2000;

  Future<Uint8List> loadForEditing(String path) async {
    final bytes = await File(path).readAsBytes();
    final decoded = _decode(bytes);
    return _encode(decoded);
  }

  Future<String> saveFinalImage({
    required Uint8List sourceBytes,
    required int rotationQuarterTurns,
    required double brightness,
    required double contrast,
    required bool autoEnhance,
    Uint8List? croppedBytes,
  }) async {
    var image = _decode(croppedBytes ?? sourceBytes);

    if (rotationQuarterTurns % 4 != 0) {
      image = img.copyRotate(
        image,
        angle: (rotationQuarterTurns % 4) * 90,
        interpolation: img.Interpolation.linear,
      );
    }

    if (brightness != 0 || contrast != 0) {
      final brightnessFactor =
          (1.0 + brightness.clamp(-1.0, 1.0) * 0.5).clamp(0.5, 1.5);

      final contrastFactor =
          (1.0 + contrast.clamp(-1.0, 1.0) * 0.75).clamp(0.25, 1.75);

      image = img.adjustColor(
        image,
        brightness: brightnessFactor,
        contrast: contrastFactor,
      );
    }

    if (autoEnhance) {
      image = img.adjustColor(
        image,
        contrast: 1.15,
        saturation: 0.90,
      );
    }

    final directory = Directory.systemTemp;
    final file = File(
      '${directory.path}/docurator_scan_'
      '${DateTime.now().microsecondsSinceEpoch}.jpg',
    );

    await file.writeAsBytes(
      img.encodeJpg(image, quality: 94),
      flush: true,
    );

    return file.path;
  }

  img.Image _decode(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      throw const FormatException(
        'Unable to decode the selected image.',
      );
    }

    var image = img.bakeOrientation(decoded);

    final largestDimension = math.max(
      image.width,
      image.height,
    );

    if (largestDimension > maxProcessingDimension) {
      if (image.width >= image.height) {
        image = img.copyResize(
          image,
          width: maxProcessingDimension,
          interpolation: img.Interpolation.linear,
        );
      } else {
        image = img.copyResize(
          image,
          height: maxProcessingDimension,
          interpolation: img.Interpolation.linear,
        );
      }
    }

    return image;
  }

  Uint8List _encode(img.Image image) {
    return Uint8List.fromList(
      img.encodeJpg(
        image,
        quality: 94,
      ),
    );
  }
}