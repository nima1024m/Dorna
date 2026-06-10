import 'package:flutter/material.dart';

class InstructionBackground extends StatelessWidget {
  final Widget child;

  const InstructionBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDarkMode
          ? Theme.of(context).scaffoldBackgroundColor
          : const Color(0xFFF0F8FF),
      // Light blue background
      body: Stack(
        children: [
          // Background scattered letters
          if (!isDarkMode)
            Image.asset(
              'assets/images/auth_background.png',
              width: MediaQuery.sizeOf(context).width,
              height: MediaQuery.sizeOf(context).height,
              fit: BoxFit.cover,
            ),
          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 8),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
