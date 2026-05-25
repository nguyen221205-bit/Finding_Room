import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';

/// Helper to show consistent SnackBars across the app.
class AppSnackbar {
  AppSnackbar._();

  /// Show a standard informational snackbar.
  static void show(BuildContext context, String message) {
    showWithMessenger(ScaffoldMessenger.of(context), message);
  }

  static void showWithMessenger(ScaffoldMessengerState messenger, String message) {
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Show a success snackbar with a green tint.
  static void success(BuildContext context, String message) {
    successWithMessenger(ScaffoldMessenger.of(context), message);
  }

  static void successWithMessenger(ScaffoldMessengerState messenger, String message) {
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.success,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mediumAll),
        ),
      );
  }

  /// Show an error snackbar with a red tint.
  static void error(BuildContext context, String message) {
    errorWithMessenger(ScaffoldMessenger.of(context), message);
  }

  static void errorWithMessenger(ScaffoldMessengerState messenger, String message) {
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mediumAll),
        ),
      );
  }
}
