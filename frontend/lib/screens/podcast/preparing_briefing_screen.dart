import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

import 'podcast_dashboard_screen.dart';

class PreparingBriefingScreen extends StatefulWidget {
  static const routeName = '/podcast/preparing_briefing';

  const PreparingBriefingScreen({super.key});

  @override
  State<PreparingBriefingScreen> createState() =>
      _PreparingBriefingScreenState();
}

class _PreparingBriefingScreenState extends State<PreparingBriefingScreen> {
  int currentStep = 0;
  final List<String> steps = [
    "Curating your daily news...",
    "Analyzing your schedule...",
    "Preparing your language level...",
    "Generating Alex & Sarah's script...",
    "Almost ready..."
  ];

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  void _startLoading() async {
    for (int i = 0; i < steps.length; i++) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          currentStep = i;
        });
      }
    }
    // Navigate to dashboard after completion
    Get.offAllNamed(PodcastaDashboardScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D11),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 150.sp,
                  height: 150.sp,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                  ),
                ),
                Icon(Icons.auto_awesome, color: Colors.blueAccent, size: 50.sp),
              ],
            ),
            SizedBox(height: 40.sp),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                steps[currentStep],
                key: ValueKey<int>(currentStep),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: 10.sp),
            Text(
              "Your personalized briefing is being built by AI.",
              style: TextStyle(color: Colors.white30, fontSize: 10.sp),
            ),
          ],
        ),
      ),
    );
  }
}
