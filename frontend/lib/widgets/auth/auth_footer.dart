import 'package:dorna/theme/app_tokens.dart';
import 'package:dorna/utils/utils.dart';
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12.sp,
                    ),
              ),
              Text(
                actionText,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: DornaColors.warning,
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
