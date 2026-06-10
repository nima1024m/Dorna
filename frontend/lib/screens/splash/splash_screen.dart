import 'package:dio/dio.dart';
import 'package:dorna/screens/auth/auth_screen.dart';
import 'package:dorna/screens/onboarding/onboarding_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth/auth_controller.dart';
import '../../controllers/settings/settings_controller.dart';
import '../../utils/local_platform_storage.dart';
import '../../utils/utils.dart';
import '../../widgets/ui/toast.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const routeName = kIsWeb ? '/' : '/splash';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _authController = Get.find<AuthController>();
  final _settingsController = Get.find<SettingsController>();

  final duration = const Duration(
    seconds: 2,
  );

  Future<void> init() async {
    try {
      const LocalPlatformStorage storage = LocalPlatformStorage();
      var containsUserKey = await storage.containsKey(
        key: 'user',
      );
      await Future.delayed(
        duration,
      );
      if (!containsUserKey) {
        navigateToLogin();
        return;
      } else {
        await _authController.getStoredUser();

        try {
          var containsTokenKey = await storage.containsKey(
            key: 'access_token',
          );

          if (containsTokenKey) {
            _authController.getUserData();

            navigateToNext();
          }
        } on DioException catch (e) {
          if (e.response == null) {
            showNetworkToast(e: e, context: context);
            return;
          }
          if (e.response?.statusCode == 403 || e.response?.statusCode == 401) {
            navigateToLogin();
          } else {
            showNetworkToast(e: e, context: context);
          }
        }
        // }
      }
    } catch (e) {
      showCustomToast('Error ${e.toString()}', context, isError: true);
    }
  }

  navigateToNext() async {
    if (!_settingsController.isOnboardingCompleted.value) {
      Get.offAllNamed(
        OnboardingScreen.routeName,
      );
    } else if (!_settingsController.isCollectDataSeen.value) {
      await Utils.handleKeyboardPermissionNavigation();
    } else {
      Get.offAllNamed(
        HomeScreen.routeName,
      );
    }
  }

  void navigateToLogin() async {
    if (!_settingsController.isOnboardingCompleted.value) {
      Get.offAllNamed(
        OnboardingScreen.routeName,
      );
    } else if (_settingsController.isLoginSkipped.value) {
      await Utils.handleKeyboardPermissionNavigation();
    } else {
      Get.offAllNamed(
        AuthScreen.routeName,
      );
    }
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Utils.appContext = context;
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Image.asset(
              isDarkMode
                  ? 'assets/images/splash_dark.png'
                  : 'assets/images/splash_light.png',
              width: MediaQuery.sizeOf(context).width,
              height: MediaQuery.sizeOf(context).height,
              fit: BoxFit.cover,
            ),
            SafeArea(
              child: Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 200,
                  color: isDarkMode ? const Color(0xff1C75BC) : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
