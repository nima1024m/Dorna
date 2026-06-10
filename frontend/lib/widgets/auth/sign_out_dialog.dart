import 'package:dorna/controllers/auth/auth_controller.dart';
import 'package:dorna/screens/auth/auth_screen.dart';
import 'package:dorna/utils/utils.dart';
import 'package:dorna/widgets/ui/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SignOutDialog extends StatelessWidget {
  const SignOutDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Theme(
      data: Theme.of(context),
      child: CupertinoAlertDialog(
        title: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Sign out of account?',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 13.sp,
                ),
          ),
        ),
        content: const SizedBox.shrink(),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'Cancel',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDarkMode
                        ? CupertinoColors.white
                        : CupertinoColors.label,
                    fontSize: 13.sp,
                  ),
            ),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              AuthController authController = AuthController();
              authController.logout();
              Navigator.of(context).pop();
              Get.offAllNamed(AuthScreen.routeName);
            },
            child: Text(
              'Sign out',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppColors.errorText,
                    fontSize: 13.sp,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
