enum PodcastStatus {
  idle,
  suggested,
  generatingMeta,
  readyMeta,
  generatingAudio,
  readyToPlay,
  error
}

class PodcastSegment {
  final int index;
  final String speaker;
  final String text;
  final String? audioUrl;
  final bool isReady;
  final Duration startTime;
  final Duration endTime;

  PodcastSegment({
    this.index = 0,
    required this.speaker,
    required this.text,
    this.audioUrl,
    this.isReady = false,
    this.startTime = Duration.zero,
    this.endTime = Duration.zero,
  });

  factory PodcastSegment.fromJson(Map<String, dynamic> json) {
    return PodcastSegment(
      index: json['index'] ?? 0,
      speaker: json['speaker'] ?? 'Alex',
      text: json['text'] ?? '',
      audioUrl: json['url'],
      isReady: json['ready'] ?? false,
    );
  }
}

class PodcastCardData {
  final String id;
  final String topicQuery;
  String title;
  String description;
  String imageUrl;
  String category;
  PodcastStatus status;

  // Playback/Generation fields
  String? jobId;
  double progress;
  String? currentStep;
  int totalSegments;
  int completedSegments;
  String? errorMessage;

  List<PodcastSegment> segments;
  String? audioFilePath;

  DateTime? createdAt;

  PodcastCardData({
    required this.id,
    required this.topicQuery,
    this.title = "Loading...",
    this.description = "Curating your briefing...",
    this.imageUrl = "",
    this.category = "General",
    this.status = PodcastStatus.idle,
    this.segments = const [],
    this.audioFilePath,
    this.createdAt,
    this.jobId,
    this.progress = 0,
    this.currentStep,
    this.totalSegments = 0,
    this.completedSegments = 0,
    this.errorMessage,
  });

  factory PodcastCardData.fromJson(Map<String, dynamic> json) {
    PodcastStatus parseStatus(String? status) {
      if (status == null) return PodcastStatus.idle;
      switch (status.toLowerCase()) {
        case 'suggested':
          return PodcastStatus.suggested;
        case 'generating_meta':
          return PodcastStatus.generatingMeta;
        case 'ready_meta':
          return PodcastStatus.readyMeta;
        case 'generating_audio':
          return PodcastStatus.generatingAudio;
        case 'ready': // API might return just 'ready' or 'ready_to_play'
        case 'ready_to_play':
          return PodcastStatus.readyToPlay;
        case 'error':
          return PodcastStatus.error;
        default:
          return PodcastStatus.idle;
      }
    }

    return PodcastCardData(
      id: json['id'],
      topicQuery: json['query'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
      category: json['category'] ?? 'General',
      status: parseStatus(json['status']),
      jobId: json['job_id'] ?? json['podcast_job_id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  void updateWithMeta({
    required String title,
    required String description,
    required String imageUrl,
    required String category,
  }) {
    this.title = title;
    this.description = description;
    this.imageUrl = imageUrl;
    this.category = category;
    this.status = PodcastStatus.readyMeta;
  }

  void updateFromStatus(Map<String, dynamic> json) {
    jobId = json['job_id'];
    // Map string status to enum
    if (json['status'] != null) {
      switch (json['status'].toString().toLowerCase()) {
        case 'suggested':
          status = PodcastStatus.suggested;
          break;
        case 'generating': // Assuming API might use 'generating' for general progress
        case 'generating_audio':
          status = PodcastStatus.generatingAudio;
          break;
        case 'done':
        case 'ready':
          status = PodcastStatus.readyToPlay;
          break;
        case 'error':
          status = PodcastStatus.error;
          break;
      }
    }
    progress = (json['progress'] as num?)?.toDouble() ?? 0;
    currentStep = json['current_step'];
    totalSegments = json['total_segments'] ?? 0;
    completedSegments = json['completed_segments'] ?? 0;
    errorMessage = json['error_message'];

    // Merge script and segments
    // The API returns 'script' (list of {speaker, text}) and 'segments' (list of {index, url, ready})
    // We need to merge these into our List<PodcastSegment>

    if (json['script'] != null) {
      List<dynamic> scripts = json['script'];
      List<dynamic> segmentData = json['segments'] ?? [];

      List<PodcastSegment> newSegments = [];

      for (int i = 0; i < scripts.length; i++) {
        var scriptItem = scripts[i];
        var segItem =
            segmentData.firstWhere((s) => s['index'] == i, orElse: () => null);

        newSegments.add(PodcastSegment(
          index: i,
          speaker: scriptItem['speaker'] ?? 'Unknown',
          text: scriptItem['text'] ?? '',
          audioUrl: segItem != null ? segItem['url'] : null,
          isReady: segItem != null ? (segItem['ready'] ?? false) : false,
        ));
      }
      segments = newSegments;
    }
  }
}
