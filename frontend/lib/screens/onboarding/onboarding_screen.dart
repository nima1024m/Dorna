import 'package:dorna/utils/utils.dart';
import 'package:dorna/widgets/ui/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth/auth_controller.dart';
import '../../controllers/settings/settings_controller.dart';
import '../../widgets/ui/custom_button.dart';
import '../auth/auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  static const String routeName = '/onboarding';

  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final SettingsController settingsController = Get.find();
  final AuthController authController = Get.find();
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<_OnboardData> _pages = const [
    _OnboardData(
      title: 'Write Clearly,\nEvery Time',
      descriptionBold:
          'We catch grammar and spelling mistakes before they catch you!',
      descriptionBody:
          'Whether it’s an email, assignment or a message, with Dorna your words always sound right the first time.',
      imageAsset: 'assets/images/onboarding_1.png',
      imageAssetDark: 'assets/images/onboarding_1_dark.png',
      primaryButtonText: 'Next',
    ),
    _OnboardData(
      title: 'Find the Right\nTone',
      descriptionBold:
          'Just pick your tone, we adjust the tone to fit the moment perfectly.',
      descriptionBody:
          'Sound professional in job applications or approachable in chats with Dorna.',
      imageAsset: 'assets/images/onboarding_2.png',
      imageAssetDark: 'assets/images/onboarding_2_dark.png',
      primaryButtonText: 'Next',
    ),
    _OnboardData(
      title: 'Bridge Languages\nInstantly',
      descriptionBold:
          'Study, work or make friends with confidence across cultures.',
      descriptionBody:
          'Switch smoothly between English and Persian without breaking your flow with Dorna’s translator.',
      imageAsset: 'assets/images/onboarding_3.png',
      imageAssetDark: 'assets/images/onboarding_3_dark.png',
      primaryButtonText: 'Get Started',
    ),
  ];

  void _onNext() {
    if (_currentIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _onSkip();
    }
  }

  void _onSkip() async {
    settingsController.setIsOnboardingCompleted(true);
    if (!await authController.isLoggedIn()) {
      if (settingsController.isLoginSkipped.value) {
        await Utils.handleKeyboardPermissionNavigation();
      } else {
        Get.offAllNamed(
          AuthScreen.routeName,
        );
      }
    } else {
      Utils.handleKeyboardPermissionNavigation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var padding = const EdgeInsets.symmetric(horizontal: 48);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: Utils.isSmallDevice(context) ? 48 : 56),
            Padding(
              padding: padding,
              child: _ProgressHeader(
                  currentIndex: _currentIndex,
                  total: _pages.length,
                  onPageTap: (i) => _pageController.animateToPage(i,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemBuilder: (context, index) {
                  final data = _pages[index];
                  return _OnboardingPage(data: data);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 64),
              child: Column(
                children: [
                  CustomButton(
                    onPressed: _onNext,
                    text: _pages[_currentIndex].primaryButtonText,
                  ),
                  const SizedBox(height: 12),
                  Visibility(
                    visible: _currentIndex != _pages.length - 1,
                    maintainSize: true,
                    maintainState: true,
                    maintainAnimation: true,
                    child: TextButton(
                      onPressed: _onSkip,
                      child: Text(
                        'Skip',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color:
                              theme.colorScheme.onBackground.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool isDarkTheme = theme.brightness == Brightness.dark;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              data.title,
              style: theme.textTheme.displayLarge?.copyWith(
                color: AppColors.textMain(),
                fontSize: 26.sp,
                height: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Image
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal:
                      data.imageAsset.toString().contains('onboarding_1')
                          ? 24
                          : 48),
              child: Image.asset(
                isDarkTheme ? data.imageAssetDark : data.imageAsset,
                height: 40.h,
                width: MediaQuery.of(context).size.width,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 64),
            child: Text(
              data.descriptionBold,
              style: theme.textTheme.displayLarge?.copyWith(
                  color: AppColors.textMain(), height: 1.35, fontSize: 15.sp),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 64),
            child: Text(
              data.descriptionBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMain(), height: 1.35, fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final int currentIndex;
  final int total;
  final Function(int) onPageTap;

  const _ProgressHeader(
      {required this.currentIndex,
      required this.total,
      required this.onPageTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: List.generate(total, (i) {
        final active = i == currentIndex;
        return Expanded(
          child: GestureDetector(
            onTap: () => onPageTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: EdgeInsets.only(right: i == total - 1 ? 0 : 8),
              height: 5,
              decoration: BoxDecoration(
                color: active
                    ? AppColors.primaryColor()
                    : AppColors.primaryColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _OnboardData {
  final String title;
  final String descriptionBold;
  final String descriptionBody;
  final String imageAsset;
  final String imageAssetDark;
  final String primaryButtonText;

  const _OnboardData({
    required this.title,
    required this.descriptionBold,
    required this.descriptionBody,
    required this.imageAsset,
    required this.imageAssetDark,
    required this.primaryButtonText,
  });
}
