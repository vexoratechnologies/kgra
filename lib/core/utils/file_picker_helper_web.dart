import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'file_picker_helper.dart';

Future<PickedPdfFile?> pickPdfPlatform() async {
  return _pickWebFile('.pdf');
}

Future<PickedPdfFile?> pickVideoPlatform() async {
  return _pickWebFile('video/*');
}

Future<PickedPdfFile?> pickImagePlatform() async {
  return _pickWebFile('image/*');
}

Future<PickedPdfFile?> _pickWebFile(String acceptPattern) async {
  final completer = Completer<PickedPdfFile?>();
  final html.FileUploadInputElement input = html.FileUploadInputElement();
  input.accept = acceptPattern;
  
  input.style.display = 'none';
  html.document.body?.children.add(input);

  input.onChange.listen((event) {
    if (input.files != null && input.files!.isNotEmpty) {
      final file = input.files![0];
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((event) {
        final Uint8List bytes = reader.result as Uint8List;
        completer.complete(PickedPdfFile(bytes: bytes, name: file.name));
        input.remove();
      });
    } else {
      completer.complete(null);
      input.remove();
    }
  });

  html.window.onFocus.first.then((_) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!completer.isCompleted) {
        completer.complete(null);
        input.remove();
      }
    });
  });

  input.click();
  return completer.future;
}
