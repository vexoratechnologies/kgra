import 'dart:typed_data';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/constants/firestore_constants.dart';
import '../models/government_order_model.dart';

class GovernmentOrderRepository {
  final FirestoreService _firestoreService;
  final StorageService _storageService;

  GovernmentOrderRepository({
    required FirestoreService firestoreService,
    required StorageService storageService,
  })  : _firestoreService = firestoreService,
        _storageService = storageService;

  Future<void> addGovernmentOrder({
    required GovernmentOrderModel model,
    required Uint8List pdfBytes,
  }) async {
    final pdfUrl = await _storageService.uploadPdf(
      folderName: 'government_orders',
      docId: model.id,
      fileName: model.pdfName,
      fileBytes: pdfBytes,
    );
    final updatedModel = model.copyWith(pdfUrl: pdfUrl);
    await _firestoreService.saveDocumentMetadata(
      FirestoreCollections.governmentOrders,
      model.id,
      updatedModel.toJson(),
    );
  }

  Future<void> updateGovernmentOrder({
    required GovernmentOrderModel model,
    Uint8List? pdfBytes,
  }) async {
    GovernmentOrderModel updatedModel = model;
    if (pdfBytes != null) {
      final pdfUrl = await _storageService.uploadPdf(
        folderName: 'government_orders',
        docId: model.id,
        fileName: model.pdfName,
        fileBytes: pdfBytes,
      );
      updatedModel = model.copyWith(pdfUrl: pdfUrl);
    }
    await _firestoreService.saveDocumentMetadata(
      FirestoreCollections.governmentOrders,
      model.id,
      updatedModel.toJson(),
    );
  }

  Future<void> deleteGovernmentOrder(GovernmentOrderModel model) async {
    if (model.pdfUrl.isNotEmpty) {
      await _storageService.deletePdf(
        folderName: 'government_orders',
        docId: model.id,
        url: model.pdfUrl,
      );
    }
    await _firestoreService.deleteDocumentMetadata(
      FirestoreCollections.governmentOrders,
      model.id,
    );
  }

  Future<List<GovernmentOrderModel>> getAllGovernmentOrders() async {
    final list = await _firestoreService.getDocumentsList(
      FirestoreCollections.governmentOrders,
    );
    return list.map((item) => GovernmentOrderModel.fromJson(item)).toList();
  }

  Future<Uint8List?> downloadGovernmentOrderPdf(GovernmentOrderModel model) async {
    if (model.pdfUrl.isEmpty) return null;
    return await _storageService.downloadPdf(
      folderName: 'government_orders',
      docId: model.id,
      url: model.pdfUrl,
    );
  }
}
