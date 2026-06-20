import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../theme/app_tokens.dart';
import '../shell/main_shell.dart';

/// Onboarding loader — "building your first daily brief" — then enters the app.
class BuildingBriefScreen extends StatefulWidget {
  static const String routeName = '/onboarding/building';

  const BuildingBriefScreen({super.key});

  @override
  State<BuildingBriefScreen> createState() => _BuildingBriefScreenState();
}

class _BuildingBriefScreenState extends State<BuildingBriefScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave;

  @override
  void initState() {
    super.initState();
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    // Enter the app once the (simulated) brief is ready.
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) Get.offAllNamed(MainShell.routeName);
    });
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 64,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    for (int i = 0; i < 4; i++)
                      AnimatedBuilder(
                        animation: _wave,
                        builder: (_, _) {
                          final phase = (_wave.value + i * 0.2) % 1.0;
                          final h = 18 + 34 * math.sin(phase * math.pi).abs();
                          return Container(
                            width: 7,
                            height: h,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: DornaColors.accentCyan,
                              borderRadius:
                                  BorderRadius.circular(DornaRadii.full),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text('Building your first daily brief…',
                  textAlign: TextAlign.center, style: tt.headlineMedium),
              const SizedBox(height: 8),
              Text(
                "Looking at your day, the weather, and what's worth talking about.",
                textAlign: TextAlign.center,
                style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 28),
              ClipRRect(
                borderRadius: BorderRadius.circular(DornaRadii.full),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 2800),
                  builder: (context, value, _) => Stack(
                    children: [
                      Container(height: 6, width: 220, color: cs.surfaceContainerHighest),
                      Container(
                        height: 6,
                        width: 220 * value,
                        decoration:
                            const BoxDecoration(gradient: DornaColors.brandGradient),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
