import 'package:dorna/controllers/keyboard_status/keyboard_status_controller.dart';
import 'package:dorna/utils/utils.dart';
import 'package:dorna/widgets/ui/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../ui/custom_underline_text.dart';

class KeyboardStatusView extends StatelessWidget {
  const KeyboardStatusView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final KeyboardStatusController controller =
        Get.find<KeyboardStatusController>();
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    const duration = Duration(milliseconds: 300);

    return Obx(() {
      return AnimatedContainer(
        duration: duration,
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16,
        ),
        decoration: BoxDecoration(
          color: controller.getBackgroundColor(isDarkMode),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Icon
            AnimatedContainer(
              duration: duration,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: controller.getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: controller.getStatusColor().withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Center(
                child: controller.loading.value
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: Center(
                            child: CircularProgressIndicator(
                          strokeWidth: 2,
                        )))
                    : SvgPicture.asset(
                        controller.getStatusIcon(),
                        width: 16,
                        height: 16,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Status Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Keyboard status:',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: AppColors.greySubtext().withOpacity(0.5),
                          fontSize: 13.sp,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          controller.getStatusMessage(),
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: controller.loading.value
                                        ? (isDarkMode
                                            ? const Color(0xffC9D4DC)
                                                .withOpacity(0.3)
                                            : const Color(0xff232E36)
                                                .withOpacity(0.3))
                                        : AppColors.greySubtext(),
                                    fontSize: 14.sp,
                                  ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Action Button (if needed)
                      if (controller.keyboardStatus ==
                              KeyboardStatus.inactive &&
                          !controller.loading.value)
                        GestureDetector(
                          onTap: () async {
                            await Utils.handleKeyboardPermissionNavigation(
                              navigateToHomeOnGrantPermission: false,
                            );
                          },
                          child: CustomUnderlineText(
                            'Enable keyboard',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  color: AppColors.primaryColor(),
                                  fontSize: 12.sp,
                                ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
