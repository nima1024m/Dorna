import 'package:dorna/theme/app_tokens.dart';
import 'package:dorna/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class PasswordTips extends StatelessWidget {
  final bool hasText;
  final bool hasMinLength;
  final bool hasNumber;
  final bool hasLower;
  final bool hasUpper;

  const PasswordTips({
    super.key,
    required this.hasText,
    required this.hasMinLength,
    required this.hasNumber,
    required this.hasLower,
    required this.hasUpper,
  });

  Widget _row(BuildContext context, bool ok, String text) {
    final cs = Theme.of(context).colorScheme;
    final colorOk = DornaColors.success;
    final colorBad = cs.error;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (hasText)
          Icon(ok ? Icons.check : Icons.close,
              size: 16, color: ok ? colorOk : colorBad)
        else
          Padding(
            padding: const EdgeInsets.all(5.5),
            child: Icon(Icons.circle, size: 5, color: cs.onSurface),
          ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12.sp,
                  color: cs.onSurface,
                ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHigh;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(right: 48),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _row(context, hasMinLength, 'Minimum 8 characters'),
              const SizedBox(height: 4),
              _row(context, hasNumber, 'At least one numeral (0–9)'),
              const SizedBox(height: 4),
              _row(context, hasLower, 'At least one lowercase letter'),
              const SizedBox(height: 4),
              _row(context, hasUpper, 'At least one uppercase letter'),
            ],
          ),
        ),
        Positioned(
          top: -8,
          left: 16,
          child: SvgPicture.asset(
            'assets/icons/ic_triangle.svg',
            height: 12,
            color: color,
          ),
        ),
      ],
    );
  }
}
