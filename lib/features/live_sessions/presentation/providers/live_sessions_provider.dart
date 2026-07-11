import 'package:flutter/material.dart';
import '../../data/models/live_session_model.dart';
import '../../data/repositories/live_sessions_repository.dart';

class LiveSessionProvider extends ChangeNotifier {
  final LiveSessionRepository _repository;

  LiveSessionProvider({required LiveSessionRepository repository}) : _repository = repository;

  List<LiveSessionModel> _sessions = [];
  bool _isLoading = false;
  String? _error;

  List<LiveSessionModel> get sessionsList => _sessions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void _setError(String? val) {
    _error = val;
    notifyListeners();
  }

  Future<void> fetchLiveSessions() async {
    _setLoading(true);
    _setError(null);
    try {
      _sessions = await _repository.getLiveSessions();
    } catch (e) {
      _setError('Failed to fetch live sessions: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addLiveSession(LiveSessionModel session) async {
    _setError(null);
    try {
      await _repository.saveLiveSession(session);
      await fetchLiveSessions();
      return true;
    } catch (e) {
      _setError('Failed to add live session: ${e.toString()}');
      return false;
    }
  }

  Future<bool> updateLiveSession(LiveSessionModel session) async {
    _setError(null);
    try {
      await _repository.saveLiveSession(session);
      await fetchLiveSessions();
      return true;
    } catch (e) {
      _setError('Failed to update live session: ${e.toString()}');
      return false;
    }
  }

  Future<bool> deleteLiveSession(String id) async {
    _setError(null);
    try {
      await _repository.deleteLiveSession(id);
      _sessions.removeWhere((s) => s.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete live session: ${e.toString()}');
      return false;
    }
  }
}
