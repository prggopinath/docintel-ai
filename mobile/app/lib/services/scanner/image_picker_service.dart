import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickFromCamera() async {
    return await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 100,
    );
  }

  Future<XFile?> pickFromGallery() async {
    return await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
  }
}