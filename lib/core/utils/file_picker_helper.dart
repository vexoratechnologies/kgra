import 'dart:typed_data';
import 'file_picker_helper_stub.dart'
    if (dart.library.html) 'file_picker_helper_web.dart';

Future<PickedPdfFile?> pickPdfFile() => pickPdfPlatform();
Future<PickedPdfFile?> pickVideoFile() => pickVideoPlatform();
Future<PickedPdfFile?> pickImageFile() => pickImagePlatform();

class PickedPdfFile {
  final Uint8List bytes;
  final String name;
  PickedPdfFile({required this.bytes, required this.name});
}
