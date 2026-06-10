import 'package:flutter/material.dart';

import '../ui/app_colors.dart';
import '../ui/custom_button.dart';

class InstructionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final Color? backgroundColor;
  final Color? textColor;
  final Border? border;
  final bool loading;

  const InstructionButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.backgroundColor,
    this.textColor,
    this.border,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: CustomButton(
        onPressed: onPressed,
        text: text,loading:loading ,
        loadingColor: const Color(0xffFF9500),
        border:
            border ?? Border.all(color: AppColors.primaryColor(), width: 1.5),
        backgroundColor: backgroundColor ?? Colors.transparent,
        textColor: textColor ?? AppColors.primaryColor(),
      ),
    );
  }
}
