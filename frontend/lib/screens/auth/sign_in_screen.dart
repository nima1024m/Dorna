import 'package:dorna/screens/auth/reset_password_email_screen.dart';
import 'package:dorna/screens/auth/sign_up_screen.dart';
import 'package:dorna/utils/utils.dart';
import 'package:dorna/widgets/auth/auth_skeleton.dart';
import 'package:dorna/widgets/auth/social_button.dart';
import 'package:dorna/widgets/ui/custom_button.dart';
import 'package:dorna/widgets/ui/custom_form_input.dart';
import 'package:dorna/widgets/ui/toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth/auth_controller.dart';
import '../../widgets/auth/auth_divider.dart';
import '../../widgets/auth/auth_footer.dart';
import '../../widgets/auth/auth_header.dart';
import '../../widgets/ui/custom_underline_text.dart';
import 'email_verification_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  static const routeName = '/sign_in_screen';

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  final GlobalKey<FormState> _formKeyEmail = GlobalKey<FormState>();
  final GlobalKey<FormState> _formKeyPassword = GlobalKey<FormState>();

  bool _isSubmitting = false;
  bool _resetForm = false;
  String? _apiError;
  final AuthController _authController = Get.find<AuthController>();

  String? _validateEmail(String? v) {
    if (_resetForm) {
      return null;
    }
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(v.trim())) return 'Enter a valid email';
    if (_apiError != null) return '';
    return null;
  }

  String? _validatePassword(String? v) {
    if (_resetForm) {
      return null;
    }
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Minimum 8 characters';
    // Show API error on password field if it exists
    if (_apiError != null) return _apiError;
    return null;
  }

  Future<void> _onSignInTap() async {
    // Clear any previous API errors
    setState(() {
      _apiError = null;
    });
    bool validate1 = _formKeyEmail.currentState!.validate();
    bool validate2 = _formKeyPassword.currentState!.validate();

    if (!validate1 || !validate2) return;

    setState(() => _isSubmitting = true);

    try {
      final isSuccessful = await _authController.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (isSuccessful == true) {
        // Show success message
        showCustomToast(
          'Sign in successful!',
          context,
          isSuccess: true,
        );

        // Navigate to email verification or main screen
        await Utils.handleKeyboardPermissionNavigation();
      } else if (isSuccessful == false) {
        setState(() {
          _apiError = 'Sign in failed. Please try again.';
        });
        // Trigger form validation to show error
        _formKeyEmail.currentState!.validate();
        _formKeyPassword.currentState!.validate();
        Future.delayed(const Duration(milliseconds: 500)).then((v) {
          _apiError = null;
        });
      }
    } catch (e) {
      String errorMessage = 'Sign in failed. Please try again.';

      // Handle specific error cases
      if (e.getDioError()?.response?.statusCode == 401) {
        final data = e.getDioError()?.response?.data;
        // Check for inactive account error
        if (data is Map &&
            data['detail'] is Map &&
            data['detail']['code'] == 'inactive_account') {
          // Resend activation email
          await _authController.resendActivation(
              email: _emailController.text.trim());

          // Navigate to verification screen
          Get.toNamed(
            EmailVerificationScreen.routeName,
            arguments: {'email': _emailController.text.trim()},
          );
          return;
        }

        errorMessage = 'Wrong credentials';
      }

      setState(() {
        _apiError = errorMessage;
      });
      // Trigger form validation to show error
      _formKeyEmail.currentState!.validate();
      _formKeyPassword.currentState!.validate();
      Future.delayed(const Duration(milliseconds: 500)).then((v) {
        _apiError = null;
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void onForgotPasswordTap() {
    _emailController.clear();
    _passwordController.clear();
    _apiError = null;
    _resetForm = true;
    _formKeyEmail.currentState!.validate();
    _formKeyPassword.currentState!.validate();
    _resetForm = false;

    Get.toNamed(ResetPasswordEmailScreen.routeName);
  }

  void onSignUpTap() {
    Get.offNamed(SignUpScreen.routeName);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Utils.appContext = context;
    bool isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: AuthSkeleton(
          isKeyboardOpen: isKeyboardOpen,
          topWidgets: [
            const AuthHeader(
              title: 'Sign in',
              subtitle: 'Welcome back!',
              description: 'Sign in with your credentials or social account.',
            ),
            const SizedBox(height: 32),
            CustomFormInput(
              title: 'Email address',
              hintText: 'Enter your email address',
              formKey: _formKeyEmail,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => _validateEmail(v as String?),
              inputFocusNode: _emailFocus,
              nextFocusNode: _passwordFocus,
            ),
            const SizedBox(height: 48),
            CustomFormInput(
              title: 'Password',
              hintText: 'Enter your password',
              formKey: _formKeyPassword,
              controller: _passwordController,
              isSecureText: true,
              validator: (v) => _validatePassword(v as String?),
              inputFocusNode: _passwordFocus,
              onChanged: (_) {
                setState(() {});
              },
            ),
            const SizedBox(height: 24),
            buildForgetPasswordButton(),
          ],
          bottomWidgets: [
            const AuthDivider(text: 'or sign in with'),
            const SizedBox(height: 24),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppleSignInButton(),
                SizedBox(width: 20),
                GoogleSignInButton(),
              ],
            ),
            const SizedBox(height: 24),
            AuthFooter(
              questionText: 'Don\'t have an account? ',
              actionText: 'Sign up',
              onTap: onSignUpTap,
            ),
          ],
          mainButton: CustomButton(
            onPressed: _onSignInTap,
            text: _isSubmitting ? 'Signing in' : 'Sign in',
            loading: _isSubmitting,
            textSize: 14.sp,
          ),
        ),
      ),
    );
  }

  Stack buildForgetPasswordButton() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const SizedBox(
          height: 48,
          width: double.infinity,
        ),
        Positioned(
          left: -8,
          child: TextButton(
              onPressed: onForgotPasswordTap,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.all(8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: CustomUnderlineText(
                'Forgot password?',
                isBoldLine: true,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 12.sp,
                    color: Theme.of(context).colorScheme.primary,
                    ),
              )),
        ),
      ],
    );
  }
}
