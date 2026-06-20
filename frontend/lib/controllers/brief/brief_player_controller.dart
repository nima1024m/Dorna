import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../config/api_client.dart';

/// One chapter of the daily brief.
class BriefSegment {
  final String id;
  final String label;
  final IconData icon;
  final String transcript;
  final String highlight; // phrase rendered as an inline cyan chip
  final String fa; // Persian gloss
  const BriefSegment({
    required this.id,
    required this.label,
    required this.icon,
    required this.transcript,
    required this.highlight,
    required this.fa,
  });

  factory BriefSegment.fromJson(Map<String, dynamic> j) {
    final id = j['id']?.toString() ?? '';
    return BriefSegment(
      id: id,
      label: j['label']?.toString() ?? id,
      icon: iconFor(id),
      transcript: j['transcript']?.toString() ?? '',
      highlight: j['highlight']?.toString() ?? '',
      fa: j['fa']?.toString() ?? '',
    );
  }

  static IconData iconFor(String id) {
    switch (id) {
      case 'weather':
        return Icons.wb_sunny_outlined;
      case 'happening':
        return Icons.public;
      case 'phrases':
        return Icons.forum_outlined;
      case 'goodtoknow':
        return Icons.tips_and_updates_outlined;
      case 'challenge':
        return Icons.bolt_outlined;
      default:
        return Icons.article_outlined;
    }
  }
}

/// Drives the redesigned Daily Brief player.
///
/// Segments/transcript/date come from the F2 backend (`GET /v1/daily-brief/today`)
/// when available; otherwise the placeholder set below is used. Audio playback
/// itself is still a local timeline simulation (the brief is text/segments;
/// per-segment TTS audio is a later add).
class BriefPlayerController extends GetxController {
  final ApiClient _apiClient = ApiClient();

  static const int totalSeconds = 300; // 5:00

  final RxString dateLabel = 'Monday, Jun 1'.obs;
  final RxList<BriefSegment> segments = RxList<BriefSegment>(_defaultSegments);

  int get _segSeconds {
    final n = segments.length;
    return n == 0 ? totalSeconds : (totalSeconds ~/ n);
  }

  static const List<BriefSegment> _defaultSegments = [
    BriefSegment(
      id: 'weather',
      label: 'Weather',
      icon: Icons.wb_sunny_outlined,
      transcript:
          "It's a crisp, sunny morning in Toronto — about 12 degrees. A light "
          "jacket is all you need. If someone asks about it, you can say "
          "\"Gorgeous day, isn't it?\" to start a friendly chat.",
      highlight: "Gorgeous day, isn't it?",
      fa: 'یک صبح آفتابی و خنک در تورنتو است؛ حدود ۱۲ درجه. یک ژاکت سبک کافی است.',
    ),
    BriefSegment(
      id: 'happening',
      label: "What's happening",
      icon: Icons.public,
      transcript:
          "There's a local tech meetup downtown this evening. People will "
          "likely ask \"So, what do you do?\" — a simple, friendly opener you'll "
          "hear a lot at events here.",
      highlight: 'So, what do you do?',
      fa: 'امشب یک رویداد فناوری در مرکز شهر برگزار می‌شود.',
    ),
    BriefSegment(
      id: 'phrases',
      label: 'Useful phrases',
      icon: Icons.forum_outlined,
      transcript:
          "When you meet someone in the morning, a very common way to check in "
          "is by saying \"How's it going?\" It's casual and perfect for your new "
          "Canadian neighbours.",
      highlight: "How's it going?",
      fa: 'وقتی صبح کسی را می‌بینید، یک راه رایج برای احوال‌پرسی گفتن '
          '«How\'s it going?» است.',
    ),
    BriefSegment(
      id: 'goodtoknow',
      label: 'Good to know',
      icon: Icons.tips_and_updates_outlined,
      transcript:
          "In Canada, people often say \"sorry\" even when it isn't their fault "
          "— it's just polite. Saying \"No worries\" back keeps things warm and "
          "easy-going.",
      highlight: 'No worries',
      fa: 'در کانادا مردم اغلب حتی وقتی مقصر نیستند «sorry» می‌گویند.',
    ),
    BriefSegment(
      id: 'challenge',
      label: 'Challenge',
      icon: Icons.bolt_outlined,
      transcript:
          "Today's challenge: use \"How's it going?\" with one new person. "
          "Small, friendly openers are the fastest way to feel at home.",
      highlight: "How's it going?",
      fa: 'چالش امروز: عبارت «How\'s it going?» را با یک نفر جدید استفاده کنید.',
    ),
  ];

