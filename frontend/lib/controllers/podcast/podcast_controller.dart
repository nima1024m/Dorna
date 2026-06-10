import 'dart:async';

import 'package:dorna/screens/podcast/podcast_player_screen.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

import '../../config/api_client.dart';
import '../../models/podcast_model.dart';
import '../auth/auth_controller.dart';

class PodcastController extends GetxController {
  final ApiClient _apiClient = ApiClient();

  AudioPlayer? player;

  var podcastFeed = <String, PodcastCardData>{}.obs;
  var isLoading = false.obs;
  var isGenerating = false.obs;
  var activePodcastId = "".obs;
  var voiceSpeed = 1.0.obs;
  var isPlaying = false.obs;
  StreamSubscription? _playerStream;

  void updateVoiceSpeed(double speed) {
    voiceSpeed.value = speed;
    player?.setSpeed(speed);
    print("Selected voice speed: $speed");
  }

  Future<void> initAudioPlayer() async {
    player = AudioPlayer();
    try {
      // Listen to player state changes
      _playerStream = player!.playerStateStream.listen((state) {
        isPlaying.value = state.playing;

        // Auto-play next segment when current finishes
        if (state.processingState == ProcessingState.completed) {
          _playNextSegment();
        }
      });

      await player!.setSpeed(voiceSpeed.value);
    } catch (e) {
      print("Error initializing audio player: $e");
    }
  }

  void togglePlayPause() {
    if (player == null) return;
    if (isPlaying.value) {
      player!.pause();
    } else {
      player!.play();
    }
  }

  void disposeAudioPlayer() {
    player?.dispose();
    _playerStream?.cancel();
    player = null;
    _statusTimer?.cancel();
  }

  /// Initial entry point: fetches feed, checks for today's podcasts,
  /// and generates if missing.
  Future<void> ensurePodcastsForToday() async {
    isLoading.value = true;
    try {
      // 1. Fetch current feed
      await fetchPodcastFeed();

      // 2. Check if we have any podcast from today
      bool hasTodayPodcast = _checkForTodayPodcast();

      if (!hasTodayPodcast) {
        // 3. If not, generate new feed
        isGenerating.value = true;
        await generatePodcastFeed();

        // 4. Then fetch again recursively or just once more
        await fetchPodcastFeed();
        isGenerating.value = false;
      }
    } catch (e) {
      print("Error in ensurePodcastsForToday: $e");
    } finally {
      isLoading.value = false;
      isGenerating.value = false;
    }
  }

  Future<void> fetchPodcastFeed() async {
    try {
      final response = await _apiClient.request(
        url: 'v1/podcast/feed',
        method: ApiMethod.get,
      );

      if (response != null && response.statusCode == 200) {
        final data = response.data;
        if (data != null && data['items'] != null) {
          final List<dynamic> items = data['items'];
          podcastFeed
              .clear(); // Clear existing or append depending on requirement. Clearing for now to be safe.
          for (var item in items) {
            final podcast = PodcastCardData.fromJson(item);
            podcastFeed[podcast.id] = podcast;
          }
        }
      }
    } catch (e) {
      print("Error fetching podcast feed: $e");
    }
  }

