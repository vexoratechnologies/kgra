import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../data/models/meeting_minutes_model.dart';
import '../../data/repositories/meeting_minutes_repository.dart';

class MeetingMinutesProvider extends ChangeNotifier {
  final MeetingMinutesRepository _repository;

  MeetingMinutesProvider({required MeetingMinutesRepository repository})
      : _repository = repository;

  List<MeetingMinutesModel> _minutesList = [];
  bool _isLoading = false;
  String? _error;

  List<MeetingMinutesModel> get minutesList => _minutesList;
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

  Future<void> fetchAllMinutes() async {
    _setLoading(true);
    _setError(null);
    try {
      _minutesList = await _repository.getAllMeetingMinutes();
    } catch (e) {
      _setError('Failed to fetch minutes: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addMinutes(MeetingMinutesModel minutes, Uint8List pdfBytes) async {
    _setError(null);
    try {
      await _repository.addMeetingMinutes(model: minutes, pdfBytes: pdfBytes);
      await fetchAllMinutes(); // Refresh list to include generated storage URL
      return true;
    } catch (e) {
      _setError('Failed to add minutes: ${e.toString()}');
      return false;
    }
  }

  Future<bool> updateMinutes(MeetingMinutesModel minutes, Uint8List? pdfBytes) async {
    _setError(null);
    try {
      await _repository.updateMeetingMinutes(model: minutes, pdfBytes: pdfBytes);
      await fetchAllMinutes(); // Refresh list
      return true;
    } catch (e) {
      _setError('Failed to update minutes: ${e.toString()}');
      return false;
    }
  }

  Future<bool> deleteMinutes(MeetingMinutesModel minutes) async {
    _setError(null);
    try {
      await _repository.deleteMeetingMinutes(minutes);
      _minutesList.removeWhere((m) => m.id == minutes.id);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete minutes: ${e.toString()}');
      return false;
    }
  }

  Future<Uint8List?> downloadPdf(MeetingMinutesModel minutes) async {
    try {
      return await _repository.downloadMeetingMinutesPdf(minutes);
    } catch (e) {
      debugPrint('Failed to download PDF: $e');
      return null;
    }
  }

  Future<bool> updateMinutesStatus(String id, String status) async {
    _setError(null);
    try {
      await _repository.updateMeetingMinutesStatus(id, status);
      await fetchAllMinutes();
      return true;
    } catch (e) {
      _setError('Failed to update minutes status: ${e.toString()}');
      return false;
    }
  }
}