  static const List<double> speeds = [1.0, 1.25, 1.5];

  /// Whether the brief has been started (drives the shell mini-player).
  final RxBool started = false.obs;
  final RxInt position = 134.obs; // 2:14
  final RxBool isPlaying = false.obs;
  final RxInt speedIndex = 0.obs;
  final RxBool showFa = false.obs;
  final RxSet<String> savedPhrases = <String>{}.obs;

  Timer? _ticker;

  int get currentIndex => segments.isEmpty
      ? 0
      : (position.value ~/ _segSeconds).clamp(0, segments.length - 1);
  BriefSegment get currentSegment =>
      segments.isEmpty ? _defaultSegments.first : segments[currentIndex];
  double get speed => speeds[speedIndex.value];
  bool get isSaved => savedPhrases.contains(currentSegment.id);

  @override
  void onInit() {
    super.onInit();
    fetchBrief();
  }

  /// Pull today's generated brief; on success replace the placeholder segments.
  /// On 202 (generating) / 404 / error, keep the placeholder set.
  Future<void> fetchBrief() async {
    try {
      final r = await _apiClient.request(
        url: 'v1/daily-brief/today',
        method: ApiMethod.get,
        skipErrorStatusCodes: const [202, 404],
      );
      if (r != null && r.statusCode == 200 && r.data is Map) {
        final content = (r.data['content'] as Map?) ?? const {};
        final segs = (content['segments'] as List?) ?? const [];
        final parsed = segs
            .whereType<Map>()
            .map((e) => BriefSegment.fromJson(e.cast<String, dynamic>()))
            .where((s) => s.transcript.isNotEmpty)
            .toList();
        if (parsed.isNotEmpty) {
          segments.assignAll(parsed);
          position.value = 0;
        }
        final d = content['date']?.toString();
        if (d != null && d.isNotEmpty) dateLabel.value = d;
      }
    } catch (_) {
      // keep placeholder segments
    }
  }

  @override
  void onClose() {
    _stopTicker();
    super.onClose();
  }

  void _startTicker() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isPlaying.value) return;
      final next = position.value + speed.round();
      if (next >= totalSeconds) {
        position.value = totalSeconds;
        pause();
      } else {
        position.value = next;
      }
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  /// Start the brief (from the Today hero) — marks it started and plays.
  void play() {
    started.value = true;
    isPlaying.value = true;
    _startTicker();
  }

  void pause() {
    isPlaying.value = false;
    _stopTicker();
  }

  void togglePlay() => isPlaying.value ? pause() : play();

  /// Stop and dismiss the brief (mini-player close).
  void stop() {
    _stopTicker();
    isPlaying.value = false;
    started.value = false;
  }

  void seekFraction(double f) =>
      position.value = (f.clamp(0, 1) * totalSeconds).round();

  void nudge(int seconds) =>
      position.value = (position.value + seconds).clamp(0, totalSeconds);

  void cycleSpeed() => speedIndex.value = (speedIndex.value + 1) % speeds.length;

  void selectSegment(int i) => position.value = i * _segSeconds;

  void toggleFa() => showFa.toggle();

  void toggleSave() {
    final id = currentSegment.id;
    savedPhrases.contains(id) ? savedPhrases.remove(id) : savedPhrases.add(id);
  }

  static String fmt(int seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
