import 'dart:typed_data';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/constants/firestore_constants.dart';
import '../models/form_circular_model.dart';

class FormCircularRepository {
  final FirestoreService _firestoreService;
  final StorageService _storageService;

  FormCircularRepository({
    required FirestoreService firestoreService,
    required StorageService storageService,
  })  : _firestoreService = firestoreService,
        _storageService = storageService;

  Future<void> addFormCircular({
    required FormCircularModel model,
    Uint8List? pdfBytes,
  }) async {
    FormCircularModel updatedModel = model;
    if (pdfBytes != null) {
      final pdfUrl = await _storageService.uploadPdf(
        folderName: 'forms_circulars',
        docId: model.id,
        fileName: model.pdfName,
        fileBytes: pdfBytes,
      );
      updatedModel = model.copyWith(pdfUrl: pdfUrl);
    }
    await _firestoreService.saveDocumentMetadata(
      FirestoreCollections.formsCirculars,
      model.id,
      updatedModel.toJson(),
    );
  }

  Future<void> updateFormCircular({
    required FormCircularModel model,
    Uint8List? pdfBytes,
  }) async {
    FormCircularModel updatedModel = model;
    if (pdfBytes != null) {
      final pdfUrl = await _storageService.uploadPdf(
        folderName: 'forms_circulars',
        docId: model.id,
        fileName: model.pdfName,
        fileBytes: pdfBytes,
      );
      updatedModel = model.copyWith(pdfUrl: pdfUrl);
    }
    await _firestoreService.saveDocumentMetadata(
      FirestoreCollections.formsCirculars,
      model.id,
      updatedModel.toJson(),
    );
  }

  Future<void> deleteFormCircular(FormCircularModel model) async {
    if (model.pdfUrl.isNotEmpty) {
      await _storageService.deletePdf(
        folderName: 'forms_circulars',
        docId: model.id,
        url: model.pdfUrl,
      );
    }
    await _firestoreService.deleteDocumentMetadata(
      FirestoreCollections.formsCirculars,
      model.id,
    );
  }

  Future<List<FormCircularModel>> getAllFormCirculars() async {
    final list = await _firestoreService.getDocumentsList(
      FirestoreCollections.formsCirculars,
    );
    return list.map((item) => FormCircularModel.fromJson(item)).toList();
  }

  Future<Uint8List?> downloadFormCircularPdf(FormCircularModel model) async {
    if (model.pdfUrl.isEmpty) return null;
    return await _storageService.downloadPdf(
      folderName: 'forms_circulars',
      docId: model.id,
      url: model.pdfUrl,
    );
  }
}
