import 'package:flutter/material.dart';

class AppColors {
  static bool isDarkMode = false;

  static Color primaryColor() => isDarkMode
      ? const Color(0xff1F82D2)
      : const Color(
          0xff1C75BC,
        );

  static Color ascending() => isDarkMode
      ? const Color(0xff05C1E2)
      : const Color(
          0xff05C1E2,
        );
  static var mainBlack = const Color(0xff060606);
  static var subtitle = const Color(0xff1A171B);

  static Color textMain() =>
      isDarkMode ? const Color(0xffC9D4DC) : const Color(0xff232E36);
  static var text1 = const Color(0xff3E3E3F);
  static var text2 = const Color(0xff57585A);
  static var text3 = const Color(0xff76787B);

  static Color greySubtext() =>
      isDarkMode ? const Color(0xffC9D4DC) : const Color(0xff484C4F);
  static var grey1 = const Color(0xff343434);
  static var grey2 = const Color(0xffA8A9AD);
  static var grey3 = const Color(0xff7D7D7D);
  static var grey4 = const Color(0xff808080);
  static var neutral = const Color(0xffD3D3D3);
  static var neutral2 = const Color(0xffEDEDED);
  static var neutral3 = const Color(0xffF2F2F2);
  static var neutral4 = const Color(0xffF9F9F9);
  static var lightBlue = const Color(0xff00FFFF);
  static var lightBlue2 = const Color(0xff01FBFB);
  static var infoText = const Color(0xff039BE5);
  static var blueDark = const Color(0xff285F8E);
  static var warningText = const Color(0xffFF9500);
  static var warningText2 = const Color(0xffFF9500);
  static var errorText = const Color(0xffD80027);
  static var successText = const Color(0xff17BD62);
  static var green1 = const Color(0xff8BC63E);
  static var brand4 = const Color(0xffD12C55);
  static var redDark = const Color(0xff78003C);
  static var purple = const Color(0xff470184);
}
