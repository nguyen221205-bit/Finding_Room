import 'package:flutter/material.dart';

/// Mixin for form screens that need unsaved-change protection.
///
/// Usage:
/// 1. `with UnsavedFormMixin` on your State class
/// 2. Call `markFormDirty()` whenever a field changes
/// 3. Wrap your Scaffold body with `buildUnsavedFormGuard(child: ...)`
mixin UnsavedFormMixin<T extends StatefulWidget> on State<T> {
  bool _isFormDirty = false;

  bool get isFormDirty => _isFormDirty;

  void markFormDirty() {
    if (!_isFormDirty) {
      setState(() => _isFormDirty = true);
    }
  }

  void markFormClean() {
    if (_isFormDirty) {
      setState(() => _isFormDirty = false);
    }
  }

  /// Wraps child in a [PopScope] that intercepts back navigation
  /// and shows a discard-changes dialog when the form is dirty.
  Widget buildUnsavedFormGuard({required Widget child}) {
    return PopScope(
      canPop: !_isFormDirty,
      onPopInvokedWithResult: (bool didPop, _) async {
        if (didPop) return;
        final bool discard = await _confirmDiscard();
        if (discard && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: child,
    );
  }

  Future<bool> _confirmDiscard() async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Discard changes?'),
          content: const Text(
            'You have unsaved changes. Are you sure you want to leave?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Stay'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              child: const Text('Discard'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
