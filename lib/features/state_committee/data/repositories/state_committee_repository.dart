import '../../../../core/services/firestore_service.dart';
import '../models/committee_member_model.dart';

class StateCommitteeRepository {
  final FirestoreService _firestoreService;

  StateCommitteeRepository({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  Future<void> addMember(CommitteeMemberModel member) async {
    await _firestoreService.saveCommitteeMember(member.id, member.toJson());
  }

  Future<void> updateMember(CommitteeMemberModel member) async {
    await _firestoreService.saveCommitteeMember(member.id, member.toJson());
  }

  Future<void> deleteMember(String id) async {
    await _firestoreService.deleteCommitteeMember(id);
  }

  Future<List<CommitteeMemberModel>> getAllMembers() async {
    final list = await _firestoreService.getCommitteeMembers();
    return list.map((item) => CommitteeMemberModel.fromJson(item)).toList();
  }
}
