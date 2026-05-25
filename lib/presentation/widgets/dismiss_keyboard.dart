import 'package:flutter/material.dart';

/// Wraps a child widget in a [GestureDetector] that dismisses the
/// keyboard when the user taps outside any focused text field.
///
/// Wrap your Scaffold body (or the entire Scaffold) with this widget
/// for automatic keyboard dismissal.
class DismissKeyboard extends StatelessWidget {
  final Widget child;

  const DismissKeyboard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: child,
    );
  }
}
