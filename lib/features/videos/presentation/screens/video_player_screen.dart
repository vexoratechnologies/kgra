import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/compact_app_bar.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/video_model.dart';
import '../providers/video_provider.dart';

class VideoPlayerScreen extends StatefulWidget {
  final VideoModel video;

  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInit = false;
  String? _errorMessage;

  // Watch Statistics State
  int _lastSavedSeconds = -1;
  bool _isCompleted = false;
  Timer? _throttleTimer;
  DateTime? _lastWriteTime;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final url = widget.video.videoUrl.trim();
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoPlayerController!.initialize();

      // Get last watch progress
      final user = context.read<AuthProvider>().currentUser;
      int startAtSeconds = 0;
      if (user != null) {
        final progress = context.read<VideoProvider>().progressMap[widget.video.id];
        if (progress != null) {
          startAtSeconds = progress.watchedSeconds;
          _isCompleted = progress.isCompleted;
          if (startAtSeconds >= widget.video.duration - 5) {
            // Reset to start if finished previously
            startAtSeconds = 0;
          }
        }
      }

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        startAt: Duration(seconds: startAtSeconds),
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        errorBuilder: (context, errorMessage) {
          return Center(child: Text(errorMessage, style: const TextStyle(color: Colors.white)));
        },
      );

      // Listen for playback events
      _videoPlayerController!.addListener(_videoListener);

      // Start periodic 30-seconds watch stat timer
      _startThrottleTimer();

      setState(() {
        _isInit = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not play video: ${e.toString()}';
      });
    }
  }

  void _videoListener() {
    if (_videoPlayerController == null) return;
    final value = _videoPlayerController!.value;
    final positionSec = value.position.inSeconds;

    // 1. Completion trigger
    if (value.isCompleted || (positionSec >= widget.video.duration - 1 && !_isCompleted)) {
      _isCompleted = true;
      _saveProgressImmediately(positionSec, isFinished: true);
    }

    // 2. Pause trigger
    if (!value.isPlaying && _lastSavedSeconds != positionSec) {
      _saveProgressImmediately(positionSec);
    }
  }

  void _startThrottleTimer() {
    _throttleTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_videoPlayerController != null && _videoPlayerController!.value.isPlaying) {
        final currentPos = _videoPlayerController!.value.position.inSeconds;
        _saveProgressThrottled(currentPos);
      }
    });
  }

  void _saveProgressThrottled(int positionSec) {
    final now = DateTime.now();
    if (_lastWriteTime != null && now.difference(_lastWriteTime!).inSeconds < 30) {
      return; // Skip if written within 30 seconds
    }
    _saveProgressImmediately(positionSec);
  }

  Future<void> _saveProgressImmediately(int positionSec, {bool isFinished = false}) async {
    if (positionSec == _lastSavedSeconds && isFinished == _isCompleted) return;

    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    _lastSavedSeconds = positionSec;
    _lastWriteTime = DateTime.now();

    // Call provider to save watch status
    await context.read<VideoProvider>().saveProgress(
      userId: user.uid,
      videoId: widget.video.id,
      watchedSeconds: positionSec,
      isCompleted: isFinished || _isCompleted,
    );
  }

  @override
  void dispose() {
    _throttleTimer?.cancel();
    if (_videoPlayerController != null) {
      _videoPlayerController!.removeListener(_videoListener);
      // Save current progress on Screen Exit/Dispose
      final currentPos = _videoPlayerController!.value.position.inSeconds;
      _saveProgressImmediately(currentPos);
      _videoPlayerController!.dispose();
    }
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandBackground,
      appBar: CompactAppBar(
        title: widget.video.title,
        subtitle: 'Learn from experts',
        rightIcon: Icons.play_circle_outline,
      ),
      body: SafeArea(
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _errorMessage != null
                  ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                  : !_isInit
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : Chewie(controller: _chewieController!),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.video.title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.brandSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Duration: ${(widget.video.duration ~/ 60)}m ${(widget.video.duration % 60)}s',
                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.video.description,
                      style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
