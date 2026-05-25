import 'package:flutter/widgets.dart';

/// Consistent border radius tokens used across the entire app.
class AppRadius {
  AppRadius._();

  // ── Raw values ──────────────────────────────────────────────
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double pill = 99;

  // ── BorderRadius shortcuts ──────────────────────────────────
  static final BorderRadius smallAll = BorderRadius.circular(small);
  static final BorderRadius mediumAll = BorderRadius.circular(medium);
  static final BorderRadius largeAll = BorderRadius.circular(large);
  static final BorderRadius pillAll = BorderRadius.circular(pill);
}
