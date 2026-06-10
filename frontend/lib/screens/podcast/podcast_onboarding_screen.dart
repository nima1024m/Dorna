import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

import '../../controllers/podcast/podcast_onboarding_controller.dart';
import 'learning_goals_screen.dart';

class PodcastOnboardingScreen extends StatefulWidget {
  static const routeName = '/podcast/onboarding';

  const PodcastOnboardingScreen({super.key});

  @override
  State<PodcastOnboardingScreen> createState() =>
      _PodcastOnboardingScreenState();
}

class _PodcastOnboardingScreenState extends State<PodcastOnboardingScreen> {
  final PodcastOnboardingController controller =
      Get.put(PodcastOnboardingController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D11),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 20.sp),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    if (controller.customTopics.isNotEmpty)
                      _buildCustomSection(),
                    ...controller.categories
                        .map((cat) => _buildCategorySection(cat))
                        .toList(),
                    SizedBox(height: 20.sp),
                  ],
                ),
              ),
              _buildAddTopic(context),
              _buildStartButton(),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCustomSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 15.sp),
          child: const Text(
            "✨ CUSTOM TOPICS",
            style: TextStyle(
              color: Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Wrap(
          spacing: 10.sp,
          runSpacing: 10.sp,
          children: controller.customTopics.map((item) {
            return _buildTopicChip(
                item["id"]!, item["label"]!, Icons.auto_awesome);
          }).toList(),
        ),
        SizedBox(height: 10.sp),
        const Divider(color: Colors.white10, height: 40),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(20.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white10,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Get.back(),
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.wb_sunny_outlined,
                      color: Colors.white54, size: 28),
                  Positioned(
                    bottom: -5,
                    child: Obx(() => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "${controller.selectedTopics.length}",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        )),
                  )
                ],
              )
            ],
          ),
          SizedBox(height: 20.sp),
          Text(
            "Your Interests",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.sp),
          Text(
            "Select topics to tailor your daily podcast.",
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(Map<String, dynamic> category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 15.sp),
          child: Text(
            category["title"],
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Wrap(
          spacing: 10.sp,
          runSpacing: 10.sp,
          children: (category["items"] as List).map((item) {
            return _buildTopicChip(item["id"], item["label"], item["icon"]);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTopicChip(String id, String label, IconData icon) {
    return Obx(() {
      final isSelected = controller.isSelected(id);
      return InkWell(
        onTap: () => controller.toggleTopic(id),
        borderRadius: BorderRadius.circular(30),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 14.sp, vertical: 10.sp),
          decoration: BoxDecoration(
            color:
                isSelected ? Colors.blueAccent : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSelected ? Colors.blueAccent : Colors.white10,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white70,
                size: 16.sp,
              ),
              SizedBox(width: 8.sp),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildAddTopic(BuildContext context) {
    return InkWell(
      onTap: () => _showAddTopicSheet(context),
      borderRadius: BorderRadius.circular(20),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20.sp, vertical: 10.sp),
        padding: EdgeInsets.all(12.sp),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.blueAccent),
            ),
            SizedBox(width: 12.sp),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Add New Topic",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp),
                ),
                Text(
                  "Can't find what you're looking for?",
                  style: TextStyle(color: Colors.white54, fontSize: 10.sp),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showAddTopicSheet(BuildContext context) {
    final TextEditingController textController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF15171C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20.sp,
          right: 20.sp,
          top: 20.sp,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "New Topic",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white54),
                )
              ],
            ),
            SizedBox(height: 10.sp),
            TextField(
              controller: textController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "e.g. Tesla Stock News",
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (val) {
                if (val.isNotEmpty) {
                  controller.addCustomTopic(val);
                  Navigator.pop(context);
                }
              },
            ),
            SizedBox(height: 20.sp),
            SizedBox(
              width: double.infinity,
              height: 45.sp,
              child: ElevatedButton(
                onPressed: () {
                  if (textController.text.isNotEmpty) {
                    controller.addCustomTopic(textController.text);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("Add to Briefing",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(height: 20.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.sp, 0, 20.sp, 20.sp),
      child: SizedBox(
        width: double.infinity,
        height: 45.sp,
        child: ElevatedButton(
          onPressed: () {
            // Check flow or just go to LearningGoalsScreen
            // Since controller.nextStep logic handles skip, but here we just want to go to next manually
            Get.toNamed(LearningGoalsScreen.routeName);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
    );
  }
}
