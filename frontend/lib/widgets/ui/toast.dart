import 'package:dio/dio.dart';
import 'package:dorna/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
// import 'package:dorna/share_plus.dart';
import 'package:toastification/toastification.dart';

showCustomToast(
  String message,
  BuildContext? context, {
  Duration? duration,
  bool isError = false,
  bool isNetworkError = false,
  bool isServerError = false,
  bool isSuccess = false,
}) {
  if (context == null) {
    return;
  }
  var color = isError ? const Color(0xffE04B48) : const Color(0xff339E38);
  return toastification.show(
    context: context,
    title: Padding(
      padding: const EdgeInsets.all(4.0),
      child: Row(
        children: [
          if (isNetworkError || isServerError)
            SvgPicture.asset(
              isNetworkError
                  ? 'assets/icons/ic_wifi_lost.svg'
                  : 'assets/icons/ic_heart_break.svg',
              width: 24,
              height: 24,
            )
          else
            SvgPicture.asset(
              isError
                  ? 'assets/icons/ic_error.svg'
                  : 'assets/icons/ic_success.svg',
              width: 24,
              height: 24,
            ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Text(
              message,
              maxLines: 5,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 12.sp,
                  ),
            ),
          ),
        ],
      ),
    ),
    type: ToastificationType.info,
    backgroundColor: const Color(0xff242424).withOpacity(0.9),
    // backgroundColor: isSuccess
    //     ? const Color(
    //         0xffCCEFCE,
    //       )
    //     : isError
    //         ? const Color(0xffF5C3C2)
    //         : const Color(
    //             0xffCCEFCE,
    //           ),
    foregroundColor: color,
    primaryColor: color,
    margin: EdgeInsets.zero,
    style: ToastificationStyle.simple,
    alignment: Alignment.bottomCenter,
    closeButtonShowType: CloseButtonShowType.none,
    progressBarTheme: Theme.of(context).progressIndicatorTheme.copyWith(
          color: color,
          linearTrackColor: color.withOpacity(0.5),
        ),
    borderRadius: BorderRadius.circular(16),
    borderSide: const BorderSide(color: Colors.transparent),
    autoCloseDuration: duration ??
        Duration(
          seconds: isError ? 4 : 3,
        ),
  );
}

bool showNetworkToast({
  required DioException e,
  required BuildContext context,
}) {
  if (e.response?.statusCode == 429 ||
      (((e.response?.statusCode ?? 0) >= 500) &&
          ((e.response?.statusCode ?? 0) < 600))) {
    showCustomToast(
      'Oops! Unfortunately our service is temporarily unavailable. We’re fixing it!',
      context,
      isServerError: true,
    );
    return true;
  }
  if (e.response?.statusCode == null) {
    showCustomToast(
      'Hmm… Looks like you’re offline... Please check your connection.',
      context,
      isNetworkError: true,
    );
    return true;
  }
  return false;
}
