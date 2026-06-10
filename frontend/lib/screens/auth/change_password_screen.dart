import 'package:dorna/utils/password_validator.dart';
import 'package:dorna/utils/utils.dart';
import 'package:dorna/widgets/auth/auth_skeleton.dart';
import 'package:dorna/widgets/ui/custom_button.dart';
import 'package:dorna/widgets/ui/custom_form_input.dart';
import 'package:dorna/widgets/ui/toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth/auth_controller.dart';
import '../../widgets/auth/password_tips.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  static const routeName = '/change_password_screen';

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FocusNode _currentPasswordFocus = FocusNode();
  final FocusNode _newPasswordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  final GlobalKey<FormState> _formKeyCurrentPassword = GlobalKey<FormState>();
  final GlobalKey<FormState> _formKeyNewPassword = GlobalKey<FormState>();
  final GlobalKey<FormState> _formKeyConfirmPassword = GlobalKey<FormState>();

  bool _isSubmitting = false;
  bool _showPasswordTips = false;
  String? _apiError;
  final AuthController _authController = Get.find<AuthController>();

  String? _validateCurrentPassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    return null;
  }

  bool get _hasMinLength =>
      PasswordValidator.hasMinLength(_newPasswordController.text);

  bool get _hasNumber =>
      PasswordValidator.hasNumber(_newPasswordController.text);

  bool get _hasLower => PasswordValidator.hasLower(_newPasswordController.text);

  bool get _hasUpper => PasswordValidator.hasUpper(_newPasswordController.text);

  String? _validateNewPassword(String? v) {
    return PasswordValidator.validate(v);
  }

  String? _validateConfirmPassword(String? v) {
    if (v == null || v.isEmpty) return 'Please confirm password';
    if (v != _newPasswordController.text) return "Passwords must match";
    // Fallback: show any API error here if present
    if (_apiError != null) return _apiError;
    return null;
  }

  Future<void> _onResetPasswordTap() async {
    // Clear previous API errors
    setState(() {
      _apiError = null;
    });
    bool validate1 = _formKeyCurrentPassword.currentState!.validate();
    bool validate2 = _formKeyNewPassword.currentState!.validate();
    bool validate3 = _formKeyConfirmPassword.currentState!.validate();

    if (!validate1 || !validate2 || !validate3) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final result = await _authController.changePassword(
        oldPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (result == true) {
        if (mounted) {
          showCustomToast('Password changed successfully', context,
              isSuccess: true);
          Get.back();
        }
      } else if (result == false) {
        setState(() {
          _apiError = 'Failed to change password. Please try again.';
        });
        _formKeyConfirmPassword.currentState!.validate();
        Future.delayed(const Duration(milliseconds: 500)).then((v) {
          _apiError = null;
        });
      }
    } catch (e) {
      String errorMessage = e.getDioBackendErrorMessage() ??
          'Password change failed. Please try again.';
      final status = e.getDioError()?.response?.statusCode;
      if (status == 401 || status == 403) {
        errorMessage = e.getDioBackendErrorMessage() ??
            'Session expired. Please sign in again.';
      } else if (status == 422 || status == 400) {
        errorMessage = e.getDioBackendErrorMessage() ??
            'Current password is incorrect or new password invalid.';
      }
      setState(() {
        _apiError = errorMessage;
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
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _currentPasswordFocus.dispose();
    _newPasswordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _newPasswordFocus.addListener(() {
      if (mounted) {
        setState(() {
          _showPasswordTips = _newPasswordFocus.hasFocus;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // var hintStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
    //       fontSize: 12.sp,
    //       color: isDarkMode
    //           ? const Color(0xffFFFFFF).withOpacity(0.25)
    //           : const Color(0xff2E3633).withOpacity(0.25),
    //     );
    // var labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
    //       color: AppColors.greySubtext(),
    //       fontSize: 13.sp,
    //     );
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: AuthSkeleton(
          isKeyboardOpen: isKeyboardOpen,
          backTitle: 'Change password',
          topWidgets: [
            const SizedBox(
              height: 32,
            ),
            CustomFormInput(
              title: 'Current password',
              hintText: 'Enter your password',
              // hintStyle: hintStyle,
              // labelStyle: labelStyle,
              controller: _currentPasswordController,
              isSecureText: true,
              validator: (v) => _validateCurrentPassword(v as String?),
              formKey: _formKeyCurrentPassword,
              inputFocusNode: _currentPasswordFocus,
              nextFocusNode: _newPasswordFocus,
              onChanged: (_) {
                setState(() {});
              },
            ),
            const SizedBox(height: 48),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomFormInput(
                      title: 'New password',
                      hintText: 'Enter your new password',
                      // hintStyle: hintStyle,
                      // labelStyle: labelStyle,
                      controller: _newPasswordController,
                      isSecureText: true,
                      validator: (v) => _validateNewPassword(v as String?),
                      formKey: _formKeyNewPassword,
                      inputFocusNode: _newPasswordFocus,
                      nextFocusNode: _confirmPasswordFocus,
                      onChanged: (_) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 48),
                    CustomFormInput(
                      title: 'Confirm new password',
                      hintText: 'Repeat your password',
                      // hintStyle: hintStyle,
                      // labelStyle: labelStyle,
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
          mainButton: CustomButton(
            onPressed: _onResetPasswordTap,
            text: 'Change password',
            loading: _isSubmitting,
            textSize: 14.sp,
          ),
          bottomWidgets: [],
        ),
      ),
    );
  }
}
