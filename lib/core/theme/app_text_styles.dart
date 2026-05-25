import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Reusable text-style helpers that layer on top of the
/// Material [TextTheme] so we keep the M3 defaults while
/// providing quick access to common app-specific combinations.
class AppTextStyles {
  AppTextStyles._();

  // ── Headlines ───────────────────────────────────────────────
  static TextStyle headline(BuildContext context) =>
      Theme.of(context).textTheme.headlineSmall!;

  // ── Titles ──────────────────────────────────────────────────
  static TextStyle titleLarge(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge!;

  static TextStyle titleMedium(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium!;

  static TextStyle titleSmall(BuildContext context) =>
      Theme.of(context).textTheme.titleSmall!;

  // ── Body ────────────────────────────────────────────────────
  static TextStyle body(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium!;

  static TextStyle bodySecondary(BuildContext context) => Theme.of(
    context,
  ).textTheme.bodyMedium!.copyWith(color: AppColors.textSecondary);

  static TextStyle bodySmall(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall!;

  // ── Caption / Label ─────────────────────────────────────────
  static TextStyle caption(BuildContext context) => Theme.of(
    context,
  ).textTheme.bodySmall!.copyWith(color: AppColors.textSecondary);

  static TextStyle label(BuildContext context) =>
      Theme.of(context).textTheme.labelMedium!;

  // ── Specialty ───────────────────────────────────────────────
  static TextStyle price(BuildContext context) =>
      Theme.of(context).textTheme.titleSmall!.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w700,
      );

  static TextStyle priceLarge(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge!.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w800,
      );
}
