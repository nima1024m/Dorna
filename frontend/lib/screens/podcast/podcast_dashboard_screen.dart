import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../controllers/auth/auth_controller.dart';
import '../../controllers/podcast/podcast_controller.dart';
import '../../models/podcast_model.dart';
import '../../utils/utils.dart';

class PodcastaDashboardScreen extends StatefulWidget {
  static const routeName = '/podcast_dashboard_screen';

  const PodcastaDashboardScreen({super.key});

  @override
  State<PodcastaDashboardScreen> createState() =>
      _PodcastaDashboardScreenState();
}

class _PodcastaDashboardScreenState extends State<PodcastaDashboardScreen> {
  final PodcastController controller = Get.find();
  final AuthController authController = Get.find();
  String activeTab = 'foryou';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D11),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildGreetingSection(),
                  _buildHeroVideoSection(),
                  _buildTabsSection(),
                  _buildPodcastFeed(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.sp, vertical: 15.sp),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32.sp,
                height: 32.sp,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bolt, color: Colors.white, size: 28),
              ),
              SizedBox(width: 10.sp),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Dorna",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold)),
                  Text("Stay curious today",
                      style: TextStyle(color: Colors.white54, fontSize: 10.sp)),
                ],
              ),
            ],
          ),
          Row(
            children: [
              _buildTopIconButton(Icons.edit_outlined, Colors.green),
              SizedBox(width: 8.sp),
              _buildTopIconButton(Icons.terminal, Colors.white70),
              SizedBox(width: 8.sp),
              _buildTopIconButton(Icons.wb_sunny_outlined, Colors.white70),
              SizedBox(width: 8.sp),
              const Icon(Icons.more_horiz, color: Colors.white70),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopIconButton(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF15171C),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2D313A)),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  Widget _buildGreetingSection() {
    final now = DateTime.now();
    final formattedDate = DateFormat('MMMM d, y').format(now);
    final greeting = _getGreeting(now.hour);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 10.sp),
      child: Obx(() {
        final userName = authController.getUserDetails.fullName ?? "Sam";
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Daily Brief • $formattedDate",
                style: TextStyle(color: Colors.white38, fontSize: 10.sp)),
            SizedBox(height: 10.sp),
            RichText(
              text: TextSpan(
                style: TextStyle(
                    fontSize: 26.sp,
                    height: 1.2,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
                children: [
                  TextSpan(text: "$greeting\n"),
                  TextSpan(
                      text: userName,
                      style: TextStyle(color: Colors.orange[600])),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  Widget _buildHeroVideoSection() {
    return GestureDetector(
      onTap: () => controller.playPodcast('hero'),
      child: Center(
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 15.sp),
          width: 90.w,
          height: 22.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            image: const DecorationImage(
              image: CachedNetworkImageProvider(
                  "https://images.unsplash.com/photo-1614850523060-8da1d56ae167?q=80&w=600&auto=format&fit=crop"),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25), color: Colors.black26),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white30),
                ),
                child:
                    const Icon(Icons.play_arrow, color: Colors.white, size: 30),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabsSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 10.sp),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildTabItem("For You", activeTab == 'foryou'),
              SizedBox(width: 25.sp),
              _buildTabItem("Discover", activeTab == 'discover'),
            ],
          ),
          const Icon(Icons.refresh, color: Colors.white38, size: 20),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, bool isSelected) {
    return GestureDetector(
      onTap: () =>
          setState(() => activeTab = title.toLowerCase().replaceAll(' ', '')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white38,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold)),
          if (isSelected)
            Container(
                margin: const EdgeInsets.only(top: 4),
                width: 25.sp,
                height: 2,
                color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildPodcastFeed() {
    return Obx(() {
      final now = DateTime.now();
      final items = controller.podcastFeed.values.where((p) {
        if (p.id == 'hero') return false;
        if (p.createdAt == null) return false;
        final created = p.createdAt!.toLocal();
        return created.year == now.year &&
            created.month == now.month &&
            created.day == now.day;
      }).toList();

      if (items.isEmpty) {
        return Padding(
          padding: EdgeInsets.all(20.sp),
          child: Center(
            child: Text(
              "No podcasts for today yet.",
              style: TextStyle(color: Colors.white54, fontSize: 11.sp),
            ),
          ),
        );
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.sp),
        itemCount: items.length,
        itemBuilder: (context, index) =>
            _buildPremiumPodcastCard(items[index], index),
      );
    });
  }

  Widget _buildPremiumPodcastCard(PodcastCardData item, int index) {
    String dateStr = "";
    if (item.createdAt != null) {
      dateStr = DateFormat('MMM y').format(item.createdAt!.toLocal());
    }

    return GestureDetector(
      onTap: () => controller.playPodcast(item.id),
      child: Container(
        height: 180.sp,
        margin: EdgeInsets.only(bottom: 20.sp),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25.sp),
          image: DecorationImage(
            image: CachedNetworkImageProvider(item.imageUrl.isNotEmpty
                ? item.imageUrl
                : "https://images.unsplash.com/photo-1488646953014-85cb44e25828?auto=format&fit=crop&q=80&w=800"),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25.sp),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
            ),
          ),
          padding: EdgeInsets.all(18.sp),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 5.sp),
              Text(item.description,
                  maxLines: 2,
                  style: TextStyle(color: Colors.white70, fontSize: 10.sp)),
              SizedBox(height: 10.sp),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Episode #${index + 1} • $dateStr",
                      style: TextStyle(color: Colors.white38, fontSize: 8.sp)),
                  const Icon(Icons.bookmark_outline,
                      color: Colors.white54, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
