import 'package:dorna/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'app_colors.dart';
import 'custom_list_tile.dart';

class CustomSwitchTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String leadingIcon;
  final String? subtitle;
  final EdgeInsets? margin;

  const CustomSwitchTile({
    Key? key,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.leadingIcon,
    this.subtitle,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var padding = margin ?? const EdgeInsets.symmetric(horizontal: 12);
    return Padding(
      padding: padding,
      child: Column(
        children: [
          CustomListTile(
            title: title,
            onTap: null,
            leading: SvgPicture.asset(
              leadingIcon,
              width: 22,
              height: 22,
              color: AppColors.textMain(),
            ),
            trailing: Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: AppColors.primaryColor(),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.black.withOpacity(0.1),
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            ),
            showArrow: subtitle == null,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            margin: EdgeInsets.zero,
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 20, right: 20),
              child: Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.greySubtext().withOpacity(0.5),
                      fontSize: 13.sp,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
