import 'package:dorna/utils/utils.dart';
import 'package:flutter/material.dart';

import '../ui/back_header.dart';

class AuthSkeleton extends StatelessWidget {
  final List<Widget> topWidgets;
  final List<Widget> bottomWidgets;
  final Widget mainButton;
  final bool isKeyboardOpen;
  final double topSpace;
  final bool isScrollOnOpenKeybpard;
  final String? backTitle;
  final BuildContext? parentContext;
  static double? normalHeight;

  const AuthSkeleton({
    Key? key,
    required this.topWidgets,
    required this.bottomWidgets,
    required this.mainButton,
    required this.isKeyboardOpen,
    this.topSpace = 48,
    this.isScrollOnOpenKeybpard = true,
    this.backTitle,
    this.parentContext,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isSmallDevice = Utils.isSmallDevice(context);

    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      if (!isKeyboardOpen && AuthSkeleton.normalHeight == null) {
        AuthSkeleton.normalHeight = constraints.maxHeight;
      }
      if (!isScrollOnOpenKeybpard) {
        return buildBody(isSmallDevice);
      }
      return SingleChildScrollView(
        reverse: true,
        physics: const NeverScrollableScrollPhysics(),
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          padding: isScrollOnOpenKeybpard
              ? EdgeInsets.only(
                  bottom:
                      MediaQuery.viewInsetsOf(parentContext ?? context).bottom /
                          (2.5))
              : EdgeInsets.zero,
          child: SizedBox(
            height: AuthSkeleton.normalHeight,
            child: buildBody(isSmallDevice),
          ),
        ),
      );
    });
  }

  Column buildBody(bool isSmallDevice) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: BackHeader(
            title: backTitle,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: isSmallDevice ? 0 : 8,
                ),
                Expanded(
                  child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints c) {
                    var remainHeight = c.maxHeight;
                    var bottomInset =
                        MediaQuery.viewInsetsOf(parentContext ?? context)
                            .bottom;
                    int flexValue = isScrollOnOpenKeybpard
                        ? 100
                        : (100 - bottomInset).clamp(0, 100).toInt();
                    return Column(
                      children: [
                        SizedBox(
                            height: remainHeight * (0.6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: topWidgets,
                            )),
                        const Spacer(
                          flex: 100,
                        ),
                        mainButton,
                        Expanded(
                            flex: flexValue, child: const SizedBox.shrink()),
                        SizedBox(
                          height: bottomWidgets.any((e) => e is Spacer) ||
                                  bottomWidgets.isEmpty
                              ? (remainHeight * (isSmallDevice ? 0.18 : 0.18))
                              : null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: bottomWidgets,
                          ),
                        ),
                        Expanded(
                            flex: flexValue, child: const SizedBox.shrink()),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
