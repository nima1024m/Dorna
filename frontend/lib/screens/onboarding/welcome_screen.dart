import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../theme/app_tokens.dart';
import '../../widgets/ui/custom_button.dart';
import '../auth/sign_in_screen.dart';
import 'interests_screen.dart';

/// Onboarding entry: brand, value prop, and routes into the flow or to sign-in.
class WelcomeScreen extends StatelessWidget {
  static const String routeName = '/welcome';

  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              DornaSpacing.screenMargin, 24, DornaSpacing.screenMargin, 32),
          child: Column(
            children: [
              Image.asset('assets/images/logotype.png',
                  height: 26, color: cs.primary),
              const SizedBox(height: 20),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(DornaRadii.xl),
                      child: Image.asset('assets/images/city_morning.png',
                          fit: BoxFit.cover),
                    ),
                    // Fade the illustration's lower edge into the background.
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 140,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [cs.surface, cs.surface.withValues(alpha: 0)],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Speak with confidence, every day.',
                  textAlign: TextAlign.center, style: tt.headlineLarge),
              const SizedBox(height: 12),
              Text(
                'Dorna learns your day and gives you the right words for real '
                'conversations — at work, at events, and around town.',
                textAlign: TextAlign.center,
                style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 28),
              CustomButton(
                text: 'Get started',
                onPressed: () => Get.toNamed(InterestsScreen.routeName),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Get.toNamed(SignInScreen.routeName),
                child: Text('I already have an account',
                    style: tt.labelLarge?.copyWith(color: cs.primary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
