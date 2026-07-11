import 'dart:typed_data';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/storage_service.dart';
import '../models/ad_model.dart';

class AdRepository {
  final FirestoreService _firestoreService;
  final StorageService _storageService;

  AdRepository({
    required FirestoreService firestoreService,
    required StorageService storageService,
  })  : _firestoreService = firestoreService,
        _storageService = storageService;

  Future<void> addAd({
    required AdModel model,
    required Uint8List fileBytes,
  }) async {
    final imageUrl = await _storageService.uploadImage(
      folderName: 'ads',
      docId: model.id,
      fileName: '${model.id}.jpg',
      fileBytes: fileBytes,
    );
    final updatedModel = model.copyWith(imageUrl: imageUrl);
    await _firestoreService.saveAd(updatedModel);
  }

  Future<void> updateAd({
    required AdModel model,
    Uint8List? fileBytes,
  }) async {
    AdModel updatedModel = model;
    if (fileBytes != null) {
      final imageUrl = await _storageService.uploadImage(
        folderName: 'ads',
        docId: model.id,
        fileName: '${model.id}.jpg',
        fileBytes: fileBytes,
      );
      updatedModel = model.copyWith(imageUrl: imageUrl);
    }
    await _firestoreService.saveAd(updatedModel);
  }

  Future<void> deleteAd(AdModel ad) async {
    if (ad.imageUrl.isNotEmpty) {
      await _storageService.deleteImage(
        folderName: 'ads',
        docId: ad.id,
        url: ad.imageUrl,
      );
    }
    await _firestoreService.deleteAd(ad.id);
  }

  Future<List<AdModel>> getAds() async {
    return await _firestoreService.getAds();
  }
}
