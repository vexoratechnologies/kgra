import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../data/models/ad_model.dart';
import '../../data/repositories/ad_repository.dart';

class AdProvider extends ChangeNotifier {
  final AdRepository _repository;

  AdProvider({required AdRepository repository}) : _repository = repository;

  List<AdModel> _ads = [];
  bool _isLoading = false;
  String? _error;

  List<AdModel> get adsList => _ads;
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

  Future<void> fetchAds({bool force = false}) async {
    if (!force && _ads.isNotEmpty) {
      return;
    }
    _setLoading(true);
    _setError(null);
    try {
      _ads = await _repository.getAds();
      print(_ads);
      print("_ads");
    } catch (e) {
      _setError('Failed to fetch ads: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addAd(AdModel ad, Uint8List fileBytes) async {
    _setError(null);
    try {
      await _repository.addAd(model: ad, fileBytes: fileBytes);
      await fetchAds(force: true);
      return true;
    } catch (e) {
      _setError('Failed to add ad: ${e.toString()}');
      return false;
    }
  }

  Future<bool> updateAd(AdModel ad, Uint8List? fileBytes) async {
    _setError(null);
    try {
      await _repository.updateAd(model: ad, fileBytes: fileBytes);
      await fetchAds(force: true);
      return true;
    } catch (e) {
      _setError('Failed to update ad: ${e.toString()}');
      return false;
    }
  }

  Future<bool> deleteAd(AdModel ad) async {
    _setError(null);
    try {
      await _repository.deleteAd(ad);
      _ads.removeWhere((item) => item.id == ad.id);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete ad: ${e.toString()}');
      return false;
    }
  }
}
