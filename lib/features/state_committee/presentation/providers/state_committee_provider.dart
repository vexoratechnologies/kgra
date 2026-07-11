import 'package:flutter/material.dart';
import '../../data/models/committee_member_model.dart';
import '../../data/repositories/state_committee_repository.dart';

class StateCommitteeProvider extends ChangeNotifier {
  final StateCommitteeRepository _repository;

  StateCommitteeProvider({required StateCommitteeRepository repository})
      : _repository = repository;

  List<CommitteeMemberModel> _members = [];
  bool _isLoading = false;
  String? _error;

  List<CommitteeMemberModel> get members => _members;
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
      _members = await _repository.getAllMembers();
    } catch (e) {
      _setError('Failed to fetch members: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addMember(CommitteeMemberModel member) async {
    _setError(null);
    try {
      await _repository.addMember(member);
      _members.insert(0, member);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add member: ${e.toString()}');
      return false;
    }
  }

  Future<bool> updateMember(CommitteeMemberModel member) async {
    _setError(null);
    try {
      await _repository.updateMember(member);
      final index = _members.indexWhere((m) => m.id == member.id);
      if (index != -1) {
        _members[index] = member;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Failed to update member: ${e.toString()}');
      return false;
    }
  }

  Future<bool> deleteMember(String id) async {
    _setError(null);
    try {
      await _repository.deleteMember(id);
      _members.removeWhere((m) => m.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete member: ${e.toString()}');
      return false;
    }
  }
}
