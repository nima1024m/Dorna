import 'package:flutter/material.dart';

class InstructionCard extends StatelessWidget {
  final Widget child;
  final double width;
  final EdgeInsets? padding;

  const InstructionCard({
    super.key,
    required this.child,
    required this.width,this.padding,

  });

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      padding: padding?? const EdgeInsets.symmetric(horizontal: 32, vertical: 50),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xff141515) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
