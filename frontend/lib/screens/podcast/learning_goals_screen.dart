import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

import '../../controllers/podcast/podcast_onboarding_controller.dart';
import 'language_level_screen.dart';

class LearningGoalsScreen extends StatelessWidget {
  static const routeName = '/podcast/learning_goals';

  // Safe way to get controller
  PodcastOnboardingController get controller {
    try {
      return Get.find<PodcastOnboardingController>();
    } catch (e) {
      return Get.put(PodcastOnboardingController());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D11),
      appBar: _buildAppBar(),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20.sp, 0, 20.sp, 100.sp),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildHeaderText(),
          ...controller.goals.map((goal) => _buildGoalCard(goal)).toList(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: const Color(0xFF0B0D11),
          padding: EdgeInsets.symmetric(horizontal: 20.sp, vertical: 10.sp),
          child: SizedBox(
            width: double.infinity,
            height: 45.sp,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to Language Level screen
                Get.toNamed(LanguageLevelScreen.routeName);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              child: Text(
                "Continue",
                style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ),
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
      actions: [
        _buildActionIcon(Icons.edit_outlined, Colors.green),
        _buildActionIcon(Icons.crop_original_outlined, Colors.white30),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "What do you want to use English for?",
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Select all that apply. We'll personalize your learning.",
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal) {
    return Obx(() {
      final isSelected = controller.selectedGoals.contains(goal["id"]);
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () => controller.toggleGoal(goal["id"]),
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blueAccent.withOpacity(0.05)
                  : Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.blueAccent : Colors.white10,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blueAccent
                        : Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                                color: Colors.blueAccent.withOpacity(0.4),
                                blurRadius: 15,
                                spreadRadius: 2)
                          ]
                        : null,
                  ),
                  child: Icon(goal["icon"], color: Colors.white, size: 20),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal["title"],
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(goal["desc"],
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: isSelected ? Colors.blueAccent : Colors.white24,
                        width: 2),
                    color: isSelected ? Colors.blueAccent : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
