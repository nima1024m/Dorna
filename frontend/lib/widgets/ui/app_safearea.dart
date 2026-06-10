import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppSafeArea extends StatelessWidget {
  final Widget child;
  final bool? top;
  final bool? bottom;

  const AppSafeArea({
    super.key,
    required this.child,
    this.top,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        top:
            top ?? (defaultTargetPlatform == TargetPlatform.iOS ? false : true),
        bottom: bottom ??
            (defaultTargetPlatform == TargetPlatform.iOS ? false : true),
        child: child);
  }
}
