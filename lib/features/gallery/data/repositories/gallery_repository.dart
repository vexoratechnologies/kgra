import 'dart:typed_data';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/storage_service.dart';
import '../models/gallery_image_model.dart';

class GalleryRepository {
  final FirestoreService _firestoreService;
  final StorageService _storageService;

  GalleryRepository({
    required FirestoreService firestoreService,
    required StorageService storageService,
  })  : _firestoreService = firestoreService,
        _storageService = storageService;

  Future<void> addGalleryImage({
    required GalleryImageModel model,
    required Uint8List fileBytes,
  }) async {
    final imageUrl = await _storageService.uploadImage(
      folderName: 'gallery',
      docId: model.id,
      fileName: '${model.id}.jpg',
      fileBytes: fileBytes,
    );
    final updatedModel = model.copyWith(imageUrl: imageUrl);
    await _firestoreService.saveGalleryImage(updatedModel);
  }

  Future<void> updateGalleryImage({
    required GalleryImageModel model,
    Uint8List? fileBytes,
  }) async {
    GalleryImageModel updatedModel = model;
    if (fileBytes != null) {
      final imageUrl = await _storageService.uploadImage(
        folderName: 'gallery',
        docId: model.id,
        fileName: '${model.id}.jpg',
        fileBytes: fileBytes,
      );
      updatedModel = model.copyWith(imageUrl: imageUrl);
    }
    await _firestoreService.saveGalleryImage(updatedModel);
  }

  Future<void> deleteGalleryImage(GalleryImageModel model) async {
    if (model.imageUrl.isNotEmpty) {
      await _storageService.deleteImage(
        folderName: 'gallery',
        docId: model.id,
        url: model.imageUrl,
      );
    }
    await _firestoreService.deleteGalleryImage(model.id);
  }

  Future<List<GalleryImageModel>> getGalleryImages() async {
    return await _firestoreService.getGalleryImages();
  }

  Future<Uint8List?> downloadImage(GalleryImageModel model) async {
    if (model.imageUrl.isEmpty) return null;
    return await _storageService.downloadImage(
      folderName: 'gallery',
      docId: model.id,
      url: model.imageUrl,
    );
  }
}
