import '../../../../core/services/firestore_service.dart';
import '../models/video_model.dart';
import '../models/video_progress_model.dart';

class VideoRepository {
  final FirestoreService _firestoreService;

  VideoRepository({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  Future<void> saveVideo(VideoModel video) async {
    await _firestoreService.saveVideo(video);
  }

  Future<List<VideoModel>> getVideos() async {
    return await _firestoreService.getVideos();
  }

  Future<void> deleteVideo(String id) async {
    await _firestoreService.deleteVideo(id);
  }

  Future<void> saveVideoProgress(VideoProgressModel progress) async {
    await _firestoreService.saveVideoProgress(progress);
  }

  Future<VideoProgressModel?> getVideoProgress(String userId, String videoId) async {
    return await _firestoreService.getVideoProgress(userId, videoId);
  }

  Future<List<VideoProgressModel>> getUserVideoProgress(String userId) async {
    return await _firestoreService.getUserVideoProgress(userId);
  }
}
