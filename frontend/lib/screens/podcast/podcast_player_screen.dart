import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

import '../../controllers/podcast/podcast_controller.dart';
import '../../models/podcast_model.dart';

class PodcastPlayerScreen extends StatefulWidget {
  static const routeName = '/podcast_player_screen';

  const PodcastPlayerScreen({super.key});

  @override
  State<PodcastPlayerScreen> createState() => _PodcastPlayerScreenState();
}

class _PodcastPlayerScreenState extends State<PodcastPlayerScreen>
    with TickerProviderStateMixin {
  final PodcastController controller = Get.find<PodcastController>();
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _itemKeys = {};

  late AnimationController _glowController;
  late Animation<Offset> _orangeGlowAnim;
  late Animation<Offset> _blueGlowAnim;

  @override
  void initState() {
    super.initState();
    _initAnimations();

    // Listen to segment changes to scroll
    ever(controller.currentSegmentIndex, (index) {
      _scrollToActive(index);
    });
  }

  void _initAnimations() {
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _orangeGlowAnim = Tween<Offset>(
      begin: const Offset(-0.3, 0.1),
      end: const Offset(-0.1, 0.4),
    ).animate(
        CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));

    _blueGlowAnim = Tween<Offset>(
      begin: const Offset(0.3, 0.9),
      end: const Offset(0.1, 0.6),
    ).animate(
        CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));
  }

  void _scrollToActive(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Small delay to ensure list is rendered
      Future.delayed(const Duration(milliseconds: 100), () {
        final context = _itemKeys[index]?.currentContext;
        if (context != null) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 800),
            alignment: 0.5, // اسکرول به مرکز صفحه
            curve: Curves.easeInOutCubic,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    controller.disposeAudioPlayer();
    _glowController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
          _buildAmbientGlows(),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildConversationList()),
                _buildBottomControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ... _buildAmbientGlows ...

  Widget _buildAmbientGlows() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              left: _orangeGlowAnim.value.dx * 100.w,
              top: _orangeGlowAnim.value.dy * 100.h,
              child: Container(
                width: 140.w,
                height: 140.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEA580C).withOpacity(0.15),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 140, sigmaY: 140),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            Positioned(
              right: _blueGlowAnim.value.dx * 100.w,
              bottom: _blueGlowAnim.value.dy * 100.h,
              child: Container(
                width: 120.w,
                height: 120.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2563EB).withOpacity(0.12),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.sp, vertical: 10.sp),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 36.sp,
              height: 36.sp,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.keyboard_arrow_down,
                  color: Colors.white, size: 30),
            ),
          ),
          Obx(() {
            final podcastId = controller.activePodcastId.value;
            final podcast = controller.podcastFeed[podcastId];
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.sp),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      podcast?.title ?? "Playing...",
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (podcast?.status == PodcastStatus.generatingAudio ||
                        podcast?.status == PodcastStatus.generatingMeta ||
                        podcast?.status == PodcastStatus.suggested)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          "Generating... ${podcast?.completedSegments ?? 0} / ${podcast?.totalSegments ?? '?'}",
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 8.sp,
                          ),
                        ),
                      )
                  ],
                ),
              ),
            );
          }),
          Row(
            children: [
              _buildActionIcon(Icons.edit, Colors.green),
              SizedBox(width: 8.sp),
              _buildActionIcon(Icons.terminal, Colors.white54),
              SizedBox(width: 8.sp),
              _buildActionIcon(Icons.wb_sunny_outlined, Colors.white54),
              SizedBox(width: 8.sp),
              const Icon(Icons.more_horiz, color: Colors.white, size: 28),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 15.sp),
    );
  }

  Widget _buildConversationList() {
    return Obx(() {
      final podcastId = controller.activePodcastId.value;
      final podcast = controller.podcastFeed[podcastId];
      final activeIndex = controller.currentSegmentIndex.value;

      if (podcast == null) {
        return const Center(
            child: CircularProgressIndicator(color: Colors.blueAccent));
      }

      // If no segments yet, show loading or empty
      if (podcast.segments.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.blueAccent),
              SizedBox(height: 16.sp),
              Text(
                "Preparing script...",
                style: TextStyle(color: Colors.white54, fontSize: 12.sp),
              )
            ],
          ),
        );
      }

      return ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(24.sp, 40.sp, 24.sp, 150.sp),
        itemCount: podcast.segments.length,
        itemBuilder: (context, index) {
          final segment = podcast.segments[index];
          final isActive = index == activeIndex;
          final itemKey = _itemKeys.putIfAbsent(index, () => GlobalKey());

          return AnimatedOpacity(
            duration: const Duration(milliseconds: 600),
            key: itemKey,
            opacity: isActive ? 1.0 : 0.15,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 600),
              scale: isActive ? 1.0 : 0.94,
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(bottom: 40.sp),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive ? Colors.white : Colors.white24,
                          ),
                        ),
                        SizedBox(width: 12.sp),
                        Text(
                          segment.speaker.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 8.5.sp,
                            fontWeight: FontWeight.w900,
                            // فوق بولد برای نام گوینده
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.sp),
                    Text(
                      segment.text,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22.sp,
                        // فونت درشت و خوانا
                        fontWeight: FontWeight.w700,
                        // بولد
                        height: 1.3,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildBottomControls() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          24.sp, 10.sp, 24.sp, MediaQuery.of(context).padding.bottom + 10.sp),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black,
            Colors.black.withOpacity(0.95),
            Colors.black.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Obx(() => _buildCircleButton(
                "${controller.voiceSpeed.value}x",
                onTap: () => _showSpeedSelection(context),
              )),
          const SizedBox(
            width: 24,
          ),
          // Expanded(
          //   child: Container(
          //     height: 54.sp,
          //     margin: EdgeInsets.symmetric(horizontal: 15.sp),
          //     decoration: BoxDecoration(
          //       color: Colors.white,
          //       borderRadius: BorderRadius.circular(35),
          //       boxShadow: [
          //         BoxShadow(
          //           color: Colors.white.withOpacity(0.25),
          //           blurRadius: 30,
          //           spreadRadius: 1,
          //         )
          //       ],
          //     ),
          //     child: Row(
          //       mainAxisAlignment: MainAxisAlignment.center,
          //       children: [
          //         const Icon(Icons.mic, color: Colors.black, size: 24),
          //         SizedBox(width: 8.sp),
          //         Text(
          //           "Ask to Join",
          //           style: TextStyle(
          //             color: Colors.black,
          //             fontSize: 14.5.sp,
          //             fontWeight: FontWeight.w900, // بسیار بولد
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
          Obx(() => _buildCircleButton(
                null,
                icon: controller.isPlaying.value
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                onTap: () => controller.togglePlayPause(),
              )),
        ],
      ),
    );
  }

  Widget _buildCircleButton(String? text,
      {IconData? icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50.sp,
        height: 50.sp,
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: Colors.white, size: 32)
              : Text(text!,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }

  void _showSpeedSelection(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Playback Speed'),
        actions: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
          return CupertinoActionSheetAction(
            child: Text('${speed}x'),
            onPressed: () {
              controller.updateVoiceSpeed(speed);
              Get.back();
            },
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          isDestructiveAction: true,
          onPressed: () {
            Get.back();
          },
        ),
      ),
    );
  }
}
