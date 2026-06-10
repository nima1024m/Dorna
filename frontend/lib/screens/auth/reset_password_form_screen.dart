import 'package:dorna/screens/auth/auth_screen.dart';
import 'package:dorna/screens/auth/sign_in_screen.dart';
import 'package:dorna/utils/password_validator.dart';
import 'package:dorna/utils/utils.dart';
import 'package:dorna/widgets/auth/auth_header.dart';
import 'package:dorna/widgets/auth/auth_skeleton.dart';
import 'package:dorna/widgets/ui/custom_button.dart';
import 'package:dorna/widgets/ui/custom_form_input.dart';
import 'package:dorna/widgets/ui/toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth/auth_controller.dart';
import '../../widgets/auth/password_tips.dart';

class ResetPasswordFormScreen extends StatefulWidget {
  const ResetPasswordFormScreen({super.key});

  static const routeName = '/reset_password_form_screen';

  @override
  State<ResetPasswordFormScreen> createState() =>
      _ResetPasswordFormScreenState();
}

class _ResetPasswordFormScreenState extends State<ResetPasswordFormScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  final GlobalKey<FormState> _formKeyNewPassword = GlobalKey<FormState>();
  final GlobalKey<FormState> _formKeyConfirmPassword = GlobalKey<FormState>();
  final AuthController _authController = Get.find<AuthController>();

  bool _isSubmitting = false;
  bool _showPasswordTips = false;
  String? _apiError;
  final String _email =
      (Get.arguments != null ? Get.arguments['email'] : null) ?? '';
  final String _verifyToken =
      (Get.arguments != null ? Get.arguments['verifyToken'] : null) ?? '';

  bool get _hasMinLength =>
      PasswordValidator.hasMinLength(_newPasswordController.text);

  bool get _hasNumber =>
      PasswordValidator.hasNumber(_newPasswordController.text);

  bool get _hasLower => PasswordValidator.hasLower(_newPasswordController.text);

  bool get _hasUpper => PasswordValidator.hasUpper(_newPasswordController.text);

  String? _validatePassword(String? v) {
    return PasswordValidator.validate(v);
  }

  String? _validateConfirmPassword(String? v) {
    if (v == null || v.isEmpty) return 'Please confirm password';
    if (v != _newPasswordController.text) return "Passwords must match";
    if (_apiError != null) return _apiError;
    return null;
  }

  Future<void> _onResetPasswordTap() async {
    setState(() {
      _apiError = null;
    });
    bool validate1 = _formKeyNewPassword.currentState!.validate();
    bool validate2 = _formKeyConfirmPassword.currentState!.validate();

    if (!validate1 || !validate2) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final ok = await _authController.resetPassword(
        email: _email,
        newPassword: _newPasswordController.text,
        verifyToken: _verifyToken,
      );

      if (ok == true) {
        showCustomToast('Password reset successfully', context,
            isSuccess: true);
        Get.offNamedUntil(
          SignInScreen.routeName,
          (route) => route.settings.name == AuthScreen.routeName,
        );
      } else if (ok == false) {
        setState(() {
          _apiError = 'Failed to reset password. Please try again.';
        });
        _formKeyConfirmPassword.currentState!.validate();
        Future.delayed(const Duration(milliseconds: 500)).then((v) {
          _apiError = null;
        });
      }
    } catch (e) {
      String message = e.getDioBackendErrorMessage() ??
          'Failed to reset password. Please try again.';
      setState(() {
        _apiError = message;
      });
      _formKeyConfirmPassword.currentState!.validate();
      Future.delayed(const Duration(milliseconds: 500)).then((v) {
        _apiError = null;
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _passwordFocus.addListener(() {
      if (mounted) {
        setState(() {
          _showPasswordTips = _passwordFocus.hasFocus;
        });
      }
    });
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
              const AuthHeader(
                title: 'Reset password',
                subtitle: 'To set new password:',
                description:
                    'Your new password must be different from the old one.',
              ),
              const SizedBox(height: 32),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomFormInput(
                      title: 'New password',
                      hintText: 'Enter your new password',
                      controller: _newPasswordController,
                      isSecureText: true,
                      validator: (v) => _validatePassword(v as String?),
                      formKey: _formKeyNewPassword,
                      inputFocusNode: _passwordFocus,
                      nextFocusNode: _confirmPasswordFocus,
                      onChanged: (_) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 48),
                    CustomFormInput(
                      title: 'Confirm password',
                      hintText: 'Repeat your password',
                      controller: _confirmPasswordController,
                      isSecureText: true,
                      validator: (v) => _validateConfirmPassword(v as String?),
                      formKey: _formKeyConfirmPassword,
                      inputFocusNode: _confirmPasswordFocus,
                    ),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 70,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: _showPasswordTips && isKeyboardOpen
                        ? PasswordTips(
                            hasText: _newPasswordController.text.isNotEmpty,
                            hasMinLength: _hasMinLength,
                            hasNumber: _hasNumber,
                            hasLower: _hasLower,
                            hasUpper: _hasUpper,
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
            ],
            bottomWidgets: [],
            mainButton: CustomButton(
              onPressed: _onResetPasswordTap,
              text: 'Reset password',
              loading: _isSubmitting,
              textSize: 14.sp,
            ),
            isKeyboardOpen: isKeyboardOpen,
          ),
      ),
    );
  }
}
