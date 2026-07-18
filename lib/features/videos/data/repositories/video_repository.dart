import 'dart:typed_data';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../notification/data/models/notification_model.dart';
import '../models/video_model.dart';
import '../models/video_progress_model.dart';

class VideoRepository {
  final FirestoreService _firestoreService;
  final StorageService _storageService;

  VideoRepository({
    required FirestoreService firestoreService,
    required StorageService storageService,
  })  : _firestoreService = firestoreService,
        _storageService = storageService;

  Future<VideoModel> saveVideo(
    VideoModel video,
    Uint8List? videoBytes,
    Uint8List? thumbnailBytes, {
    Function(double progress)? onVideoProgress,
    Function(double progress)? onThumbnailProgress,
  }) async {
    String finalUrl = video.videoUrl;
    if (videoBytes != null) {
      finalUrl = await _storageService.uploadVideo(
        folderName: 'educational_videos',
        docId: video.id,
        fileName: '${video.id}.mp4',
        fileBytes: videoBytes,
        onProgress: onVideoProgress,
      );
    }

    String finalThumbUrl = video.thumbnailUrl;
    if (thumbnailBytes != null) {
      finalThumbUrl = await _storageService.uploadImage(
        folderName: 'educational_thumbnails',
        docId: video.id,
        fileName: '${video.id}.jpg',
        fileBytes: thumbnailBytes,
        onProgress: onThumbnailProgress,
      );
    }

    final updatedVideo = video.copyWith(
      videoUrl: finalUrl,
      thumbnailUrl: finalThumbUrl,
    );
    await _firestoreService.saveVideo(updatedVideo);

    // Save system notification
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Educational Video Added',
      body: updatedVideo.title,
      routingPath: AppRoutes.videos,
      createdAt: DateTime.now().toIso8601String(),
    );
    await _firestoreService.saveNotification(notification);

    // Trigger push notification broadcast
    await PushNotificationService.instance.sendBroadcastNotification(
      title: 'New Educational Video Added',
      body: updatedVideo.title,
      routingPath: AppRoutes.videos,
    );

    return updatedVideo;
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
