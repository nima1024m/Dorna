import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../controllers/auth/auth_controller.dart';
import '../../utils/utils.dart';
import '../ui/toast.dart';

class SocialButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const SocialButton({super.key, required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        width: 76,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.25),
              width: 1),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      AuthController authController = Get.find();
      return SocialButton(
        child: authController.loadingGoogleLogin.value
            ? const Center(child: CircularProgressIndicator())
            : SvgPicture.asset(
                'assets/icons/ic_google.svg',
                width: 22,
                height: 22,
              ),
        onTap: () async {
          try {
            final isSuccessful = await authController.googleSignIn();
            if (isSuccessful == true) {
              showCustomToast('Sign in successful!', context, isSuccess: true);
              await Utils.handleKeyboardPermissionNavigation();
            } else if (isSuccessful == false) {
              showCustomToast('Sign in failed. Please try again.', context,
                  isError: true);
            }
          } catch (e) {
            String errorMessage = 'Google sign-in failed. Please try again';
            if (e.getDioError()?.response?.statusCode == 401) {
              errorMessage = 'Invalid Google credentials. Please try again.';
            }
            errorMessage = e.getDioBackendErrorMessage() ?? errorMessage;
            showCustomToast(errorMessage, context, isError: true);
          }
        },
      );
    });
  }
}

class AppleSignInButton extends StatelessWidget {
  const AppleSignInButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      AuthController authController = Get.find();
      return SocialButton(
        child: authController.loadingAppleLogin.value
            ? const Center(child: CircularProgressIndicator())
            : Icon(
                Icons.apple,
                size: 28,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        onTap: () async {
          try {
            final isSuccessful = await authController.appleSignIn();
            if (isSuccessful == true) {
              showCustomToast('Sign in successful!', context, isSuccess: true);
              await Utils.handleKeyboardPermissionNavigation();
            } else if (isSuccessful == false) {
              showCustomToast('Sign in failed. Please try again.', context,
                  isError: true);
            }
          } catch (e) {
            String errorMessage = 'Apple sign-in failed. Please try again';
            if (e.getDioError()?.response?.statusCode == 401) {
              errorMessage = 'Invalid Apple credentials. Please try again.';
            }
            errorMessage = e.getDioBackendErrorMessage() ?? errorMessage;
            showCustomToast(errorMessage, context, isError: true);
          }
        },
      );
    });
  }
}
