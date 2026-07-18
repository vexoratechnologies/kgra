import 'package:flutter/material.dart';
import '../../data/models/event_model.dart';
import '../../data/repositories/event_repository.dart';

class EventProvider extends ChangeNotifier {
  final EventRepository _repository;

  EventProvider({required EventRepository repository}) : _repository = repository;

  List<EventModel> _events = [];
  bool _isLoading = false;
  String? _error;

  List<EventModel> get eventsList => _events;
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

  Future<void> fetchEvents() async {
    _setLoading(true);
    _setError(null);
    try {
      _events = await _repository.getEvents();
    } catch (e) {
      _setError('Failed to fetch events: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addEvent(EventModel event) async {
    _setError(null);
    try {
      await _repository.saveEvent(event);
      _events.removeWhere((e) => e.id == event.id);
      _events.add(event);
      // Sort after addition by date ascending
      _events.sort((a, b) => a.date.compareTo(b.date));
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add event: ${e.toString()}');
      return false;
    }
  }

  Future<bool> updateEvent(EventModel event) async {
    _setError(null);
    try {
      await _repository.saveEvent(event);
      final idx = _events.indexWhere((e) => e.id == event.id);
      if (idx != -1) {
        _events[idx] = event;
      }
      _events.sort((a, b) => a.date.compareTo(b.date));
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update event: ${e.toString()}');
      return false;
    }
  }

  Future<bool> deleteEvent(String id) async {
    _setError(null);
    try {
      await _repository.deleteEvent(id);
      _events.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete event: ${e.toString()}');
      return false;
    }
  }
}
