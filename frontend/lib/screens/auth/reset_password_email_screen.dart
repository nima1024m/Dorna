import 'package:dorna/screens/auth/reset_password_otp_screen.dart';
import 'package:dorna/utils/utils.dart';
import 'package:dorna/widgets/auth/auth_header.dart';
import 'package:dorna/widgets/auth/auth_skeleton.dart';
import 'package:dorna/widgets/ui/custom_button.dart';
import 'package:dorna/widgets/ui/custom_form_input.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth/auth_controller.dart';
import '../../widgets/ui/toast.dart';

class ResetPasswordEmailScreen extends StatefulWidget {
  const ResetPasswordEmailScreen({super.key});

  static const routeName = '/reset_password_email_screen';

  @override
  State<ResetPasswordEmailScreen> createState() =>
      _ResetPasswordEmailScreenState();
}

class _ResetPasswordEmailScreenState extends State<ResetPasswordEmailScreen> {
  final TextEditingController _emailController = TextEditingController();

  final FocusNode _emailFocus = FocusNode();

  final GlobalKey<FormState> _formKeyEmail = GlobalKey<FormState>();

  bool _isSubmitting = false;
  String? _apiError;
  final AuthController _authController = Get.find<AuthController>();

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(v.trim())) return 'Enter a valid email';
    if (_apiError != null) return _apiError;
    return null;
  }

  Future<void> _onContinueTap() async {
    setState(() {
      _apiError = null;
    });

    if (!_formKeyEmail.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final ok = await _authController.forgotPassword(
        email: _emailController.text.trim(),
      );

      if (ok == true) {
        Get.toNamed(
          ResetPasswordOtpScreen.routeName,
          arguments: {
            'email': _emailController.text.trim(),
          },
        );
      } else if (ok == false) {
        setState(() {
          _apiError = 'Failed to send email. Please try again.';
        });
        _formKeyEmail.currentState!.validate();
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
      _formKeyEmail.currentState!.validate();
      Future.delayed(const Duration(milliseconds: 500)).then((v) {
        _apiError = null;
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Utils.appContext = context;
    return Scaffold(
      body: SafeArea(
        child: AuthSkeleton(
          isScrollOnOpenKeybpard: false,
          parentContext: context,
          topWidgets: [
              const AuthHeader(
                title: 'Reset password',
                subtitle: 'We need to verify it\'s you:',
                description:
                    'Please enter your email address and we will sent you a link to reset your password.',
              ),
              const SizedBox(height: 32),
              CustomFormInput(
                title: 'Email address',
                hintText: 'Enter your email address',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => _validateEmail(v as String?),
              formKey: _formKeyEmail,
              inputFocusNode: _emailFocus,
              ),
            ],
            bottomWidgets: [],
            mainButton: CustomButton(
              onPressed: _onContinueTap,
              text: 'Continue',
              loading: _isSubmitting,
              textSize: 14.sp,
            ),
          isKeyboardOpen: false,
        ),
      ),
    );
  }
}
