import '../../../../core/services/firestore_service.dart';
import '../models/live_session_model.dart';

class LiveSessionRepository {
  final FirestoreService _firestoreService;

  LiveSessionRepository({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  Future<void> saveLiveSession(LiveSessionModel session) async {
    await _firestoreService.saveLiveSession(session);
  }

  Future<List<LiveSessionModel>> getLiveSessions() async {
    return await _firestoreService.getLiveSessions();
  }

  Future<void> deleteLiveSession(String id) async {
    await _firestoreService.deleteLiveSession(id);
  }
}
