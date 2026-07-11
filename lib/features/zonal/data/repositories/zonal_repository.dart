import '../../../../core/services/firestore_service.dart';
import '../models/zonal_member_model.dart';

class ZonalRepository {
  final FirestoreService _firestoreService;

  ZonalRepository({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  Future<void> saveZonalMember(ZonalMemberModel member) async {
    await _firestoreService.saveZonalMember(member);
  }

  Future<List<ZonalMemberModel>> getZonalMembers() async {
    return await _firestoreService.getZonalMembers();
  }

  Future<void> deleteZonalMember(String id) async {
    await _firestoreService.deleteZonalMember(id);
  }
}
