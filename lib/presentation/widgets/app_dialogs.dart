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
                      backgroundColor: Theme.of(
                        dialogContext,
                      ).colorScheme.error,
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

  /// Show a dialog asking for a rejection reason.
  static Future<String?> showRejectionDialog({
    required BuildContext context,
    required String title,
    required String label,
    required String hint,
    String confirmLabel = 'Từ chối',
    String cancelLabel = 'Hủy',
    bool isDestructive = true,
  }) {
    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return RejectionDialog(
          title: title,
          label: label,
          hint: hint,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          isDestructive: isDestructive,
        );
      },
    );
  }
}

/// A stateful dialog that manages its own TextEditingController lifecycle safely.
class RejectionDialog extends StatefulWidget {
  final String title;
  final String label;
  final String hint;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;

  const RejectionDialog({
    super.key,
    required this.title,
    required this.label,
    required this.hint,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.isDestructive,
  });

  @override
  State<RejectionDialog> createState() => _RejectionDialogState();
}

class _RejectionDialogState extends State<RejectionDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            widget.isDestructive ? Icons.cancel_outlined : Icons.info_outline,
            color: widget.isDestructive ? Colors.red : Colors.blue,
          ),
          const SizedBox(width: 8),
          Text(widget.title),
        ],
      ),
      content: TextField(
        controller: _controller,
        maxLines: 3,
        autofocus: true,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(_controller.text);
          },
          style: widget.isDestructive
              ? FilledButton.styleFrom(backgroundColor: Colors.red)
              : null,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
