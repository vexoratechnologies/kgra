import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// StorageService manages file uploads and deletions in Firebase Storage.
class StorageService {
  StorageService();

  /// Uploads a PDF to Firebase Storage and returns the download URL.
  Future<String> uploadPdf({
    required String folderName,
    required String docId,
    required String fileName,
    required Uint8List fileBytes,
  }) async {
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

  /// Downloads a PDF from Firebase Storage.
  Future<Uint8List?> downloadPdf({
    required String folderName,
    required String docId,
    required String url,
  }) async {
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
    try {
      final ref = FirebaseStorage.instance.refFromURL(url);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting storage file: $e');
    }
  }

  /// Uploads a JPEG/PNG image to Firebase Storage and returns the download URL.
  Future<String> uploadImage({
    required String folderName,
    required String docId,
    required String fileName,
    required Uint8List fileBytes,
    Function(double progress)? onProgress,
  }) async {
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

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((event) {
          if (event.totalBytes > 0) {
            final progress = event.bytesTransferred / event.totalBytes;
            onProgress(progress);
          }
        });
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Exception caught during uploadImage: $e');
      rethrow;
    }
  }

  /// Downloads an image from Firebase Storage.
  Future<Uint8List?> downloadImage({
    required String folderName,
    required String docId,
    required String url,
  }) async {
    return await downloadPdf(folderName: folderName, docId: docId, url: url);
  }

  /// Deletes an image from Firebase Storage.
  Future<void> deleteImage({
    required String folderName,
    required String docId,
    required String url,
  }) async {
    await deletePdf(folderName: folderName, docId: docId, url: url);
  }

  /// Uploads a Video to Firebase Storage and returns the download URL.
  Future<String> uploadVideo({
    required String folderName,
    required String docId,
    required String fileName,
    required Uint8List fileBytes,
    Function(double progress)? onProgress,
  }) async {
    try {
      debugPrint('Initiating Firebase Storage ref for video $folderName / $docId.mp4');
      final ref = FirebaseStorage.instance
          .ref()
          .child(folderName)
          .child('$docId.mp4');

      debugPrint('Calling putData with ${fileBytes.length} bytes');
      final uploadTask = ref.putData(
        fileBytes,
        SettableMetadata(contentType: 'video/mp4'),
      );

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((event) {
          if (event.totalBytes > 0) {
            final progress = event.bytesTransferred / event.totalBytes;
            onProgress(progress);
          }
        });
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Exception caught during uploadVideo: $e');
      rethrow;
    }
  }
}
