import 'package:flutter/material.dart';
import '../../data/models/update_model.dart';
import '../../data/repositories/updates_repository.dart';

class UpdatesProvider extends ChangeNotifier {
  final UpdatesRepository _repository;

  UpdatesProvider({required UpdatesRepository repository}) : _repository = repository;

  List<UpdateModel> _updates = [];
  bool _isLoading = false;
  String? _error;

  List<UpdateModel> get updatesList => _updates;
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

  Future<void> fetchUpdates() async {
    _setLoading(true);
    _setError(null);
    try {
      _updates = await _repository.getUpdates();
    } catch (e) {
      _setError('Failed to fetch updates: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addUpdate(UpdateModel update) async {
    _setError(null);
    try {
      await _repository.saveUpdate(update);
      await fetchUpdates();
      return true;
    } catch (e) {
      _setError('Failed to add update: ${e.toString()}');
      return false;
    }
  }

  Future<bool> updateUpdate(UpdateModel update) async {
    _setError(null);
    try {
      await _repository.saveUpdate(update);
      await fetchUpdates();
      return true;
    } catch (e) {
      _setError('Failed to update: ${e.toString()}');
      return false;
    }
  }

  Future<bool> deleteUpdate(String id) async {
    _setError(null);
    try {
      await _repository.deleteUpdate(id);
      _updates.removeWhere((item) => item.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete update: ${e.toString()}');
      return false;
    }
  }
}
