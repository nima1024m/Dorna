import 'dart:async';

import 'package:dorna/controllers/auth/auth_controller.dart';
import 'package:dorna/utils/utils.dart';
import 'package:dorna/widgets/auth/auth_skeleton.dart';
import 'package:dorna/widgets/ui/app_colors.dart';
import 'package:dorna/widgets/ui/custom_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:open_mail/open_mail.dart';

import '../../widgets/auth/auth_header.dart';
import '../../widgets/ui/toast.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  static const routeName = '/email_verification';

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final String _email =
      (Get.arguments != null ? Get.arguments['email'] : null) ?? '';

  // Resend cooldown timer
  int _resendCountdown = 0; // seconds remaining; 0 means enabled
  Timer? _resendTimer;
  bool _isResending = false;

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> _openEmailApp() async {
    // Android: Will open mail app or show native picker.
    // iOS: Will open mail app if single mail app found, or show iOS action sheet if multiple apps found.
    var result = await OpenMail.getMailApps();

    // If no mail apps found, show error
    if (result.isEmpty) {
      showCustomToast('No mail apps found', context, isError: true);
    } else if (result.length > 1) {
      // Multiple mail apps found on iOS - show native iOS action sheet
      _showIOSActionSheet(result);
    } else {
      OpenMail.openMailApp();
    }
  }

  Future<void> _showIOSActionSheet(List<MailApp> mailApps) async {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Open Email App'),
        message: const Text('Select an email app to open'),
        actions: mailApps.map((app) {
          return CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              OpenMail.openSpecificMailApp(app.name);
            },
            child: Text(app.name),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          isDestructiveAction: true,
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _startResendTimer() {
    // Start 15-second cooldown
    _resendTimer?.cancel();
    setState(() {
      _resendCountdown = 15;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _resendCountdown = (_resendCountdown - 1).clamp(0, 15);
      });
      if (_resendCountdown == 0) {
        timer.cancel();
      }
    });
  }

  Future<void> onResendTap() async {
    if (_resendCountdown > 0 || _isResending) return;
    setState(() {
      _isResending = true;
    });
    try {
      final result = await _authController.resendActivation(email: _email);
      if (result == true) {
        _startResendTimer();
        showCustomToast('Email has been sent successfully.', context,
            isSuccess: true);
      } else {}
    } catch (e) {
      showCustomToast('Failed to send email. Please try again.', context,
          isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Utils.appContext = context;
    bool isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: AuthSkeleton(
          topWidgets: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.successText.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/ic_user.svg',
                  width: 22,
                  height: 22,
                  color: AppColors.successText,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const AuthHeader(
              title: 'Account created!',
              subtitle: 'To verify your account:',
              description:
                  'An email with a verification link is on its way! Please open it, verify your account, then come back here to start using the app.\nWe can’t wait to have you on board 🎉',
            ),
          ],
          bottomWidgets: [
            const Spacer(),
            Center(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Didn’t receive email? ',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: AppColors.greySubtext(),
                          fontSize: 12.sp,
                        ),
                  ),
                  GestureDetector(
                    onTap: (onResendTap),
                    child: Text(
                      'Resend',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: (_resendCountdown == 0 && !_isResending)
                                ? AppColors.warningText
                                : AppColors.greySubtext(),
                            fontSize: 12.sp,
                          ),
                    ),
                  ),
                  if (_resendCountdown > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        '${_resendCountdown}s',
                        style:
                            Theme.of(context).textTheme.displayLarge?.copyWith(
                                  color: AppColors.greySubtext(),
                                  fontSize: 12.sp,
                                ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(
              height: 24,
            ),
          ],
          mainButton: CustomButton(
            onPressed: _openEmailApp,
            text: 'Go to email app',
            textSize: 14.sp,
          ),
          isKeyboardOpen: isKeyboardOpen,
        ),
      ),
    );
  }
}
