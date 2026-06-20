import 'package:dorna/utils/utils.dart';
import 'package:flutter/material.dart';

class AuthDivider extends StatelessWidget {
  final String text;

  const AuthDivider({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: cs.onSurfaceVariant.withOpacity(0.2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: 12.sp,
                ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: cs.onSurfaceVariant.withOpacity(0.2),
          ),
        ),
      ],
    );
  }
}
