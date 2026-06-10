import 'package:dorna/utils/utils.dart';
import 'package:dorna/widgets/ui/app_colors.dart';
import 'package:flutter/material.dart';

class AuthFooter extends StatelessWidget {
  final String questionText;
  final String actionText;
  final VoidCallback onTap;

  const AuthFooter({
    super.key,
    required this.questionText,
    required this.actionText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                questionText,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppColors.greySubtext(),
                      fontSize: 12.sp,
                    ),
              ),
              Text(
                actionText,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppColors.warningText,
                      fontSize: 12.sp,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
