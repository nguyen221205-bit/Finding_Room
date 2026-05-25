import 'package:flutter/material.dart';

/// Centralized color palette for the entire app.
///
/// Use these constants instead of hardcoded Color values so that
/// adjusting the palette later is a single-file change.
class AppColors {
  AppColors._();

  // ── Brand ───────────────────────────────────────────────────
  static const Color primary = Color(0xFF3B82F6); // Modern Light Blue #3B82F6
  static const Color accent = Color(0xFF60A5FA); // Modern Accent Light Blue #60A5FA

  // ── Semantic ────────────────────────────────────────────────
  static const Color success = Color(0xFF43A047); // Green 600
  static const Color warning = Color(0xFFFFA726); // Orange 400
  static const Color error = Color(0xFFE53935); // Red 600

  // ── Text ────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);

  // ── Surfaces ────────────────────────────────────────────────
  static const Color surface = Colors.white;
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardBackground = Colors.white;

  // ── Dividers / Borders ──────────────────────────────────────
  static const Color divider = Color(0xFFE5E7EB);

  // ── Shimmer / Placeholder ───────────────────────────────────
  static const Color shimmer = Color(0xFFE5E7EB); // grey.shade200 equiv
  static const Color shimmerHighlight = Color(0xFFF3F4F6);

  // ── Status backgrounds (light tints) ────────────────────────
  static const Color successTint = Color(0xFFE8F5E9);
  static const Color warningTint = Color(0xFFFFF8E1);
  static const Color errorTint = Color(0xFFFFEBEE);
  static const Color infoTint = Color(0xFFE3F2FD);
}
