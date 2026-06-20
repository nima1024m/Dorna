import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:dorna/controllers/settings/settings_controller.dart';
import 'package:dorna/screens/instruction/instruction_collect_data_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:persian_number_utility/persian_number_utility.dart';
import 'package:sizer/sizer.dart';

import '../screens/instruction/instruction_first_screen.dart';
import '../screens/shell/main_shell.dart';
import '../screens/instruction/instruction_second_screen.dart';
import '../services/keyboard_service.dart';

extension SizerExt on num {
  /// Calculates the height depending on the device's screen size
  ///
  /// Eg: 20.h -> will take 20% of the screen's height
  double get h => this * Device.height / 100;

  /// Calculates the width depending on the device's screen size
  ///
  /// Eg: 20.w -> will take 20% of the screen's width
  double get w => this * Device.width / 100;

  /// Calculates the sp (Scalable Pixel) depending on the device's screen size
  double get sp =>
      (Utils.isTablet()
          ? (this * (Device.width / 5) / 100)
          : (this * (Device.width / 3) / 100)) -
      (Platform.isIOS ? (1 * (Device.width / 3) / 100) : 0);
}

extension MyParser on String {
  int? tryParseInt() {
    return int.tryParse(this);
  }

  double? tryParseDouble() {
    return double.tryParse(this);
  }

  String? tryToString() {
    return toString() == 'null' ? null : toString();
  }

  String capitalizeFirstChar() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }

  String getPrice() {
    var value = toString()
        .split(' ')
        .first
        .replaceAll('.', '')
        .replaceAll(',', '')
        .toEnglishDigit();
    return int.tryParse(value)?.toString() ?? value;
  }
}

extension MyErrorExtension on Object {
  DioException? getDioError() {
    if (this is DioException) {
      return this as DioException;
    }
    return null;
  }

  String? getDioBackendErrorMessage() {
    if (getDioError()?.response?.data != null) {
      //if error was map
      if (getDioError()?.response?.data['detail'] != null) {
        //if error was list
        debugPrint(
            'mylog runt=${getDioError()?.response?.data['detail'].runtimeType}');
        if (getDioError()?.response?.data['detail'] is List<dynamic>) {
          //return all msg fields in list
          return getDioError()
              ?.response
              ?.data['detail']
              .map((e) => e['msg'] ?? e['message'] ?? '')
              .toList()
              .join('\n');
        }
        return getDioError()?.response?.data['detail']['message'];
      }
    }
    return null;
  }
}

extension MyListExtension on List {
  Iterable getRangePage<T>(int page, {int pageSize = 3}) {
    int end = (page * pageSize) + pageSize;

    end = end > length ? length : end;

    int start = page * pageSize;
    if (start > length) {
      start -= pageSize;
    }

    return getRange(start, end);
  }
}

extension MyDateTimeExtension on DateTime {
  DateTime convertToLocalFromUTc() {
    return (DateTime.tryParse(('${toString()}Z').replaceAll('ZZ', 'Z')) ??
            DateTime.now())
        .toLocal();
  }

  bool isToday() {
    final now = DateTime.now();
    return now.year == year && now.month == month && now.day == day;
  }
}

class Utils {
  static BuildContext? appContext;
  static var otpCallNumber = "98200023540";
  static final verifyMobileNumberRegex = RegExp(r'((0?9)|(\+?989))\d{9}');
  static final nameRegex = RegExp('^[a-zA-Zآ-ی]+\$');
  static final emailRegex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
  static final englishTextRegex =
      RegExp("^[a-zA-Z\\s\\d~`!@#\$%^&*()_\\-+={\\[}\\]|:;'\\\",.<>\\/?]*\$");

  static Future<bool> handleKeyboardPermissionNavigation({
    bool navigateToHomeOnGrantPermission = true,
  }) async {
    final KeyboardService _keyboardService = KeyboardService();
    var isCustomKeyboardEnabled =
        await _keyboardService.isCustomKeyboardEnabled();
    if (!isCustomKeyboardEnabled) {
      Get.offAllNamed(
        InstructionFirstScreen.routeName,
      );
      return false;
    } else {
      var isCustomKeyboardHasFullAccess =
          await _keyboardService.hasFullAccessRuntime();
      if (isCustomKeyboardHasFullAccess) {
        if (navigateToHomeOnGrantPermission) {
          SettingsController settingsController = Get.find();
          if (!settingsController.isKeyboardSelected.value) {
            Get.offAllNamed(
              InstructionSecondScreen.routeName,
            );
            return false;
          } else if (!settingsController.isCollectDataSeen.value) {
            Get.offAllNamed(
              InstructionCollectDataScreen.routeName,
            );
            return false;
          } else {
            Get.offAllNamed(
              MainShell.routeName,
            );
            return true;
          }
        }
        return true;
      } else {
        Get.offAllNamed(
          InstructionFirstScreen.routeName,
        );
        return false;
      }
    }
  }

  static String convertDurationToString(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitHours = twoDigits(duration.inHours.remainder(60));

    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (twoDigitHours == '00') {
      return "$twoDigitMinutes:$twoDigitSeconds".toEnglishDigit();
    }
    return "$twoDigitHours:$twoDigitMinutes:$twoDigitSeconds".toEnglishDigit();
  }

  static String? replaceHttps(String? url) {
    if (url == null) {
      return url;
    }
    if (url.startsWith('http://')) {
      return url.replaceFirst('http://', 'https://');
    }
    return url;
  }

  static bool isEnglish(String text) {
    return englishTextRegex.hasMatch(text);
  }

  static bool isPhoneNumber(String username) {
    return
        // username.length == 11 &&
        verifyMobileNumberRegex.hasMatch(username.toEnglishDigit());
  }

  static bool isTablet() {
    if (kIsWeb) {
      return false;
    }
    final data = MediaQueryData.fromWindow(WidgetsBinding.instance.window);
    return data.size.shortestSide < 600 ? false : true;
  }

  static bool isSmallDevice(context) {
    return MediaQuery.sizeOf(context).height < 850 && !isTablet();
  }

  static RegExp getPasswordRegex() {
    return RegExp("^[a-zA-Z0-9]*\$");
  }

  static bool isOldActivityIcon(String image) {
    return image == 'assets/images/running_button2.png' ||
        image == 'assets/images/athlete_pic.png' ||
        image == 'assets/images/drink_pic.png' ||
        image == 'assets/images/food_pic.png' ||
        image == 'assets/images/swim_pic.png';
  }

  static int getMaxCharactersForLines({
    required String text,
    required TextStyle textStyle,
    required double maxWidth,
    required int maxLines,
    required BuildContext context,
  }) {
    final span = TextSpan(text: text, style: textStyle);

    // Create a TextPainter to measure text dimensions
    final textPainter = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      textScaler: MediaQuery.of(context).textScaler,
    );

    textPainter.layout(maxWidth: maxWidth);

    // Check how much of the text fits in the given constraints
    final result = textPainter
        .getPositionForOffset(ui.Offset(maxWidth, textPainter.height));
    //subtract 5 for padding
    return result.offset;
  }
}
