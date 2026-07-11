import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../data/models/form_circular_model.dart';
import '../../data/repositories/form_circular_repository.dart';

class FormsCircularsProvider extends ChangeNotifier {
  final FormCircularRepository _repository;

  FormsCircularsProvider({required FormCircularRepository repository})
      : _repository = repository;

  List<FormCircularModel> _forms = [];
  bool _isLoading = false;
  String? _error;

  List<FormCircularModel> get forms => _forms;
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

  Future<void> fetchAllForms() async {
    _setLoading(true);
    _setError(null);
    try {
      _forms = await _repository.getAllFormCirculars();
    } catch (e) {
      _setError('Failed to fetch forms: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addForm(FormCircularModel form, Uint8List? pdfBytes) async {
    _setError(null);
    try {
      await _repository.addFormCircular(model: form, pdfBytes: pdfBytes);
      await fetchAllForms(); // Refresh list to include generated storage URL
      return true;
    } catch (e) {
      _setError('Failed to add form: ${e.toString()}');
      return false;
    }
  }

  Future<bool> updateForm(FormCircularModel form, Uint8List? pdfBytes) async {
    _setError(null);
    try {
      await _repository.updateFormCircular(model: form, pdfBytes: pdfBytes);
      await fetchAllForms(); // Refresh list
      return true;
    } catch (e) {
      _setError('Failed to update form: ${e.toString()}');
      return false;
    }
  }

  Future<bool> deleteForm(FormCircularModel form) async {
    _setError(null);
    try {
      await _repository.deleteFormCircular(form);
      _forms.removeWhere((f) => f.id == form.id);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete form: ${e.toString()}');
      return false;
    }
  }

  Future<Uint8List?> downloadPdf(FormCircularModel form) async {
    try {
      return await _repository.downloadFormCircularPdf(form);
    } catch (e) {
      debugPrint('Failed to download PDF: $e');
      return null;
    }
  }
}
