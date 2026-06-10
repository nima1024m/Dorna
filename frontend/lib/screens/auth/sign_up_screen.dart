import 'package:dorna/screens/auth/email_verification_screen.dart';
import 'package:dorna/screens/auth/sign_in_screen.dart';
import 'package:dorna/utils/password_validator.dart';
import 'package:dorna/utils/utils.dart';
import 'package:dorna/widgets/auth/auth_skeleton.dart';
import 'package:dorna/widgets/ui/custom_button.dart';
import 'package:dorna/widgets/ui/custom_form_input.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth/auth_controller.dart';
import '../../widgets/auth/auth_divider.dart';
import '../../widgets/auth/auth_footer.dart';
import '../../widgets/auth/auth_header.dart';
import '../../widgets/auth/password_tips.dart';
import '../../widgets/auth/social_button.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  static const routeName = '/sign_up';

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  final GlobalKey<FormState> _formKeyEmail = GlobalKey<FormState>();
  final GlobalKey<FormState> _formKeyPassword = GlobalKey<FormState>();
  final GlobalKey<FormState> _formKeyConfirmPassword = GlobalKey<FormState>();

  bool _isSubmitting = false;
  bool _showPasswordTips = false;
  String? _apiError;
  final AuthController _authController = Get.find<AuthController>();

  bool get _hasMinLength =>
      PasswordValidator.hasMinLength(_passwordController.text);

  bool get _hasNumber => PasswordValidator.hasNumber(_passwordController.text);

  bool get _hasLower => PasswordValidator.hasLower(_passwordController.text);

  bool get _hasUpper => PasswordValidator.hasUpper(_passwordController.text);

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(v.trim())) return 'Email address is not valid';
    // Show API error on confirm password field if it exists and is not email-related
    if (_apiError != null && !_apiError!.toLowerCase().contains('email')) {
      return _apiError;
    }
    return null;
  }

  String? _validatePassword(String? v) {
    return PasswordValidator.validate(v);
  }

  String? _validateConfirmPassword(String? v) {
    if (v == null || v.isEmpty) return 'Please confirm password';
    if (v != _passwordController.text) return "Passwords must match";
    return null;
  }

  Future<void> _onCreateAccount() async {
    // Clear any previous API errors
    setState(() {
      _apiError = null;
    });
    bool validate1 = _formKeyEmail.currentState!.validate();
    bool validate2 = _formKeyPassword.currentState!.validate();
    bool validate3 = _formKeyConfirmPassword.currentState!.validate();
    if (!validate1 || !validate2 || !validate3) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final isSuccessful = await _authController.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (isSuccessful == true) {
        Get.offAndToNamed(
          EmailVerificationScreen.routeName,
          arguments: {'email': _emailController.text.trim()},
        );
      } else if (isSuccessful == false) {
        setState(() {
          _apiError = 'Failed to create account. Please try again.';
        });
        _formKeyEmail.currentState!.validate();
        _formKeyPassword.currentState!.validate();
        _formKeyConfirmPassword.currentState!.validate();
        Future.delayed(const Duration(milliseconds: 500)).then((v) {
          _apiError = null;
        });
      }
    } catch (e) {
      String errorMessage = 'Account creation failed. Please try again.';
      if (e.getDioError()?.response?.statusCode == 409) {
        errorMessage = 'This account already exists. Try signing in';
      }
      setState(() {
        _apiError = errorMessage;
      });
      _formKeyEmail.currentState!.validate();
      _formKeyPassword.currentState!.validate();
      _formKeyConfirmPassword.currentState!.validate();
      Future.delayed(const Duration(milliseconds: 500)).then((v) {
        _apiError = null;
      });
    } finally {
      setState(() => _isSubmitting = false);
    }
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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
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
          topWidgets: [
            const AuthHeader(
              title: 'Sign up',
              subtitle: 'Welcome to Dorna!',
              description:
                  'To fully experience our features\nplease create an account.',
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
              nextFocusNode: _passwordFocus,
            ),
            const SizedBox(height: 48),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomFormInput(
                      title: 'Password',
                      hintText: 'Enter a password',
                      controller: _passwordController,
                      isSecureText: true,
                      validator: (v) => _validatePassword(v as String?),
                      formKey: _formKeyPassword,
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
                            hasText: _passwordController.text.isNotEmpty,
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
          bottomWidgets: [
            const AuthDivider(text: 'or sign up with'),
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
              questionText: 'Already have an account? ',
              actionText: 'Sign in',
              onTap: () => Get.offNamed(SignInScreen.routeName),
            ),
          ],
          mainButton: CustomButton(
            onPressed: _onCreateAccount,
            text: 'Create account',
            loading: _isSubmitting,
            textSize: 14.sp,
          ),
          isKeyboardOpen: isKeyboardOpen,
        ),
      ),
    );
  }
}
