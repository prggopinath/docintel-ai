import 'package:image_picker/image_picker.dart';

import '../../../shared/models/scan_result.dart';
import '../../../services/ocr/text_recognition_service.dart';
import '../../../services/pdf/pdf_ocr_service.dart';
import '../../../services/pdf/pdf_picker_service.dart';
import '../../../services/pdf/pdf_text_service.dart';
import '../../../services/scanner/image_picker_service.dart';
//import 'package:image_cropper/image_cropper.dart';
import 'dart:io';

import 'package:document_scan/document_scan.dart';
import 'package:flutter/foundation.dart';

class ScanController {
  final ImagePickerService _imagePickerService = ImagePickerService();

  final TextRecognitionService _textRecognitionService =
      TextRecognitionService();

  final PdfPickerService _pdfPickerService = PdfPickerService();

  final PdfTextService _pdfTextService = PdfTextService();

  final PdfOcrService _pdfOcrService = PdfOcrService();

  Future<XFile?> pickImageFromCamera() async {
    return await _imagePickerService.pickFromCamera();
  }

  Future<XFile?> pickImageFromGallery() async {
    return await _imagePickerService.pickFromGallery();
  }

  Future<XFile> _autoDetectAndCrop(XFile image) async {
    try {
      final scanned = await DocumentScanner().scan(
        ScanInput.file(image.path),
        filter: ScanFilter.enhance,
        output: ScanOutputFormat.png,
      );

      // If no document boundary is detected, retain the original image.
      if (scanned == null) {
        debugPrint('No document detected; using original image.');
        return image;
      }

      final outputFile = File(
        '${Directory.systemTemp.path}/'
        'docintel_scan_${DateTime.now().microsecondsSinceEpoch}.png',
      );

      await outputFile.writeAsBytes(scanned.bytes, flush: true);

      return XFile(outputFile.path);
    } catch (e, stackTrace) {
      debugPrint('Automatic document scan failed: $e');
      debugPrintStack(stackTrace: stackTrace);

      // Preserve the existing scanning flow if detection fails.
      return image;
    }
  }

  Future<DocumentCorners?> detectDocumentCorners(String imagePath) async {
    try {
      final scanner = DocumentScanner();

      return await scanner.detectCorners(
        ScanInput.file(imagePath),
        sensitivity: DetectionSensitivity.lenient,
      );
    } catch (e, stackTrace) {
      debugPrint('Document detection failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<XFile?> cropImageWithCorners({
    required String imagePath,
    required DocumentCorners corners,
  }) async {
    try {
      final scanner = DocumentScanner();

      final scanned = await scanner.scan(
        ScanInput.file(imagePath),
        corners: corners,
        filter: ScanFilter.enhance,
        output: ScanOutputFormat.png,
      );

      if (scanned == null) {
        return null;
      }

      final outputFile = File(
        '${Directory.systemTemp.path}/'
        'docintel_manual_scan_'
        '${DateTime.now().microsecondsSinceEpoch}.png',
      );

      await outputFile.writeAsBytes(scanned.bytes, flush: true);

      return XFile(outputFile.path);
    } catch (e, stackTrace) {
      debugPrint('Manual document crop failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<ScanResult> scanImage({
    required String path,
    required String fileName,
    required String source,
    required String documentType,
  }) async {
    final text = await _textRecognitionService.recognizeText(path);

    return ScanResult(
      text: text,
      filePath: path,
      fileName: fileName,
      type: 'image',
      source: source,
      documentType: documentType,
    );
  }

  // Kept for compatibility with any existing callers.
  Future<ScanResult?> scanFromCamera({required String documentType}) async {
    final XFile? image = await _imagePickerService.pickFromCamera();

    if (image == null) return null;

    //final XFile? croppedImage = await _cropImage(image);

    //if (croppedImage == null) return null;

    //final String text = await _textRecognitionService.recognizeText(
    //  croppedImage.path,
    //);

    //return ScanResult(
    // text: text,
    // filePath: croppedImage.path,
    // fileName: image.name,
    // type: 'image',
    // source: 'camera',
    // documentType: documentType,
    //);
    final XFile processedImage = await _autoDetectAndCrop(image);

    final String text = await _textRecognitionService.recognizeText(
      processedImage.path,
    );

    return ScanResult(
      text: text,
      filePath: processedImage.path,
      fileName: image.name,
      type: 'image',
      source: 'camera', // Use 'gallery' in scanFromGallery()
      documentType: documentType,
    );
  }

  // Kept for compatibility with any existing callers.
  Future<ScanResult?> scanFromGallery({required String documentType}) async {
    final XFile? image = await _imagePickerService.pickFromGallery();

    if (image == null) return null;

    //final XFile? croppedImage = await _cropImage(image);

    //if (croppedImage == null) return null;

    //final String text = await _textRecognitionService.recognizeText(
    //croppedImage.path,
    //);

    //return ScanResult(
    //text: text,
    //filePath: croppedImage.path,
    //fileName: image.name,
    //type: 'image',
    //source: 'gallery',
    //documentType: documentType,
    //);
    final XFile processedImage = await _autoDetectAndCrop(image);

    final String text = await _textRecognitionService.recognizeText(
      processedImage.path,
    );

    return ScanResult(
      text: text,
      filePath: processedImage.path,
      fileName: image.name,
      type: 'image',
      source: 'gallery', // Use 'gallery' in scanFromGallery()
      documentType: documentType,
    );
  }

  Future<ScanResult?> scanFromPdf({String documentType = 'Other'}) async {
    final path = await _pdfPickerService.pickPdf();

    if (path == null) {
      return null;
    }

    final fileName = path.split('/').last;

    // First try direct text extraction.
    final extractedText = await _pdfTextService.extractText(path);

    if (extractedText.trim().isNotEmpty) {
      return ScanResult(
        text: extractedText,
        filePath: path,
        fileName: fileName,
        type: 'pdf',
        source: 'pdf',
        documentType: documentType,
      );
    }

    // If no embedded text exists, use scanned PDF OCR.
    final ocrText = await _pdfOcrService.extractText(path);

    return ScanResult(
      text: ocrText,
      filePath: path,
      fileName: fileName,
      type: 'pdf',
      source: 'pdf',
      documentType: documentType,
    );
  }

  Future<void> dispose() async {
    await _textRecognitionService.dispose();
    await _pdfOcrService.dispose();
  }

  Future<XFile?> pickImageForPdfFromGallery() async {
    return await _imagePickerService.pickFromGallery();
  }

  Future<XFile?> pickImageForPdfFromCamera() async {
    return await _imagePickerService.pickFromCamera();
  }

  // Future<XFile?> _cropImage(XFile image) async {
  //   final CroppedFile? croppedFile = await ImageCropper().cropImage(
  //     sourcePath: image.path,
  //     uiSettings: [
  //       AndroidUiSettings(
  //         toolbarTitle: 'Crop Document',
  //         initAspectRatio: CropAspectRatioPreset.original,
  //         lockAspectRatio: false,
  //         hideBottomControls: false,
  //       ),
  //       IOSUiSettings(title: 'Crop Document', aspectRatioLockEnabled: false),
  //     ],
  //   );

  //   if (croppedFile == null) {
  //     return null; // User cancelled cropping
  //   }

  //   return XFile(croppedFile.path);
  // }
}
