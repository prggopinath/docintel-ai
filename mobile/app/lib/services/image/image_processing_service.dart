import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

class ImageProcessingService {
  static const int _maxProcessingDimension = 2500;

  Future<Uint8List> prepareForEditing(String path) async {
    final bytes = await File(path).readAsBytes();
    final image = _decode(bytes);
    return _encode(image);
  }

  Future<Uint8List> rotate(
    Uint8List bytes, {
    int quarterTurns = 1,
  }) async {
    final image = _decode(bytes);
    final turns = quarterTurns % 4;

    if (turns == 0) {
      return bytes;
    }

    final rotated = img.copyRotate(
      image,
      angle: turns * 90,
      interpolation: img.Interpolation.linear,
    );

    return _encode(rotated);
  }

  Future<Uint8List> adjust({
    required Uint8List bytes,
    double brightness = 0,
    double contrast = 0,
  }) async {
    final image = _decode(bytes);

    // image.adjustColor uses 1.0 as the unchanged value.
    final brightnessFactor =
        (1.0 + brightness.clamp(-1.0, 1.0) * 0.5).clamp(0.5, 1.5);

    final contrastFactor =
        (1.0 + contrast.clamp(-1.0, 1.0) * 0.75).clamp(0.25, 1.75);

    final adjusted = img.adjustColor(
      image,
      brightness: brightnessFactor,
      contrast: contrastFactor,
    );

    return _encode(adjusted);
  }

  Future<Uint8List> autoEnhance(Uint8List bytes) async {
    final image = _decode(bytes);

    // Sample the image to estimate overall luminance.
    final largestDimension = math.max(image.width, image.height);
    final step = math.max(1, (largestDimension / 200).round());

    double luminanceSum = 0;
    int samples = 0;

    for (int y = 0; y < image.height; y += step) {
      for (int x = 0; x < image.width; x += step) {
        final pixel = image.getPixel(x, y);
        luminanceSum +=
            (pixel.rNormalized * 0.2126) +
            (pixel.gNormalized * 0.7152) +
            (pixel.bNormalized * 0.0722);
        samples++;
      }
    }

    final averageLuminance =
        samples == 0 ? 0.5 : luminanceSum / samples;

    final brightnessFactor =
        (0.52 / averageLuminance).clamp(0.88, 1.18);

    final enhanced = img.adjustColor(
      image,
      brightness: brightnessFactor,
      contrast: 1.18,
      saturation: 0.90,
    );

    return _encode(enhanced);
  }

  Future<String> saveToTemporaryFile({
    required Uint8List bytes,
    String prefix = 'docurator_scan',
  }) async {
    final directory = Directory.systemTemp;
    final file = File(
      '${directory.path}/${prefix}_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );

    final image = _decode(bytes);
    final jpgBytes = img.encodeJpg(image, quality: 95);

    await file.writeAsBytes(jpgBytes, flush: true);

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

    if (largestDimension > _maxProcessingDimension) {
      if (image.width >= image.height) {
        image = img.copyResize(
          image,
          width: _maxProcessingDimension,
          interpolation: img.Interpolation.linear,
        );
      } else {
        image = img.copyResize(
          image,
          height: _maxProcessingDimension,
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
        quality: 95,
      ),
    );
  }
}