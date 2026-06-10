import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

import '../../controllers/podcast/podcast_onboarding_controller.dart';

class LanguageLevelScreen extends StatefulWidget {
  static const routeName = '/podcast/language_level';

  const LanguageLevelScreen({super.key});

  @override
  State<LanguageLevelScreen> createState() => _LanguageLevelScreenState();
}

class _LanguageLevelScreenState extends State<LanguageLevelScreen> {
  final PodcastOnboardingController controller =
      Get.put(PodcastOnboardingController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D11),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeaderText(),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 20.sp),
                itemCount: controller.levels.length,
                itemBuilder: (context, index) {
                  return _buildLevelCard(controller.levels[index]);
                },
              ),
            ),
            _buildContinueButton(),
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
      padding: EdgeInsets.all(20.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "What's your current language level?",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.sp),
          Text(
            "You can change this anytime.",
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard(Map<String, dynamic> level) {
    return Obx(() {
      final isSelected = controller.selectedLanguageLevel.value == level["id"];
      return Padding(
        padding: EdgeInsets.only(bottom: 12.sp),
        child: InkWell(
          onTap: () => controller.setLanguageLevel(level["id"]),
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: EdgeInsets.all(15.sp),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blueAccent.withOpacity(0.1)
                  : Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.blueAccent : Colors.white10,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.1),
                        blurRadius: 15,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blueAccent
                        : Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(level["icon"], color: Colors.white, size: 20),
                ),
                SizedBox(width: 15.sp),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            level["title"],
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle,
                                color: Colors.blueAccent, size: 20)
                          else
                            Icon(Icons.radio_button_off,
                                color: Colors.white.withOpacity(0.2), size: 20),
                        ],
                      ),
                      SizedBox(height: 5.sp),
                      Text(
                        level["desc"],
                        style:
                            TextStyle(color: Colors.white70, fontSize: 10.sp),
                      ),
                      SizedBox(height: 8.sp),
                      Text(
                        level["exam"],
                        style: TextStyle(
                          color: isSelected
                              ? Colors.blueAccent.withOpacity(0.8)
                              : Colors.white30,
                          fontSize: 8.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildContinueButton() {
    return Padding(
      padding: EdgeInsets.all(20.sp),
      child: SizedBox(
        width: double.infinity,
        height: 45.sp,
        child: Obx(() => ElevatedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : () {
                      controller.submitPreferences();
                    },
              style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
              child: controller.isLoading.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ))
                  : Text(
                      "Continue",
                      style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
            )),
      ),
    );
  }
}
