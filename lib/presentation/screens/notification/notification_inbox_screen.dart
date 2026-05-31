import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../domain/entities/app_enums.dart';
import '../../../domain/entities/notification_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/empty_state.dart';
import '../appointment/viewing_appointments_screen.dart';

class NotificationInboxScreen extends StatelessWidget {
  const NotificationInboxScreen({super.key});

  String _formatDateTime(DateTime dt) {
    final DateTime local = dt.toLocal();
    final String day = local.day.toString().padLeft(2, '0');
    final String month = local.month.toString().padLeft(2, '0');
    final String year = local.year.toString();
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.verificationApproved:
        return Icons.verified_user_outlined;
      case NotificationType.verificationRejected:
        return Icons.gpp_bad_outlined;
      case NotificationType.roomApproved:
        return Icons.home_outlined;
      case NotificationType.roomRejected:
        return Icons.unpublished_outlined;
      case NotificationType.chatMessage:
        return Icons.chat_bubble_outline;
      case NotificationType.appointmentCreated:
        return Icons.calendar_today_outlined;
      case NotificationType.appointmentApproved:
        return Icons.event_available_outlined;
      case NotificationType.appointmentRejected:
        return Icons.event_busy_outlined;
      case NotificationType.roomHiddenByAdmin:
        return Icons.visibility_off_outlined;
      case NotificationType.landlordPrivilegeRevoked:
        return Icons.gpp_maybe_outlined;
      case NotificationType.appointmentCompleted:
        return Icons.done_all;
      case NotificationType.appointmentCancelledByTenant:
      case NotificationType.appointmentCancelledByLandlord:
      case NotificationType.appointmentCancelledByAdmin:
        return Icons.event_busy_outlined;
    }
  }

  Color _getColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.verificationApproved:
        return AppColors.success;
      case NotificationType.verificationRejected:
        return AppColors.error;
      case NotificationType.roomApproved:
        return AppColors.primary;
      case NotificationType.roomRejected:
        return AppColors.warning;
      case NotificationType.chatMessage:
        return Colors.purple;
      case NotificationType.appointmentCreated:
        return Colors.orange;
      case NotificationType.appointmentApproved:
        return Colors.green;
      case NotificationType.appointmentRejected:
        return Colors.red;
      case NotificationType.roomHiddenByAdmin:
        return Colors.red;
      case NotificationType.landlordPrivilegeRevoked:
        return Colors.redAccent;
      case NotificationType.appointmentCompleted:
        return Colors.blue;
      case NotificationType.appointmentCancelledByTenant:
      case NotificationType.appointmentCancelledByLandlord:
      case NotificationType.appointmentCancelledByAdmin:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String userId = context.watch<AuthProvider>().userId;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: <Widget>[
          Consumer<NotificationProvider>(
            builder: (BuildContext context, NotificationProvider provider, _) {
              if (provider.notifications.isEmpty) {
                return const SizedBox.shrink();
              }
              return PopupMenuButton<String>(
                onSelected: (String value) {
                  if (value == 'markAllRead') {
                    provider.markAllAsRead(userId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã đánh dấu tất cả là đã đọc'),
                      ),
                    );
                  } else if (value == 'archiveAllRead') {
                    provider.archiveAllReadNotifications(userId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã lưu trữ tất cả thông báo đã đọc'),
                      ),
                    );
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'markAllRead',
                    child: Row(
                      children: [
                        Icon(Icons.done_all, size: 20),
                        SizedBox(width: 8),
                        Text('Đánh dấu đã đọc tất cả'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'archiveAllRead',
                    child: Row(
                      children: [
                        Icon(Icons.delete_sweep_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('Lưu trữ các mục đã đọc'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (BuildContext context, NotificationProvider provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final list = provider.notifications;
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_off_outlined,
              title: 'Không có thông báo mới',
              message:
                  'Các thông báo phê duyệt hồ sơ và duyệt phòng sẽ được hiển thị ở đây.',
            );
          }

          return ListView.separated(
            padding: AppSpacing.paddingAllLg,
            itemCount: list.length,
            separatorBuilder: (BuildContext context, int index) =>
                AppSpacing.vMd,
            itemBuilder: (BuildContext context, int index) {
              final NotificationEntity notification = list[index];

              return Dismissible(
                key: Key(notification.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: AppRadius.largeAll,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Lưu trữ ',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(Icons.archive_outlined, color: Colors.white),
                    ],
                  ),
                ),
                onDismissed: (direction) {
                  provider.archiveNotification(notification.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Đã lưu trữ thông báo'),
                      action: SnackBarAction(
                        label: 'Hoàn tác',
                        onPressed: () {
                          // Vì offline-first, hoàn tác bằng cách tạo lại thông báo cũ
                          provider.createNotification(
                            userId: notification.userId,
                            title: notification.title,
                            content: notification.content,
                            type: notification.type,
                            relatedId: notification.relatedId,
                          );
                        },
                      ),
                    ),
                  );
                },
                child: GestureDetector(
                  onTap: () {
                    provider.markAsRead(notification.id);
                    if (notification.type ==
                            NotificationType.appointmentCreated ||
                        notification.type ==
                            NotificationType.appointmentApproved ||
                        notification.type ==
                            NotificationType.appointmentRejected) {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ViewingAppointmentsScreen(),
                        ),
                      );
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: AppSpacing.paddingAllMd,
                    decoration: BoxDecoration(
                      color: notification.isRead
                          ? theme.cardColor
                          : AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: AppRadius.largeAll,
                      border: Border.all(
                        color: notification.isRead
                            ? theme.dividerColor.withValues(alpha: 0.5)
                            : AppColors.primary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Left Icon Type
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _getColorForType(
                              notification.type,
                            ).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIconForType(notification.type),
                            color: _getColorForType(notification.type),
                            size: 24,
                          ),
                        ),
                        AppSpacing.hMd,
                        // Details Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const SizedBox.shrink(),
                                  // Created At
                                  Text(
                                    _formatDateTime(notification.createdAt),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Title
                              Text(
                                notification.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: notification.isRead
                                      ? FontWeight.w600
                                      : FontWeight.bold,
                                  color: notification.isRead
                                      ? theme.colorScheme.onSurface
                                      : theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Content
                              Text(
                                notification.content,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Unread Blue Dot
                        if (!notification.isRead) ...[
                          AppSpacing.hSm,
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
