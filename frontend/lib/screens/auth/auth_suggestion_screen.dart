import 'dart:io';

import 'package:dorna/screens/auth/sign_in_screen.dart';
import 'package:dorna/screens/auth/sign_up_screen.dart';
import 'package:dorna/utils/utils.dart';
import 'package:dorna/widgets/ui/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../widgets/auth/auth_footer.dart';
import '../../widgets/auth/auth_header.dart';
import '../../widgets/ui/back_header.dart';

class AuthSuggestionScreen extends StatefulWidget {
  const AuthSuggestionScreen({super.key});

  static const routeName = '/auth_suggestion_screen';

  @override
  State<AuthSuggestionScreen> createState() => _AuthSuggestionScreenState();
}

class _AuthSuggestionScreenState extends State<AuthSuggestionScreen> {
  onSignInTap() {
    Get.toNamed(SignInScreen.routeName);
  }

  void onSignUpTap() {
    Get.toNamed(SignUpScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    Utils.appContext = context;
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: BackHeader(),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 32),
                      child: AuthHeader(
                        title: 'Unlock all features',
                        titleSize: 25.sp,
                        descriptionSize: Platform.isIOS ? 15.sp : 14.sp,
                        description:
                            'Sign in or create an account to use all of Dorna’s features, get personalized suggestions and save your preferences.',
                      ),
                    ),
                    const SizedBox(
                      height: 150,
                    ),
                    CustomButton(
                      onPressed: onSignInTap,
                      text: 'Sign in',
                      textSize: 14.sp,
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    AuthFooter(
                      questionText: 'Don\'t have an account? ',
                      actionText: 'Sign up',
                      onTap: onSignUpTap,
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
