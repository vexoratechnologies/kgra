import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../data/models/gallery_image_model.dart';
import '../../data/repositories/gallery_repository.dart';

class GalleryProvider extends ChangeNotifier {
  final GalleryRepository _repository;

  GalleryProvider({required GalleryRepository repository}) : _repository = repository;

  List<GalleryImageModel> _images = [];
  bool _isLoading = false;
  String? _error;

  List<GalleryImageModel> get imagesList => _images;
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

  Future<void> fetchImages() async {
    _setLoading(true);
    _setError(null);
    try {
      _images = await _repository.getGalleryImages();
    } catch (e) {
      _setError('Failed to fetch gallery images: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addImage(GalleryImageModel image, Uint8List fileBytes) async {
    _setError(null);
    try {
      await _repository.addGalleryImage(model: image, fileBytes: fileBytes);
      await fetchImages();
      return true;
    } catch (e) {
      _setError('Failed to add image: ${e.toString()}');
      return false;
    }
  }

  Future<bool> updateImage(GalleryImageModel image, Uint8List? fileBytes) async {
    _setError(null);
    try {
      await _repository.updateGalleryImage(model: image, fileBytes: fileBytes);
      await fetchImages();
      return true;
    } catch (e) {
      _setError('Failed to update image: ${e.toString()}');
      return false;
    }
  }

  Future<bool> deleteImage(GalleryImageModel image) async {
    _setError(null);
    try {
      await _repository.deleteGalleryImage(image);
      _images.removeWhere((item) => item.id == image.id);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete image: ${e.toString()}');
      return false;
    }
  }
}
