import 'package:dorna/utils/utils.dart';
import 'package:dorna/widgets/ui/app_colors.dart';
import 'package:dorna/widgets/ui/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../screens/home/home_screen.dart';

class HomeSwitchView extends StatelessWidget {
  final HomeViewType selectedHomeViewType;
  final Function(HomeViewType homeViewType) onHomeTypeChange;

  const HomeSwitchView({
    Key? key,
    required this.selectedHomeViewType,
    required this.onHomeTypeChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(6),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          color: isDarkMode
              ? const Color(0xff141515)
              : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: buildCustomButton(
              context: context,
              homeViewType: HomeViewType.keyboard,
              title: 'Keyboard',
              icon: 'assets/icons/ic_keyboard2.svg',
            ),
          ),
          const SizedBox(
            width: 8,
          ),
          Expanded(
            child: buildCustomButton(
              context: context,
              homeViewType: HomeViewType.settings,
              iconSize: 22,
              title: 'Settings',
              icon: 'assets/icons/ic_settings.svg',
            ),
          ),
        ],
      ),
    );
  }

  CustomButton buildCustomButton({
    required BuildContext context,
    required HomeViewType homeViewType,
    required String title,
    required String icon,
    double iconSize = 19,
  }) {
    bool isSelected = homeViewType == selectedHomeViewType;
    return CustomButton(
      buttonHeight: 50,
      onPressed: () {
        onHomeTypeChange(homeViewType);
      },
      animationDuration: const Duration(milliseconds: 200),
      backgroundColor: isSelected
          ? AppColors.primaryColor().withOpacity(0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      buttonWidget: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            icon,
            width: iconSize,
            height: iconSize,
            color: isSelected
                ? AppColors.primaryColor()
                : AppColors.greySubtext().withOpacity(0.5),
          ),
          const SizedBox(
            width: 8,
          ),
          Text(
            title,
            style: isSelected
                ? Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 14.sp,
                      color: isSelected
                          ? AppColors.primaryColor()
                          : AppColors.greySubtext().withOpacity(0.5),
                    )
                : Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 14.sp,
                  color: isSelected
                          ? AppColors.primaryColor()
                          : AppColors.greySubtext().withOpacity(0.5),
                    ),
          )
        ],
      ),
    );
  }
}
