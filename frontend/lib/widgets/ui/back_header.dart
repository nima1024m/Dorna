import 'package:dorna/utils/utils.dart';
import 'package:dorna/widgets/ui/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class BackHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final Color? backgroundColor;
  final VoidCallback? onBackPressed;
  final Widget? trailingWidget;

  const BackHeader({
    super.key,
    this.titleWidget,
    this.title,
    this.backgroundColor,
    this.onBackPressed,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.only(
          left: 0,
          right: 12,
          top: 8,
          bottom: 8,
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onBackPressed ?? () => Get.back(),
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.only(
                    left: 12, right: 16, top: 8, bottom: 8),
                alignment: Alignment.centerRight,
                child: SvgPicture.asset(
                  'assets/icons/arrow_back.svg',
                  height: 16,
                  color: AppColors.textMain(),
                ),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: titleWidget != null
                    ? titleWidget!
                    : (title ?? '').isNotEmpty
                        ? Text(
                            title.toString(),
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppColors.textMain(),
                                      fontSize: 14.sp,
                                    ),
                          )
                        : null,
              ),
            ),
            if (trailingWidget != null)
              trailingWidget!
            else
              const SizedBox(width: 38),
            // Maintain consistent spacing when no trailing widget
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
