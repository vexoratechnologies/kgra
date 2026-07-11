import 'package:flutter/material.dart';
import '../../data/models/zonal_member_model.dart';
import '../../data/repositories/zonal_repository.dart';

class ZonalProvider extends ChangeNotifier {
  final ZonalRepository _repository;

  ZonalProvider({required ZonalRepository repository}) : _repository = repository;

  List<ZonalMemberModel> _members = [];
  bool _isLoading = false;
  String? _error;

  List<ZonalMemberModel> get members => _members;
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

  Future<void> fetchMembers() async {
    _setLoading(true);
    _setError(null);
    try {
      _members = await _repository.getZonalMembers();
    } catch (e) {
      _setError('Failed to fetch zonal members: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addMember(ZonalMemberModel member) async {
    _setError(null);
    try {
      await _repository.saveZonalMember(member);
      await fetchMembers();
      return true;
    } catch (e) {
      _setError('Failed to add zonal member: ${e.toString()}');
      return false;
    }
  }

  Future<bool> updateMember(ZonalMemberModel member) async {
    _setError(null);
    try {
      await _repository.saveZonalMember(member);
      await fetchMembers();
      return true;
    } catch (e) {
      _setError('Failed to update zonal member: ${e.toString()}');
      return false;
    }
  }

  Future<bool> deleteMember(String id) async {
    _setError(null);
    try {
      await _repository.deleteZonalMember(id);
      _members.removeWhere((m) => m.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete zonal member: ${e.toString()}');
      return false;
    }
  }
}
