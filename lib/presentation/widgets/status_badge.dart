import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';

/// Status badge (pending, approved, rejected) as a small pill.
class StatusBadge extends StatelessWidget {
  final String label;
  final StatusBadgeType type;

  const StatusBadge({
    super.key,
    required this.label,
    this.type = StatusBadgeType.info,
  });

  /// Convenience constructors for common statuses.
  const StatusBadge.pending({super.key, this.label = 'Pending'})
    : type = StatusBadgeType.warning;

  const StatusBadge.approved({super.key, this.label = 'Approved'})
    : type = StatusBadgeType.success;

  const StatusBadge.rejected({super.key, this.label = 'Rejected'})
    : type = StatusBadgeType.error;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (type) {
      StatusBadgeType.success => (AppColors.successTint, AppColors.success),
      StatusBadgeType.warning => (AppColors.warningTint, AppColors.warning),
      StatusBadgeType.error => (AppColors.errorTint, AppColors.error),
      StatusBadgeType.info => (AppColors.infoTint, AppColors.primary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.pillAll),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

enum StatusBadgeType { success, warning, error, info }
