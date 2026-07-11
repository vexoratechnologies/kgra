import 'dart:typed_data';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/constants/firestore_constants.dart';
import '../models/meeting_minutes_model.dart';

class MeetingMinutesRepository {
  final FirestoreService _firestoreService;
  final StorageService _storageService;

  MeetingMinutesRepository({
    required FirestoreService firestoreService,
    required StorageService storageService,
  })  : _firestoreService = firestoreService,
        _storageService = storageService;

  Future<void> addMeetingMinutes({
    required MeetingMinutesModel model,
    required Uint8List pdfBytes,
  }) async {
    final pdfUrl = await _storageService.uploadPdf(
      folderName: 'meeting_minutes',
      docId: model.id,
      fileName: model.pdfName,
      fileBytes: pdfBytes,
    );
    final updatedModel = model.copyWith(pdfUrl: pdfUrl);
    await _firestoreService.saveDocumentMetadata(
      FirestoreCollections.meetingMinutes,
      model.id,
      updatedModel.toJson(),
    );
  }

  Future<void> updateMeetingMinutes({
    required MeetingMinutesModel model,
    Uint8List? pdfBytes,
  }) async {
    MeetingMinutesModel updatedModel = model;
    if (pdfBytes != null) {
      final pdfUrl = await _storageService.uploadPdf(
        folderName: 'meeting_minutes',
        docId: model.id,
        fileName: model.pdfName,
        fileBytes: pdfBytes,
      );
      updatedModel = model.copyWith(pdfUrl: pdfUrl);
    }
    await _firestoreService.saveDocumentMetadata(
      FirestoreCollections.meetingMinutes,
      model.id,
      updatedModel.toJson(),
    );
  }

  Future<void> deleteMeetingMinutes(MeetingMinutesModel model) async {
    if (model.pdfUrl.isNotEmpty) {
      await _storageService.deletePdf(
        folderName: 'meeting_minutes',
        docId: model.id,
        url: model.pdfUrl,
      );
    }
    await _firestoreService.deleteDocumentMetadata(
      FirestoreCollections.meetingMinutes,
      model.id,
    );
  }

  Future<List<MeetingMinutesModel>> getAllMeetingMinutes() async {
    final list = await _firestoreService.getDocumentsList(
      FirestoreCollections.meetingMinutes,
    );
    return list.map((item) => MeetingMinutesModel.fromJson(item)).toList();
  }

  Future<Uint8List?> downloadMeetingMinutesPdf(MeetingMinutesModel model) async {
    if (model.pdfUrl.isEmpty) return null;
    return await _storageService.downloadPdf(
      folderName: 'meeting_minutes',
      docId: model.id,
      url: model.pdfUrl,
    );
  }

  Future<void> updateMeetingMinutesStatus(String id, String status) async {
    final list = await getAllMeetingMinutes();
    final index = list.indexWhere((m) => m.id == id);
    if (index != -1) {
      final updatedModel = list[index].copyWith(status: status);
      await _firestoreService.saveDocumentMetadata(
        FirestoreCollections.meetingMinutes,
        id,
        updatedModel.toJson(),
      );
    }
  }
}
