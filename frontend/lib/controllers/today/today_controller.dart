import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../auth/auth_controller.dart';

/// One item in the "Today's Plan" timeline.
class PlanEvent {
  final String id;
  final String time;
  final String title;
  final String kind; // 'networking' | 'coffee' → routes to prep later
  final bool dotAccent; // false → primary dot, true → cyan accent dot
  const PlanEvent({
    required this.id,
    required this.time,
    required this.title,
    required this.kind,
    this.dotAccent = false,
  });
}

/// State for the redesigned **Today** hub (greeting, daily-brief hero, plan,
/// around-you, mini-player).
///
/// Identity (name) and the date/greeting are real. The daily brief, plan
/// events, weather and around-you are **placeholder/local** — there is no
/// backend for a curated daily brief, calendar plan, or places feed yet; those
/// land in the F-phases (F2 brief, F3 around-you, F5 calendar). Wire them then.
class TodayController extends GetxController {
  // ── Identity / date (real) ──
  String get firstName {
    final full = Get.find<AuthController>().getUserDetails.fullName?.trim();
    if (full == null || full.isEmpty) return 'there';
    return full.split(RegExp(r'\s+')).first;
  }

  String get greeting {
    final h = DateTime.now().hour;
    final part = h < 12
        ? 'Good morning'
        : h < 18
            ? 'Good afternoon'
            : 'Good evening';
    return '$part, $firstName';
  }

  String get dateLabel {
    final now = DateTime.now();
    const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const mo = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${wd[now.weekday - 1]}, ${mo[now.month - 1]} ${now.day}';
  }

  // ── Brief hero (placeholder copy) ──
  static const String briefTitle = 'Your 5-min brief';
  static const String briefDuration = '5 min';
  static const String briefSubtitle =
      "Today's events, useful phrases & a bit of news";

  // ── Weather (placeholder) ──
  static const String weatherTemp = '12°';
  static const String weatherLabel = 'Sunny';
  static const IconData weatherIcon = Icons.wb_sunny_rounded;

  // ── Plan ──
  // Empty by default → the Today hub shows the "welcome / no events yet" state
  // for a new or calendar-disconnected user (matches the design's today_welcome).
  // Real events come from the calendar (F5); see TodayScreen.
  final RxList<PlanEvent> events = <PlanEvent>[].obs;

  // ── Around you (placeholder; null → location prompt) ──
  final RxnString aroundPlace = RxnString('Central Library');
  static const String aroundTip = 'Tips for starting a chat here';
}
