import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:dorna/utils/utils.dart';
import 'package:dorna/widgets/ui/toast.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../controllers/auth/auth_controller.dart';
import '../screens/auth/auth_screen.dart';

class DeepLinkService {
  StreamSubscription? deepLinkStream;
  final appLinks = AppLinks(); // AppLinks is singleton

  //Singleton
  static final DeepLinkService _instance = DeepLinkService._internal();

  factory DeepLinkService() => _instance;

  DeepLinkService._internal();

  Future<void> initUniLinks() async {
    var initialLink = await appLinks.getInitialLink();
    if (initialLink != null) {
      _handleAuthDeepKink(initialLink);
    }

    deepLinkStream = appLinks.uriLinkStream.listen((Uri? uri) async {
      debugPrint(
          'mylog uriLinkStream=${uri?.toString()} scheme=${uri?.scheme} host=${uri?.host}');
      _handleAuthDeepKink(uri);
      _handleVerificationDeepKink(uri);
    }, onError: (err) {});
  }

  void _handleAuthDeepKink(Uri? uri) {
    if ((uri?.scheme == 'dorna') && (uri?.host == 'openapp')) {
      debugPrint(
          'mylog _handleAuthDeepKink queryParameters=${uri?.queryParameters}');
      if (uri!.queryParameters['isForSignIn'].toString() == 'true') {
        Get.offAllNamed(AuthScreen.routeName);
      }
    }
  }

  void _handleVerificationDeepKink(Uri? uri) async {
    if ((uri?.scheme == 'dorna') && (uri?.host == 'openapp')) {
      debugPrint(
          'mylog _handleVerificationDeepKink queryParameters=${uri?.queryParameters}');
      String? accessToken =
          uri?.queryParameters['access_token']?.tryToString() ?? '';
      String? refreshToken =
          uri?.queryParameters['refresh_token']?.tryToString() ?? '';
      String? errorMessage =
          uri?.queryParameters['error_message']?.tryToString() ?? '';
      if (errorMessage.isNotEmpty) {
        await Future.delayed(const Duration(seconds: 1));
        showCustomToast(errorMessage, Utils.appContext, isError: true);
        return;
      }
      if (accessToken.isNotEmpty || refreshToken.isNotEmpty) {
        AuthController authController = Get.find();
        authController.saveUserTokens(
            accessToken: accessToken, refreshToken: refreshToken);
        authController.getUserData();
        Utils.handleKeyboardPermissionNavigation();
      }
    }
  }

  dispose() {
    deepLinkStream?.cancel();
  }
}
