import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';
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
    final accent = textColor ?? DornaColors.warning;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: CustomButton(
        onPressed: onPressed,
        text: text,
        loading: loading,
        loadingColor: accent,
        border: border ?? Border.all(color: accent, width: 1.5),
        backgroundColor: backgroundColor ?? Colors.transparent,
        textColor: accent,
      ),
    );
  }
}
