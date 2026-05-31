import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../domain/entities/app_enums.dart';
import '../../../domain/entities/room_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../providers/room_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/app_snackbar.dart';
import '../../providers/appointment_provider.dart';

class LandlordDetailScreen extends StatefulWidget {
  final UserEntity landlord;

  const LandlordDetailScreen({super.key, required this.landlord});

  @override
  State<LandlordDetailScreen> createState() => _LandlordDetailScreenState();
}

class _LandlordDetailScreenState extends State<LandlordDetailScreen> {
  Future<void> _handleHideRoom(RoomEntity room) async {
    final String? reason = await AppDialogs.showRejectionDialog(
      context: context,
      title: 'Ẩn phòng vi phạm',
      label: 'Lý do ẩn phòng',
      hint: 'Nhập lý do ẩn phòng trọ này khỏi hệ thống...',
      confirmLabel: 'Ẩn phòng',
    );

    if (reason == null || reason.trim().isEmpty || !mounted) return;

    try {
      final roomProvider = context.read<RoomProvider>();
      final appointmentProvider = context.read<AppointmentProvider>();
      final notificationProvider = context.read<NotificationProvider>();
      final bool success = await roomProvider.hideRoomByAdmin(
        roomId: room.id,
        reason: reason,
      );

      if (success && mounted) {
        // Hủy tất cả lịch hẹn đang mở của phòng này
        final cancelledApts = await appointmentProvider
            .cancelAppointmentsForRoomByAdmin(room.id);

        // Tạo thông báo cho chủ nhà
        await notificationProvider.createNotification(
          userId: widget.landlord.id,
          title: 'Phòng trọ đã bị ẩn bởi Admin',
          content: 'Tin đăng "${room.title}" của bạn đã bị ẩn. Lý do: $reason',
          type: NotificationType.roomHiddenByAdmin,
          relatedId: room.id,
        );

        // Tạo thông báo cho các khách thuê bị ảnh hưởng
        for (final apt in cancelledApts) {
          final String dateStr =
              '${apt.appointmentTime.day}/${apt.appointmentTime.month}/${apt.appointmentTime.year} ${apt.appointmentTime.hour.toString().padLeft(2, '0')}:${apt.appointmentTime.minute.toString().padLeft(2, '0')}';
          await notificationProvider.createNotification(
            userId: apt.tenantId,
            title: 'Lịch xem phòng bị hủy',
            content:
                'Lịch hẹn xem phòng "${room.title}" vào lúc $dateStr đã bị quản trị viên hủy do tin đăng này vi phạm quy định và bị ẩn.',
            type: NotificationType.appointmentCancelledByAdmin,
            relatedId: apt.id,
          );
        }

        if (!mounted) return;
        AppSnackbar.success(context, 'Đã ẩn phòng "${room.title}" thành công.');
      } else if (mounted) {
        AppSnackbar.error(context, 'Ẩn phòng thất bại.');
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.error(context, 'Đã xảy ra lỗi khi ẩn phòng.');
      }
    }
  }

