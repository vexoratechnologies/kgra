import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Non-web (native) platform implementation for Android, iOS, macOS, Windows, Linux.
Future<String?> downloadFilePlatform({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  try {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);

      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(file.path, mimeType: mimeType, name: fileName)],
        subject: fileName,
        text: fileName,
      );
      return file.path;
    } else {
      // Desktop: macOS, Windows, Linux
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Spreadsheet File',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        bytes: bytes,
      );

      if (savePath != null) {
        final file = File(savePath);
        if (!await file.exists() || (await file.length()) != bytes.length) {
          await file.writeAsBytes(bytes, flush: true);
        }
        return savePath;
      }
      return null;
    }
  } catch (e) {
    debugPrint('[downloadFilePlatform] Error saving file: $e');
    return null;
  }
}
