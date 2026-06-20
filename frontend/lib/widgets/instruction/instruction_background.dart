import 'package:flutter/material.dart';

/// Plain themed backdrop for the keyboard-setup flow. The redesign drops the
/// legacy scattered-letters image in favour of the clean surface from the design.
class InstructionBackground extends StatelessWidget {
  final Widget child;

  const InstructionBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 8),
            child: child,
          ),
        ),
      ),
    );
  }
}
