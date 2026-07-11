import 'package:flutter/material.dart';
import '../../data/models/video_model.dart';
import '../../data/models/video_progress_model.dart';
import '../../data/repositories/video_repository.dart';

class VideoProvider extends ChangeNotifier {
  final VideoRepository _repository;

  VideoProvider({required VideoRepository repository}) : _repository = repository;

  List<VideoModel> _videos = [];
  Map<String, VideoProgressModel> _progressMap = {}; // videoId -> progress
  bool _isLoading = false;
  String? _error;

  List<VideoModel> get videosList => _videos;
  Map<String, VideoProgressModel> get progressMap => _progressMap;
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

  Future<void> fetchVideos(String userId) async {
    _setLoading(true);
    _setError(null);
    try {
      _videos = await _repository.getVideos();
      final progressList = await _repository.getUserVideoProgress(userId);
      _progressMap = {for (var p in progressList) p.videoId: p};
    } catch (e) {
      _setError('Failed to fetch videos: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addVideo(VideoModel video) async {
    _setError(null);
    try {
      await _repository.saveVideo(video);
      _videos.removeWhere((v) => v.id == video.id);
      _videos.insert(0, video);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add video: ${e.toString()}');
      return false;
    }
  }

  Future<bool> updateVideo(VideoModel video) async {
    _setError(null);
    try {
      await _repository.saveVideo(video);
      final idx = _videos.indexWhere((v) => v.id == video.id);
      if (idx != -1) {
        _videos[idx] = video;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update video: ${e.toString()}');
      return false;
    }
  }

  Future<bool> deleteVideo(String id) async {
    _setError(null);
    try {
      await _repository.deleteVideo(id);
      _videos.removeWhere((v) => v.id == id);
      _progressMap.remove(id);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete video: ${e.toString()}');
      return false;
    }
  }

  /// Saves the progress of a video to the local map and Firestore
  Future<void> saveProgress({
    required String userId,
    required String videoId,
    required int watchedSeconds,
    required bool isCompleted,
  }) async {
    final progress = VideoProgressModel(
      videoId: videoId,
      userId: userId,
      watchedSeconds: watchedSeconds,
      isCompleted: isCompleted,
      lastUpdated: DateTime.now().toIso8601String(),
    );
    _progressMap[videoId] = progress;
    notifyListeners();
    // Save to firestore (or mock storage)
    await _repository.saveVideoProgress(progress);
  }
}