  Future<void> _handleRestoreRoom(RoomEntity room) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Khôi phục phòng trọ'),
        content: Text(
          'Bạn có chắc chắn muốn khôi phục phòng trọ "${room.title}" hoạt động bình thường trở lại không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Khôi phục'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final roomProvider = context.read<RoomProvider>();
      final notificationProvider = context.read<NotificationProvider>();
      final bool success = await roomProvider.restoreRoomByAdmin(
        roomId: room.id,
      );

      if (success && mounted) {
        // Create Notification
        await notificationProvider.createNotification(
          userId: widget.landlord.id,
          title: 'Tin đăng đã được khôi phục',
          content:
              'Tin đăng "${room.title}" của bạn đã được quản trị viên khôi phục.',
          type: NotificationType.roomApproved,
          relatedId: room.id,
        );

        if (!mounted) return;
        AppSnackbar.success(
          context,
          'Đã khôi phục phòng "${room.title}" thành công.',
        );
      } else if (mounted) {
        AppSnackbar.error(context, 'Khôi phục phòng thất bại.');
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.error(context, 'Đã xảy ra lỗi khi khôi phục phòng.');
      }
    }
  }

  String _formatPrice(int price) {
    if (price <= 0) return 'Thỏa thuận';
    return '${(price / 1000000).toStringAsFixed(1).replaceAll('.0', '')} triệu/tháng';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roomProvider = context.watch<RoomProvider>();

    final landlordRooms = roomProvider.roomsForOwner(widget.landlord.id);
    final int totalRooms = landlordRooms.length;
    final int activeRooms = landlordRooms
        .where((r) => r.status == RoomStatus.approved)
        .length;
    final int pendingRooms = landlordRooms
        .where((r) => r.status == RoomStatus.pending)
        .length;
    final int hiddenOrRejectedRooms = landlordRooms
        .where(
          (r) =>
              r.status == RoomStatus.rejected ||
              r.status == RoomStatus.hiddenByAdmin,
        )
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết chủ nhà'),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Landlord Header card
            Padding(
              padding: AppSpacing.paddingAllLg,
              child: Card(
                elevation: 0,
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Padding(
                  padding: AppSpacing.paddingAllLg,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: theme.colorScheme.primary,
                        backgroundImage: () {
                          final String? path = widget.landlord.avatarPath;
                          if (path == null || path.isEmpty) return null;
                          if (path.startsWith('http')) {
                            return NetworkImage(path) as ImageProvider;
                          }
                          if (path.startsWith('assets/')) {
                            return AssetImage(path) as ImageProvider;
                          }
                          return FileImage(File(path)) as ImageProvider;
                        }(),
                        child:
                            widget.landlord.avatarPath == null ||
                                widget.landlord.avatarPath!.isEmpty
                            ? Text(
                                widget.landlord.username.isNotEmpty
                                    ? widget.landlord.username[0].toUpperCase()
                                    : 'L',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 20,
                                ),
                              )
                            : null,
                      ),
                      AppSpacing.hMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.landlord.username,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.landlord.email,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                            if (widget.landlord.phoneNumber != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'SĐT: ${widget.landlord.phoneNumber}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Statistics Grid Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context: context,
                      label: 'Tổng phòng',
                      count: totalRooms,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      context: context,
                      label: 'Hoạt động',
                      count: activeRooms,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      context: context,
                      label: 'Chờ duyệt',
                      count: pendingRooms,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      context: context,
                      label: 'Đã ẩn/Từ chối',
                      count: hiddenOrRejectedRooms,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Danh sách phòng đăng',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Room list
            Expanded(
              child: landlordRooms.isEmpty
                  ? const EmptyState(
                      icon: Icons.home_outlined,
                      title: 'Không có phòng nào',
                      message:
                          'Chủ nhà này chưa đăng tải phòng trọ nào lên hệ thống.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 24,
                      ),
                      itemCount: landlordRooms.length,
                      separatorBuilder: (_, _) => AppSpacing.vMd,
                      itemBuilder: (context, index) {
                        final room = landlordRooms[index];
                        final StatusBadge badge = switch (room.status) {
                          RoomStatus.pending => const StatusBadge.pending(
                            label: 'Chờ duyệt',
                          ),
                          RoomStatus.approved => const StatusBadge.approved(
                            label: 'Đã duyệt',
                          ),
                          RoomStatus.rejected => const StatusBadge.rejected(
                            label: 'Từ chối',
                          ),
                          RoomStatus.hiddenByAdmin =>
                            const StatusBadge.rejected(
                              label: 'Đã ẩn bởi Admin',
                            ),
                        };

                        final bool isHidable =
                            room.status == RoomStatus.approved ||
                            room.status == RoomStatus.pending;

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: theme.dividerColor),
                          ),
                          child: Padding(
                            padding: AppSpacing.paddingAllLg,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        room.title,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    badge,
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  room.address,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.hintColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatPrice(room.price),
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (isHidable)
                                      ElevatedButton.icon(
                                        onPressed: () => _handleHideRoom(room),
                                        icon: const Icon(
                                          Icons.visibility_off_outlined,
                                          size: 16,
                                        ),
                                        label: const Text('Ẩn phòng'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              theme.colorScheme.errorContainer,
                                          foregroundColor: theme
                                              .colorScheme
                                              .onErrorContainer,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (room.status == RoomStatus.hiddenByAdmin)
                                      ElevatedButton.icon(
                                        onPressed: () =>
                                            _handleRestoreRoom(room),
                                        icon: const Icon(
                                          Icons.restore_outlined,
                                          size: 16,
                                        ),
                                        label: const Text('Khôi phục phòng'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.success
                                              .withValues(alpha: 0.2),
                                          foregroundColor: AppColors.success,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (room.rejectionReason != null &&
                                    room.rejectionReason!.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.errorContainer
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: theme.colorScheme.error
                                            .withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: Text(
                                      'Lý do: ${room.rejectionReason}',
                                      style: TextStyle(
                                        color: theme.colorScheme.error,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String label,
    required int count,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
