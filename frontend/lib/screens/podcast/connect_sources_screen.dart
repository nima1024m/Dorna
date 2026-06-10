import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

import 'preparing_podcast_screen.dart';

class ConnectSourcesScreen extends StatefulWidget {
  static const routeName = '/podcast/connect_sources';

  const ConnectSourcesScreen({super.key});

  @override
  State<ConnectSourcesScreen> createState() => _ConnectSourcesScreenState();
}

class _ConnectSourcesScreenState extends State<ConnectSourcesScreen> {
  bool isCalendarConnected = false;
  bool isMailConnected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D11),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSourceCard(
              title: "Google Calendar",
              desc: "To include your meetings in the briefing",
              icon: Icons.calendar_today_outlined,
              isConnected: isCalendarConnected,
              onTap: () =>
                  setState(() => isCalendarConnected = !isCalendarConnected),
            ),
            _buildSourceCard(
              title: "Work Email",
              desc: "To summarize your important emails",
              icon: Icons.mail_outline,
              isConnected: isMailConnected,
              onTap: () => setState(() => isMailConnected = !isMailConnected),
            ),
            const Spacer(),
            _buildContinueButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(20.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Get.back(),
          ),
          SizedBox(height: 10.sp),
          Text(
            "Connect sources",
            style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 5.sp),
          Text(
            "To build your personal briefing.",
            style: TextStyle(color: Colors.white54, fontSize: 11.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceCard({
    required String title,
    required String desc,
    required IconData icon,
    required bool isConnected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.sp, vertical: 8.sp),
      padding: EdgeInsets.all(15.sp),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: isConnected ? Colors.blueAccent : Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.sp),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: Colors.blueAccent),
          ),
          SizedBox(width: 15.sp),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp)),
                Text(desc,
                    style: TextStyle(color: Colors.white54, fontSize: 10.sp)),
              ],
            ),
          ),
          Switch(
            value: isConnected,
            onChanged: (v) => onTap(),
            activeColor: Colors.blueAccent,
          )
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return Padding(
      padding: EdgeInsets.all(20.sp),
      child: SizedBox(
        width: double.infinity,
        height: 45.sp,
        child: ElevatedButton(
          onPressed: () => Get.toNamed(PreparingPodcastScreen.routeName),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: Text("Build My Briefing",
              style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ),
      ),
    );
  }
}