  Future<void> generatePodcastFeed() async {
    try {
      final response = await _apiClient.request(
        url: 'v1/podcast/feed/generate',
        method: ApiMethod.post,
        data: {"count": 3},
      );

      if (response != null && response.statusCode == 200) {
        print("Generation triggered successfully");
        // We might need to wait a bit or poll, but for now assuming synchronous or fast enough
        // that the next fetch will get it, or the user will refresh.
        // If it's a long running job, we might need a simpler delay here.
        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      print("Error generating podcast feed: $e");
    }
  }

  bool _checkForTodayPodcast() {
    final now = DateTime.now();
    for (var podcast in podcastFeed.values) {
      if (podcast.createdAt != null) {
        final createdAt = podcast.createdAt!.toLocal();
        if (createdAt.year == now.year &&
            createdAt.month == now.month &&
            createdAt.day == now.day) {
          return true;
        }
      }
    }
    return false;
  }

  // --- New Playback Logic ---

  Timer? _statusTimer;
  var currentSegmentIndex = 0.obs;

  Future<void> playPodcast(String id) async {
    activePodcastId.value = id;
    final podcast = podcastFeed[id];
    if (podcast == null) return;
    Get.toNamed(PodcastPlayerScreen.routeName);
    await initAudioPlayer();

    // Reset state
    currentSegmentIndex.value = 0;
    _isPlayingRealAudio = false;

    // Play default sound to start with (loading ambience)
    try {
      await player?.setAsset('assets/sound/sound_theme.mp3');
      player?.play();
      player?.setLoopMode(
          LoopMode.one); // Loop ambient sound until real audio is ready
    } catch (e) {
      print("Error playing ambient sound: $e");
    }

    String? jobId = podcast.jobId;

    if (podcast.status == PodcastStatus.suggested) {
      final newJobId = await _triggerPlayApi(id);
      if (newJobId != null) {
        jobId = newJobId;
        podcast.jobId = newJobId;
      }
    }

    if (jobId != null) {
      // Start polling status with JOB ID
      _startPolling(id, jobId);
    } else {
      print("Error: No Job ID available for podcast $id");
    }
  }

  Future<String?> _triggerPlayApi(String id) async {
    try {
      final response = await _apiClient.request(
        method: ApiMethod.post,
        url: 'v1/podcast/feed/$id/play',
        data: {}, // -d ''
      );

      if (response != null && response.statusCode == 200) {
        return response.data['podcast_job_id'];
      }
    } catch (e) {
      print("Error triggering play: $e");
    }
    return null;
  }

  void _startPolling(String podcastId, String jobId) {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _checkStatus(podcastId, jobId);
    });
    // Check immediately as well
    _checkStatus(podcastId, jobId);
  }

  Future<void> _checkStatus(String podcastId, String jobId) async {
    try {
      final response = await _apiClient.request(
          method: ApiMethod.get, url: 'v1/podcast/$jobId/status');

      if (response != null && response.statusCode == 200) {
        final data = response.data;
        final podcast = podcastFeed[podcastId];
        if (podcast != null) {
          podcast.updateFromStatus(data);
          podcastFeed.refresh(); // Trigger Obx updates

          // Trigger playback logic if we have new segments
          _tryPlayNextSegment(podcast);

          if (podcast.status == PodcastStatus.readyToPlay ||
              podcast.status == PodcastStatus.error) {
            if (podcast.completedSegments >= podcast.totalSegments &&
                podcast.totalSegments > 0) {
              _statusTimer?.cancel();
            }
          }
        }
      }
    } catch (e) {
      print("Error polling status: $e");
    }
  }

  bool _isPlayingRealAudio = false;

  Future<void> _tryPlayNextSegment(PodcastCardData podcast) async {
    if (podcast.segments.isEmpty) return;

    // If we are still playing ambient theme, wait for at least 2 ready segments
    if (!_isPlayingRealAudio) {
      // Count how many segments are ready
      final readyCount =
          podcast.segments.where((s) => s.isReady && s.audioUrl != null).length;

      if (readyCount >= 2) {
        final firstSeg = podcast.segments.first;
        if (firstSeg.isReady && firstSeg.audioUrl != null) {
          _isPlayingRealAudio = true;
          player?.setLoopMode(LoopMode.off); // Stop looping ambient
          await _playSegment(firstSeg);
        }
      }
      return;
    }

    // If we are already playing, logic is handled by _playerStream listener calling _playNextSegment
    // But if we were idle/waiting for a segment to become ready, we might need to kickstart it here?
    // The _playerStream only fires when playback completes. If we Finished segment 1 but segment 2 wasn't ready, we stopped.
    // So we need to check if we are stopped/completed and the NEXT segment is now ready.

    if (player?.processingState == ProcessingState.completed ||
        player?.processingState == ProcessingState.idle) {
      // Try play next
      _playNextSegment();
    }
  }

  Future<void> _playNextSegment() async {
    final podcast = podcastFeed[activePodcastId.value];
    if (podcast == null) return;

    int nextIndex = currentSegmentIndex.value + 1;

    // Note: currentSegmentIndex starts at 0. If we just finished 0, we want 1.
    // However, if we just started (index 0) and are playing it, we don't want to skip it.
    // So we need to be careful.
    // Let's assume currentSegmentIndex points to the one currently playing or just finished.

    // Wait, if this is called from 'completed' state, we definitely want the next one.
    // If called from polling (because we were stuck), we want the next one (or the current one if we never started?)

    // Simplified logic:
    // If we are playing, do nothing.
    if (player?.playing == true &&
        player?.processingState != ProcessingState.completed) return;

    // If we just finished segment N, try N+1
    if (nextIndex < podcast.segments.length) {
      final nextSeg = podcast.segments[nextIndex];
      if (nextSeg.isReady && nextSeg.audioUrl != null) {
        currentSegmentIndex.value = nextIndex;
        await _playSegment(nextSeg);
      } else {
        // Next not ready yet, wait for next poll
        // Maybe show loading?
      }
    } else {
      // End of playlist
    }
  }

  Future<void> _playSegment(PodcastSegment segment,
      {bool isRetry = false}) async {
    try {
      final url = ApiClient.baseUrl +
          (segment.audioUrl!.startsWith('/')
              ? segment.audioUrl!.substring(1)
              : segment.audioUrl!);

      // Get access token and pass it as a header
      final token = ApiInterceptors.accessToken;
      await player?.setUrl(
        url,
        headers: token.isNotEmpty ? {'Authorization': 'Bearer $token'} : null,
      );
      player?.play();
    } catch (e) {
      // Check for 401 error and try to refresh token
      final errorString = e.toString().toLowerCase();
      if (!isRetry &&
          (errorString.contains('401') ||
              errorString.contains('unauthorized'))) {
        print("Got 401 on audio segment, attempting token refresh...");
        final authController = Get.find<AuthController>();
        final refreshSuccess = await authController.refreshToken();
        if (refreshSuccess) {
          // Retry playing the segment with new token
          await _playSegment(segment, isRetry: true);
          return;
        }
      }
      print("Error playing segment ${segment.index}: $e");
    }
  }
}
