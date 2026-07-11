import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// StorageService manages file uploads and deletions in Firebase Storage.
class StorageService {
  final SharedPreferences _prefs;

  StorageService({required SharedPreferences prefs}) : _prefs = prefs;

  bool get _useMock => Firebase.apps.isEmpty;

  /// Uploads a PDF to Firebase Storage (or SharedPreferences in mock mode) and returns the download URL.
  Future<String> uploadPdf({
    required String folderName,
    required String docId,
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    if (_useMock) {
      // Mock Storage: store base64 in SharedPreferences
      final base64String = base64Encode(fileBytes);
      await _prefs.setString('mock_storage_${folderName}_${docId}', base64String);
      await _prefs.setString('mock_storage_${folderName}_${docId}_name', fileName);
      return 'mock://storage/$folderName/$docId/$fileName';
    }

    try {
      debugPrint('Initiating Firebase Storage ref for $folderName / $docId.pdf');
      final ref = FirebaseStorage.instance
          .ref()
          .child(folderName)
          .child('$docId.pdf');

      debugPrint('Calling putData with ${fileBytes.length} bytes');
      final uploadTask = ref.putData(
        fileBytes,
        SettableMetadata(contentType: 'application/pdf'),
      );

      uploadTask.snapshotEvents.listen(
        (event) {
          debugPrint('Upload progress: ${event.bytesTransferred} / ${event.totalBytes} (${event.state})');
        },
        onError: (e) {
          debugPrint('Upload error inside stream listener: $e');
        },
      );

      final snapshot = await uploadTask.timeout(const Duration(seconds: 15), onTimeout: () {
        throw TimeoutException('Firebase Storage upload timed out after 15 seconds. Please check your network connection, and make sure your Firebase Storage bucket exists and rules allow uploads.');
      });
      debugPrint('Upload completed successfully. Getting download URL.');
      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('Got download URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Exception caught during uploadPdf: $e');
      rethrow;
    }
  }

  /// Downloads a PDF from mock storage or Firebase Storage.
  Future<Uint8List?> downloadPdf({
    required String folderName,
    required String docId,
    required String url,
  }) async {
    if (_useMock || url.startsWith('mock://')) {
      final base64String = _prefs.getString('mock_storage_${folderName}_${docId}');
      if (base64String != null && base64String.isNotEmpty) {
        return base64Decode(base64String);
      }
      return null;
    }

    try {
      final ref = FirebaseStorage.instance.refFromURL(url);
      final bytes = await ref.getData();
      return bytes;
    } catch (e) {
      debugPrint('Error downloading storage file: $e');
      return null;
    }
  }

  /// Deletes a PDF file from Firebase Storage.
  Future<void> deletePdf({
    required String folderName,
    required String docId,
    required String url,
  }) async {
    if (_useMock || url.startsWith('mock://')) {
      await _prefs.remove('mock_storage_${folderName}_${docId}');
      await _prefs.remove('mock_storage_${folderName}_${docId}_name');
      return;
    }

    try {
      final ref = FirebaseStorage.instance.refFromURL(url);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting storage file: $e');
    }
  }

  /// Uploads a JPEG/PNG image to Firebase Storage (or SharedPreferences in mock mode) and returns the download URL.
  Future<String> uploadImage({
    required String folderName,
    required String docId,
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    if (_useMock) {
      // Mock Storage: store base64 in SharedPreferences
      final base64String = base64Encode(fileBytes);
      await _prefs.setString('mock_storage_${folderName}_${docId}', base64String);
      await _prefs.setString('mock_storage_${folderName}_${docId}_name', fileName);
      return 'mock://storage/$folderName/$docId/$fileName';
    }

    try {
      debugPrint('Initiating Firebase Storage ref for image $folderName / $docId.jpg');
      final ref = FirebaseStorage.instance
          .ref()
          .child(folderName)
          .child('$docId.jpg');

      debugPrint('Calling putData with ${fileBytes.length} bytes');
      final uploadTask = ref.putData(
        fileBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask.timeout(const Duration(seconds: 15), onTimeout: () {
        throw TimeoutException('Firebase Storage upload timed out after 15 seconds.');
      });
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Exception caught during uploadImage: $e');
      rethrow;
    }
  }

  /// Downloads an image from mock storage or Firebase Storage.
  Future<Uint8List?> downloadImage({
    required String folderName,
    required String docId,
    required String url,
  }) async {
    return await downloadPdf(folderName: folderName, docId: docId, url: url);
  }

  /// Deletes an image from mock storage or Firebase Storage.
  Future<void> deleteImage({
    required String folderName,
    required String docId,
    required String url,
  }) async {
    await deletePdf(folderName: folderName, docId: docId, url: url);
  }
}
