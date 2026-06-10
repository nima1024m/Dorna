import 'dart:async';

import 'package:dorna/screens/auth/reset_password_form_screen.dart';
import 'package:dorna/utils/utils.dart';
import 'package:dorna/widgets/auth/auth_header.dart';
import 'package:dorna/widgets/auth/auth_skeleton.dart';
import 'package:dorna/widgets/ui/app_colors.dart';
import 'package:dorna/widgets/ui/custom_button.dart';
import 'package:dorna/widgets/ui/toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../controllers/auth/auth_controller.dart';

class ResetPasswordOtpScreen extends StatefulWidget {
  const ResetPasswordOtpScreen({super.key});

  static const routeName = '/reset_password_otp_screen';

  @override
  State<ResetPasswordOtpScreen> createState() => _ResetPasswordOtpScreenState();
}

class _ResetPasswordOtpScreenState extends State<ResetPasswordOtpScreen> {
  final TextEditingController _otpController = TextEditingController();

  final FocusNode _otpFocus = FocusNode();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthController _authController = Get.find<AuthController>();

  bool _isSubmitting = false;
  String? _apiError;
  final String _email =
      (Get.arguments != null ? Get.arguments['email'] : null) ?? '';

  // Resend cooldown timer
  int _resendCountdown = 0; // seconds remaining; 0 means enabled
  Timer? _resendTimer;
  bool _isResending = false;
  bool removeErrors = false;

  String? _validateOtp(String? v) {
    if (removeErrors) {
      return null;
    }
    if (v == null || v.trim().isEmpty) return 'OTP is required';
    if (_apiError != null) return _apiError;
    return null;
  }

  Future<void> _onVerifyTap() async {
    setState(() {
      _apiError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final token = await _authController.verifyReset(
        email: _email,
        code: _otpController.text.trim(),
      );

      if (token != null && token.isNotEmpty) {
        Get.toNamed(
          ResetPasswordFormScreen.routeName,
          arguments: {
            'email': _email,
            'verifyToken': token,
          },
        );
      } else {
        setState(() {
          _apiError = 'Invalid or expired code.';
        });
        _formKey.currentState!.validate();
      }
    } catch (e) {
      String message =
          e.getDioBackendErrorMessage() ?? 'Invalid or expired code.';
      setState(() {
        _apiError = message;
      });
      _formKey.currentState!.validate();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
      final result = await _authController.forgotPassword(email: _email);
      if (result == true) {
        _startResendTimer();
        showCustomToast('Email has been sent successfully.', context,
            isSuccess: true);
      } else if (result == false) {
        setState(() {
          _apiError = 'Failed to send email. Please try again.';
        });
        _formKey.currentState!.validate();
        Future.delayed(const Duration(milliseconds: 500)).then((v) {
          _apiError = null;
        });
      }
    } catch (e) {
      String message = e.getDioBackendErrorMessage() ??
          'Failed to send email. Please try again.';
      if (e.getDioError()?.response?.statusCode == 500) {
        if (e.getDioError()?.response?.data.toString().contains('not_found') ==
            true) {
          message = 'Email not found.';
        } else {
          showNetworkToast(e: e.getDioError()!, context: Utils.appContext!);
        }
      }
      setState(() {
        _apiError = message;
      });
      _formKey.currentState!.validate();
      Future.delayed(const Duration(milliseconds: 500)).then((v) {
        _apiError = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocus.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _otpFocus.addListener(() {
      if (_otpFocus.hasFocus) {
        removeErrors = true;
        _formKey.currentState?.validate();
        Future.delayed(const Duration(milliseconds: 500)).then((v) {
          removeErrors = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Utils.appContext = context;
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: AuthSkeleton(
            isScrollOnOpenKeybpard: false,
            isKeyboardOpen: false,
            parentContext: context,
            topWidgets: [
              const AuthHeader(
                title: 'Reset password',
                subtitle: 'To set new password:',
                description:
                    'We have sent you an email with a code, Please check your inbox and enter the code here.',
              ),
              const SizedBox(height: 32),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TapRegion(
                    onTapUpOutside: (e) {
                      _formKey.currentState?.validate();
                      _otpFocus.unfocus();
                    },
                    child: PinCodeTextField(
                      onChanged: (value) {
                        _apiError = null;
                        if (value.isEmpty == true) {
                          removeErrors = true;
                          _formKey.currentState?.validate();
                          Future.delayed(const Duration(milliseconds: 200))
                              .then((v) {
                            removeErrors = false;
                          });
                        }
                      },
                      onSubmitted: (s) {
                        _formKey.currentState?.validate();
                      },
                      focusNode: _otpFocus,
                      length: 5,
                      appContext: context,
                      controller: _otpController,
                      animationType: AnimationType.scale,
                      enableActiveFill: true,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      errorTextSpace: 32,
                      validator: _validateOtp,
                      keyboardType: TextInputType.number,
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(
                          12,
                        ),
                        fieldHeight: 55,
                        fieldWidth: 55,
                        borderWidth: 1.5,
                        activeBorderWidth: 1.5,
                        inactiveBorderWidth: 1.5,
                        activeColor: AppColors.greySubtext(),
                        selectedColor: Theme.of(context).colorScheme.secondary,
                        selectedFillColor: isDarkMode
                            ? Colors.transparent
                            : Colors.grey.shade100,
                        inactiveFillColor: Colors.transparent,
                        inactiveColor: AppColors.greySubtext(),
                        activeFillColor:
                            isDarkMode ? Colors.transparent : Colors.white,
                        errorBorderColor: AppColors.errorText,
                        errorBorderWidth: 1.5,
                      ),
                      cursorColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
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
                      onTap: (_resendCountdown == 0 && !_isResending)
                          ? onResendTap
                          : null,
                      child: Text(
                        'Resend',
                        style: Theme.of(context)
                            .textTheme
                            .displayLarge
                            ?.copyWith(
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
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(
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
              onPressed: _onVerifyTap,
              text: 'Verify',
              loading: _isSubmitting,
              textSize: 14.sp,
            ),
          ),
        ),
      ),
    );
  }
}
