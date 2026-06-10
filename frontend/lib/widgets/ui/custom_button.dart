import 'package:dorna/utils/utils.dart';
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final Function onPressed;
  final Widget? buttonWidget;
  final String? text;
  final bool loading;
  final List<Color>? gradientColors;
  double? buttonHeight;
  final double? textSize;
  final bool isEnabled;
  final bool showBackgroundColorAnyway;
  final bool setDefaultHeight;
  final EdgeInsetsGeometry? padding;
  final List<BoxShadow>? boxShadow;
  final BorderRadius? borderRadius;
  final Border? border;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? loadingColor;
  final TextStyle? textStyle;
  final Duration animationDuration;
  final Function()? onLongPress;

  CustomButton({
    super.key,
    required this.onPressed,
    this.buttonWidget,
    this.text,
    this.loading = false,
    this.gradientColors,
    this.buttonHeight,
    this.padding,
    this.isEnabled = true,
    this.setDefaultHeight = true,
    this.showBackgroundColorAnyway = false,
    this.boxShadow,
    this.borderRadius,
    this.border,
    this.backgroundColor,
    this.onLongPress,
    this.textColor,
    this.textSize,
    this.textStyle,
    this.loadingColor,
    this.animationDuration = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    buttonHeight ??= Utils.isTablet() ? 70 : 52;
    var textColorValue = !isEnabled
        ? Colors.white.withOpacity(0.4)
        : (textColor ?? Colors.white);
    return AnimatedContainer(
      width: padding == null ? double.infinity : null,
      height: setDefaultHeight ? buttonHeight : null,
      duration: animationDuration,
      decoration: BoxDecoration(
        borderRadius: borderRadius ??
            BorderRadius.circular(
              12,
            ),
        border: border,
        boxShadow: boxShadow,
        color: showBackgroundColorAnyway
            ? backgroundColor
            : isEnabled
                ? backgroundColor
                : const Color(0xff8B8B66).withOpacity(0.5),
        gradient: (backgroundColor == null && isEnabled)
            ? LinearGradient(
                colors: gradientColors ??
                    [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary,
                    ],
                begin: Alignment.bottomRight,
                end: Alignment.topLeft,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: borderRadius ??
                BorderRadius.circular(
                  12,
                )),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isEnabled
              ? () {
                  onPressed();
                }
              : null,
          onLongPress: onLongPress,
          child: Center(
            child: Padding(
              padding: padding ?? EdgeInsets.zero,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  text == null
                      ? (buttonWidget!)
                      : Text(
                          text.toString(),
                          style: textStyle ??
                              Theme.of(context)
                                  .textTheme
                                  .displayLarge
                                  ?.copyWith(
                                    color: loading
                                        ? textColorValue.withOpacity(0.5)
                                        : textColorValue,
                                      fontSize: textSize ??
                                          (Utils.isSmallDevice(context)
                                            ? 14.sp
                                            : 13.sp),
                                      height: 1,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                  if (loading)
                    Positioned(
                      left: -32,
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                          color: loadingColor ?? Colors.white,
                          strokeWidth: 3,
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
