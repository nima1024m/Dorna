import 'package:dorna/utils/utils.dart';
import 'package:dorna/widgets/ui/app_colors.dart';
import 'package:flutter/material.dart';

class AuthDivider extends StatelessWidget {
  final String text;

  const AuthDivider({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.greySubtext().withOpacity(0.2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppColors.greySubtext(),
                  fontSize: 12.sp,
                ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.greySubtext().withOpacity(0.2),
          ),
        ),
      ],
    );
  }
}
