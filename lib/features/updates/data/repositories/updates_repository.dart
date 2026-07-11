import '../../../../core/services/firestore_service.dart';
import '../models/update_model.dart';

class UpdatesRepository {
  final FirestoreService _firestoreService;

  UpdatesRepository({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  Future<void> saveUpdate(UpdateModel update) async {
    await _firestoreService.saveUpdate(update);
  }

  Future<List<UpdateModel>> getUpdates() async {
    return await _firestoreService.getUpdates();
  }

  Future<void> deleteUpdate(String id) async {
    await _firestoreService.deleteUpdate(id);
  }
}
