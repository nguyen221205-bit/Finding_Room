import 'package:flutter/material.dart';

/// Reusable confirmation dialogs for destructive actions.
class AppDialogs {
  AppDialogs._();

  /// Show a generic confirmation dialog.
  ///
  /// Returns `true` if the user confirmed, `false` or `null` otherwise.
  static Future<bool> confirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: isDestructive
                  ? FilledButton.styleFrom(
                      backgroundColor:
                          Theme.of(dialogContext).colorScheme.error,
                    )
                  : null,
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  /// Convenience: confirm logout.
  static Future<bool> confirmLogout(BuildContext context) {
    return confirm(
      context: context,
      title: 'Logout',
      message: 'Are you sure you want to log out?',
      confirmLabel: 'Logout',
      isDestructive: true,
    );
  }

  /// Convenience: confirm discard unsaved changes.
  static Future<bool> confirmDiscard(BuildContext context) {
    return confirm(
      context: context,
      title: 'Discard changes?',
      message:
          'You have unsaved changes. Are you sure you want to leave this page?',
      confirmLabel: 'Discard',
      isDestructive: true,
    );
  }

  /// Convenience: confirm approve action.
  static Future<bool> confirmApprove(BuildContext context, String itemName) {
    return confirm(
      context: context,
      title: 'Approve $itemName',
      message: 'Are you sure you want to approve this $itemName?',
      confirmLabel: 'Approve',
    );
  }
}
