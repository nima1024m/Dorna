import 'package:dorna/utils/utils.dart';
import 'package:dorna/widgets/ui/app_colors.dart';
import 'package:flutter/material.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String description;
  final double? titleSize;
  final double? descriptionSize;

  const AuthHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.description,
    this.titleSize,
    this.descriptionSize,
  });

  @override
  Widget build(BuildContext context) {
    var isSmallDevice = Utils.isSmallDevice(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: titleSize ?? (isSmallDevice ? 25.sp : 30.sp),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain(),
                      ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallDevice || subtitle == null ? 16 : 24),
        if (subtitle != null)
          Text(
            subtitle.toString(),
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 15.sp,
                color: AppColors.textMain(),
                fontWeight: FontWeight.w700,
              ),
        ),
        if (subtitle != null) const SizedBox(height: 8),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: descriptionSize ?? 13.sp,
                color: AppColors.greySubtext().withOpacity(0.8),
                height: descriptionSize == null ? 1.6 : 1.3,
              ),
        ),
      ],
    );
  }
}
