import 'package:dorna/screens/auth/sign_in_screen.dart';
import 'package:dorna/screens/auth/sign_up_screen.dart';
import 'package:dorna/theme/app_tokens.dart';
import 'package:dorna/widgets/ui/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/settings/settings_controller.dart';
import '../../utils/utils.dart';
import '../../widgets/ui/custom_underline_text.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  static const routeName = '/auth_screen';

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final SettingsController settingsController = Get.find();

  void onSkipTap() {
    settingsController.setIsLoginSkipped(true);
    Utils.handleKeyboardPermissionNavigation();
  }

  onSignUpTap() {
    Get.toNamed(
      SignUpScreen.routeName,
    );
  }

  onSignInTap() {
    Get.toNamed(
      SignInScreen.routeName,
    );
  }

  void onLearnMoreTap() {
    launchUrl(Uri.parse('https://thedorna.com/'),
        mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    Utils.appContext = context;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 48, right: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const SizedBox(
                height: 48,
              ),
              Hero(
                tag: 'logo',
                placeholderBuilder: (
                  BuildContext context,
                  Size heroSize,
                  Widget child,
                ) {
                  return const SizedBox();
                },
                child: Image.asset(
                  'assets/images/logo.png',
                  width: Utils.isSmallDevice(context) ? 150 : 180,
                  color: cs.primary,
                ),
              ),
              SizedBox(
                height: Utils.isSmallDevice(context) ? 24 : 32,
              ),
              Hero(
                tag: 'Dorna',
                child: Text(
                  'Dorna',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: cs.primary,
                        fontSize: 45.sp,
                      fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Hero(
                        tag: 'Your Writing Assistant',
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              DornaColors.primary,
                              DornaColors.accentCyan
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ).createShader(
                              Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                          child: Text(
                            'Your Writing Assistant',
                            style: Theme.of(context)
                                .textTheme
                                .displayLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontSize: 23.sp,
                                    fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: Utils.isSmallDevice(context) ? 60 : 80,
              ),
              CustomButton(
                onPressed: onSignUpTap,
                text: 'Create account',
              ),
              const SizedBox(
                height: 16,
              ),
              CustomButton(
                onPressed: onSignInTap,
                text: 'Sign in',
                backgroundColor: cs.primary.withOpacity(0.1),
                textColor: cs.primary,
              ),
              const SizedBox(
                height: 16,
              ),
              Center(
                child: TextButton(
                  onPressed: onSkipTap,
                  child: Text(
                    'Skip for now',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface.withOpacity(0.4),
                          fontSize: 12.sp,
                        ),
                  ),
                ),
              ),
              const Spacer(),
              Center(
                child: GestureDetector(
                  onTap: onLearnMoreTap,
                  child: CustomUnderlineText(
                    'Learn more about Dorna keyboard',
                    isBoldLine: true,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 12.sp,
                        ),
                  ),
                ),
              ),
              const SizedBox(
                height: 48,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
