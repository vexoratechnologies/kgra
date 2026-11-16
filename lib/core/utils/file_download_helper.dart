import 'dart:typed_data';
import 'file_download_helper_stub.dart'
    if (dart.library.html) 'file_download_helper_web.dart';

/// Cross-platform file download and export utility.
///
/// On Web: Triggers browser file download via an anchor element.
/// On Mobile (Android/iOS): Saves to a local directory and triggers native Share/Save sheet.
/// On Desktop (macOS/Windows/Linux): Opens the native save file dialog or saves to Downloads.
Future<String?> downloadFile({
  required Uint8List bytes,
  required String fileName,
  String mimeType =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
}) =>
    downloadFilePlatform(
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
    );

