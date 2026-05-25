import 'package:flutter/painting.dart';

/// Consistent shadow presets used across the entire app.
class AppShadows {
  AppShadows._();

  /// Very subtle shadow for flat surfaces (e.g. chat input bar).
  static final List<BoxShadow> subtle = <BoxShadow>[
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  /// Default card-level shadow.
  static final List<BoxShadow> card = <BoxShadow>[
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Elevated shadow for modals or floating elements.
  static final List<BoxShadow> elevated = <BoxShadow>[
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.10),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}
