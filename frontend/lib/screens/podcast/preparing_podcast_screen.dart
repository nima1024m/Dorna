import 'package:dorna/controllers/podcast/podcast_controller.dart';
import 'package:dorna/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

import 'podcast_dashboard_screen.dart';

class PreparingPodcastScreen extends StatefulWidget {
  static const routeName = '/podcast/preparing_podcast';

  const PreparingPodcastScreen({super.key});

  @override
  State<PreparingPodcastScreen> createState() => _PreparingPodcastScreenState();
}

class _PreparingPodcastScreenState extends State<PreparingPodcastScreen> {
  final PodcastController controller = Get.find();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.ensurePodcastsForToday();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D11),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 20.sp),
                children: [
                  _buildHeaderText(),
                  _buildVideoPlaceholder(),
                  _buildReadyStatusCard(),
                  _buildFeatureGrid(),
                  SizedBox(height: 20.sp),
                ],
              ),
            ),
            _buildStartButton(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.white10,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            onPressed: () => Get.back(),
          ),
        ),
      ),
      title: Row(
        children: List.generate(
            4,
            (index) => Container(
                  width: 30.sp,
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: index < 3
                        ? Colors.blueAccent
                        : Colors.blueAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                )),
      ),
      actions: [
        _buildActionIcon(Icons.edit_outlined, Colors.green),
        _buildActionIcon(Icons.terminal_outlined, Colors.white30),
        _buildActionIcon(Icons.wb_sunny_outlined, Colors.white30),
        SizedBox(width: 10.sp),
      ],
    );
  }

  Widget _buildActionIcon(IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  Widget _buildHeaderText() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.sp),
      child: Column(
        children: [
          Obx(() => Text(
                controller.isGenerating.value
                    ? "Generating your\ndaily podcast..."
                    : controller.isLoading.value
                        ? "Checking for updates..."
                        : "Your podcast is\nready!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              )),
          SizedBox(height: 10.sp),
          Text(
            "Let's see how Dorna works while you wait.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 11.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlaceholder() {
    return Container(
      height: 22.h,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFFA855F7), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.play_arrow_rounded,
              color: Colors.white, size: 40),
        ),
      ),
    );
  }

  Widget _buildReadyStatusCard() {
    return Obx(() {
      var isLoading =
          controller.isLoading.value || controller.isGenerating.value;
      return Container(
        margin: EdgeInsets.symmetric(vertical: 20.sp),
        padding: EdgeInsets.all(20.sp),
        decoration: BoxDecoration(
          color: const Color(0xFF15171C),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatusCheck(true),
                _buildStatusCheck(true),
                _buildStatusCheck(true),
                _buildStatusCheck(!isLoading),
              ],
            ),
            SizedBox(height: 15.sp),
            Text(
              isLoading ? "Preparing content..." : "Your podcast is ready!",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp),
            ),
            Text(
              "Personalized just for you",
              style: TextStyle(color: Colors.white54, fontSize: 10.sp),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatusCheck(bool completed) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: completed
            ? Colors.green.withOpacity(0.2)
            : Colors.blueAccent.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
            color: completed ? Colors.green : Colors.blueAccent, width: 1),
      ),
      child: completed
          ? const Icon(
              Icons.check,
              color: Colors.green,
              size: 14,
            )
          : SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.blueAccent,
              ),
            ),
    );
  }

  Widget _buildFeatureGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12.sp,
      mainAxisSpacing: 12.sp,
      childAspectRatio: 1.2,
      children: [
        _buildFeatureCard(
            "Daily personalized podcasts",
            "Content tailored to your interests",
            Icons.headphones,
            Colors.blue),
        _buildFeatureCard(
            "Save unknown words",
            "Build your vocabulary as you listen",
            Icons.pause_circle_outline,
            Colors.purple),
        _buildFeatureCard("Interactive practice",
            "Flashcards & sentence exercises", Icons.layers, Colors.orange),
        _buildFeatureCard("Adaptive difficulty", "Content grows with you",
            Icons.bar_chart, Colors.green),
      ],
    );
  }

  Widget _buildFeatureCard(
      String title, String desc, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        color: const Color(0xFF15171C),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const Spacer(),
          Text(title,
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 9.sp)),
          SizedBox(height: 2.sp),
          Text(desc,
              style: TextStyle(color: Colors.white38, fontSize: 7.5.sp),
              maxLines: 2),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return Padding(
      padding: EdgeInsets.all(20.sp),
      child: SizedBox(
        width: double.infinity,
        height: 45.sp,
        child: Obx(() {
          final isReady =
              !controller.isLoading.value && !controller.isGenerating.value;
          return ElevatedButton(
            onPressed: isReady
                ? () => Get.offNamedUntil(PodcastaDashboardScreen.routeName,
                    (route) => route.settings.name == HomeScreen.routeName)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isReady ? Colors.blueAccent : Colors.grey,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Start My First Podcast",
                  style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                SizedBox(width: 8.sp),
                if (isReady)
                  const Icon(Icons.arrow_forward,
                      color: Colors.white, size: 18),
              ],
            ),
          );
        }),
      ),
    );
  }
}
