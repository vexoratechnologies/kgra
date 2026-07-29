import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'file_picker_helper.dart';

Future<PickedPdfFile?> pickPdfPlatform() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf'],
    withData: true,
  );
  if (result != null && result.files.single.bytes != null) {
    return PickedPdfFile(
      bytes: result.files.single.bytes!,
      name: result.files.single.name,
    );
  }
  return null;
}

Future<PickedPdfFile?> pickVideoPlatform() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.video,
    withData: true,
  );
  if (result != null && result.files.single.bytes != null) {
    return PickedPdfFile(
      bytes: result.files.single.bytes!,
      name: result.files.single.name,
    );
  }
  return null;
}

Future<PickedPdfFile?> pickImagePlatform() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    withData: true,
  );
  if (result != null && result.files.single.bytes != null) {
    return PickedPdfFile(
      bytes: result.files.single.bytes!,
      name: result.files.single.name,
    );
  }
  return null;
}
