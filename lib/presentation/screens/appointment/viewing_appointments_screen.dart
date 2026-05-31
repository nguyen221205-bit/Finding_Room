import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../domain/entities/app_enums.dart';
import '../../../domain/entities/viewing_appointment_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/role_provider.dart';
import '../../providers/room_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/empty_state.dart';

class ViewingAppointmentsScreen extends StatefulWidget {
  const ViewingAppointmentsScreen({super.key});

  @override
  State<ViewingAppointmentsScreen> createState() =>
      _ViewingAppointmentsScreenState();
}

class _ViewingAppointmentsScreenState extends State<ViewingAppointmentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  Future<void> _refresh() async {
    final auth = context.read<AuthProvider>();
    final roleProv = context.read<RoleProvider>();
    final aptProv = context.read<AppointmentProvider>();

    if (roleProv.activeMode == ActiveUserMode.landlord) {
      await aptProv.loadAppointmentsForLandlord(auth.userId);
    } else {
      await aptProv.loadAppointmentsForTenant(auth.userId);
    }
  }

  String _formatDateTime(DateTime dt) {
    final String minutes = dt.minute.toString().padLeft(2, '0');
    final String hours = dt.hour.toString().padLeft(2, '0');
    final String day = dt.day.toString().padLeft(2, '0');
    final String month = dt.month.toString().padLeft(2, '0');
    return '$hours:$minutes ngày $day/$month/${dt.year}';
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.approved:
        return Colors.green;
      case AppointmentStatus.rejected:
        return Colors.red;
      case AppointmentStatus.completed:
        return Colors.blue;
      case AppointmentStatus.cancelledByTenant:
      case AppointmentStatus.cancelledByLandlord:
      case AppointmentStatus.cancelledByAdmin:
        return Colors.grey;
    }
  }

  String _getStatusText(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return 'Chờ xác nhận';
      case AppointmentStatus.approved:
        return 'Đã xác nhận';
      case AppointmentStatus.rejected:
        return 'Đã từ chối';
      case AppointmentStatus.completed:
        return 'Đã xem phòng';
      case AppointmentStatus.cancelledByTenant:
        return 'Khách hủy';
      case AppointmentStatus.cancelledByLandlord:
        return 'Chủ nhà hủy';
      case AppointmentStatus.cancelledByAdmin:
        return 'Hủy bởi Admin';
    }
  }

  Future<void> _handleApprove(ViewingAppointmentEntity appointment) async {
    final aptProv = context.read<AppointmentProvider>();
    final ntfProv = context.read<NotificationProvider>();
    final roomProv = context.read<RoomProvider>();

    final bool ok = await aptProv.approveAppointment(appointment.id);
    if (!mounted) return;

    if (ok) {
      final room = roomProv.byId(appointment.roomId);
      final String roomTitle = room?.title ?? 'Phòng trọ';
      final String timeStr = _formatDateTime(appointment.appointmentTime);

      // Gửi thông báo cho người thuê
      await ntfProv.createNotification(
        userId: appointment.tenantId,
        title: 'Lịch xem phòng đã được xác nhận',
        content:
            'Yêu cầu xem phòng tại "$roomTitle" vào lúc $timeStr đã được chủ nhà chấp nhận.',
        type: NotificationType.appointmentApproved,
        relatedId: appointment.id,
      );
      if (!mounted) return;

      AppSnackbar.show(context, 'Đã phê duyệt lịch xem phòng.');
    } else {
      AppSnackbar.error(
        context,
        aptProv.error ?? 'Phê duyệt thất bại. Vui lòng thử lại.',
      );
    }
  }

  Future<void> _handleReject(ViewingAppointmentEntity appointment) async {
    final aptProv = context.read<AppointmentProvider>();
    final ntfProv = context.read<NotificationProvider>();
    final roomProv = context.read<RoomProvider>();

    final bool ok = await aptProv.rejectAppointment(appointment.id);
    if (!mounted) return;

    if (ok) {
      final room = roomProv.byId(appointment.roomId);
      final String roomTitle = room?.title ?? 'Phòng trọ';
      final String timeStr = _formatDateTime(appointment.appointmentTime);

      // Gửi thông báo cho người thuê
      await ntfProv.createNotification(
        userId: appointment.tenantId,
        title: 'Lịch xem phòng đã bị từ chối',
        content:
            'Yêu cầu xem phòng tại "$roomTitle" vào lúc $timeStr đã bị chủ nhà từ chối.',
        type: NotificationType.appointmentRejected,
        relatedId: appointment.id,
      );
      if (!mounted) return;

      AppSnackbar.show(context, 'Đã từ chối lịch xem phòng.');
    } else {
      AppSnackbar.error(
        context,
        aptProv.error ?? 'Từ chối thất bại. Vui lòng thử lại.',
      );
    }
  }

  Future<void> _handleTenantCancel(ViewingAppointmentEntity appointment) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy lịch xem phòng'),
        content: const Text(
          'Bạn có chắc chắn muốn hủy lịch hẹn xem phòng này không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hủy lịch'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final aptProv = context.read<AppointmentProvider>();
    final ntfProv = context.read<NotificationProvider>();
    final roomProv = context.read<RoomProvider>();

    final bool ok = await aptProv.cancelAppointmentByTenant(appointment.id);
    if (!mounted) return;

    if (ok) {
      final room = roomProv.byId(appointment.roomId);
      final String roomTitle = room?.title ?? 'Phòng trọ';
      final String timeStr = _formatDateTime(appointment.appointmentTime);

      // Gửi thông báo cho chủ nhà
      await ntfProv.createNotification(
        userId: appointment.landlordId,
        title: 'Khách hàng đã hủy lịch hẹn',
        content:
            'Lịch hẹn xem phòng tại "$roomTitle" vào lúc $timeStr đã bị khách thuê "${appointment.tenantName}" hủy bỏ.',
        type: NotificationType.appointmentCancelledByTenant,
        relatedId: appointment.id,
      );
      if (!mounted) return;

      AppSnackbar.show(context, 'Đã hủy lịch xem phòng thành công.');
    } else {
      AppSnackbar.error(
        context,
        aptProv.error ?? 'Hủy lịch thất bại. Vui lòng thử lại.',
      );
    }
  }

  Future<void> _handleLandlordCancel(
    ViewingAppointmentEntity appointment,
  ) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy lịch xem phòng'),
        content: const Text(
          'Bạn có chắc chắn muốn hủy lịch hẹn xem phòng này không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hủy lịch'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final aptProv = context.read<AppointmentProvider>();
    final ntfProv = context.read<NotificationProvider>();
    final roomProv = context.read<RoomProvider>();

    final bool ok = await aptProv.cancelAppointmentByLandlord(appointment.id);
    if (!mounted) return;

    if (ok) {
      final room = roomProv.byId(appointment.roomId);
      final String roomTitle = room?.title ?? 'Phòng trọ';
      final String timeStr = _formatDateTime(appointment.appointmentTime);

      // Gửi thông báo cho khách thuê
      await ntfProv.createNotification(
        userId: appointment.tenantId,
        title: 'Chủ nhà đã hủy lịch hẹn',
        content:
            'Lịch hẹn xem phòng tại "$roomTitle" vào lúc $timeStr đã bị chủ nhà hủy bỏ.',
        type: NotificationType.appointmentCancelledByLandlord,
        relatedId: appointment.id,
      );
      if (!mounted) return;

      AppSnackbar.show(context, 'Đã hủy lịch xem phòng thành công.');
    } else {
      AppSnackbar.error(
        context,
        aptProv.error ?? 'Hủy lịch thất bại. Vui lòng thử lại.',
      );
    }
  }

  Future<void> _handleComplete(ViewingAppointmentEntity appointment) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hoàn thành'),
        content: const Text(
          'Xác nhận khách hàng đã xem phòng trọ thực tế thành công?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final aptProv = context.read<AppointmentProvider>();
    final ntfProv = context.read<NotificationProvider>();
    final roomProv = context.read<RoomProvider>();

    final bool ok = await aptProv.completeAppointment(appointment.id);
    if (!mounted) return;

    if (ok) {
      final room = roomProv.byId(appointment.roomId);
      final String roomTitle = room?.title ?? 'Phòng trọ';
      final String timeStr = _formatDateTime(appointment.appointmentTime);

      // Gửi thông báo cho khách thuê
      await ntfProv.createNotification(
        userId: appointment.tenantId,
        title: 'Lịch xem phòng hoàn thành',
        content:
            'Chủ nhà đã xác nhận bạn đã xem phòng thành công tại "$roomTitle" lúc $timeStr. Cảm ơn bạn!',
        type: NotificationType.appointmentCompleted,
        relatedId: appointment.id,
      );
      if (!mounted) return;

      AppSnackbar.show(context, 'Đã cập nhật trạng thái xem phòng thành công.');
    } else {
      AppSnackbar.error(
        context,
        aptProv.error ?? 'Cập nhật thất bại. Vui lòng thử lại.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleProv = context.watch<RoleProvider>();
    final aptProv = context.watch<AppointmentProvider>();
    final roomProv = context.watch<RoomProvider>();

    final bool isLandlord = roleProv.activeMode == ActiveUserMode.landlord;
    final String screenTitle = isLandlord
        ? 'Lịch hẹn xem phòng (Chủ nhà)'
        : 'Lịch hẹn của tôi';

    final activeAppointments = aptProv.appointments.where((apt) {
      return apt.status == AppointmentStatus.pending ||
          apt.status == AppointmentStatus.approved;
    }).toList();

    final historyAppointments = aptProv.appointments.where((apt) {
      return apt.status == AppointmentStatus.completed ||
          apt.status == AppointmentStatus.rejected ||
          apt.status == AppointmentStatus.cancelledByTenant ||
          apt.status == AppointmentStatus.cancelledByLandlord ||
          apt.status == AppointmentStatus.cancelledByAdmin;
    }).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            screenTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Đang hoạt động'),
              Tab(text: 'Lịch sử'),
            ],
            indicatorWeight: 3,
          ),
        ),
        body: aptProv.isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildAppointmentList(
                    appointments: activeAppointments,
                    isLandlord: isLandlord,
                    roomProv: roomProv,
                    emptyMessage: isLandlord
                        ? 'Không có lịch hẹn nào đang hoạt động.'
                        : 'Bạn không có lịch hẹn nào đang hoạt động.',
                  ),
                  _buildAppointmentList(
                    appointments: historyAppointments,
                    isLandlord: isLandlord,
                    roomProv: roomProv,
                    emptyMessage: isLandlord
                        ? 'Không có lịch sử xem phòng nào.'
                        : 'Bạn chưa có lịch sử xem phòng nào.',
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAppointmentList({
    required List<ViewingAppointmentEntity> appointments,
    required bool isLandlord,
    required RoomProvider roomProv,
    required String emptyMessage,
  }) {
    if (appointments.isEmpty) {
      return Center(
        child: EmptyState(
          icon: Icons.calendar_today_outlined,
          title: 'Chưa có lịch hẹn',
          message: emptyMessage,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: AppSpacing.paddingAllLg,
        itemCount: appointments.length,
        itemBuilder: (BuildContext context, int index) {
          final appointment = appointments[index];
          final room = roomProv.byId(appointment.roomId);
          final Color statusColor = _getStatusColor(appointment.status);

          final bool showLandlordApproveReject =
              isLandlord && appointment.status == AppointmentStatus.pending;
          final bool showLandlordComplete =
              isLandlord && appointment.status == AppointmentStatus.approved;
          final bool showLandlordCancel =
              isLandlord && appointment.status == AppointmentStatus.approved;

          final bool showTenantCancel =
              !isLandlord &&
              (appointment.status == AppointmentStatus.pending ||
                  appointment.status == AppointmentStatus.approved);

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Lịch hẹn xem phòng',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _getStatusText(appointment.status),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, thickness: 0.8),

                  Text(
                    room?.title ?? 'Phòng trọ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  _buildInfoRow(
                    icon: Icons.access_time_outlined,
                    label: 'Thời gian hẹn:',
                    value: _formatDateTime(appointment.appointmentTime),
                  ),
                  const SizedBox(height: 8),

                  _buildInfoRow(
                    icon: isLandlord
                        ? Icons.person_outline
                        : Icons.home_work_outlined,
                    label: isLandlord ? 'Người thuê:' : 'Họ tên đặt lịch:',
                    value: appointment.tenantName,
                  ),
                  const SizedBox(height: 8),

                  _buildInfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Số điện thoại:',
                    value: appointment.tenantPhone,
                  ),
                  const SizedBox(height: 8),

                  _buildInfoRow(
                    icon: Icons.group_outlined,
                    label: 'Số người xem:',
                    value: '${appointment.numberOfPeople} người',
                  ),

                  if (appointment.note != null &&
                      appointment.note!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      icon: Icons.note_alt_outlined,
                      label: 'Ghi chú:',
                      value: appointment.note!,
                    ),
                  ],

                  if (showLandlordApproveReject) ...[
                    const Divider(height: 24, thickness: 0.8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _handleReject(appointment),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Từ chối',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => _handleApprove(appointment),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Xác nhận',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (showLandlordComplete || showLandlordCancel) ...[
                    const Divider(height: 24, thickness: 0.8),
                    Row(
                      children: [
                        if (showLandlordCancel)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _handleLandlordCancel(appointment),
                              icon: const Icon(Icons.cancel_outlined, size: 16),
                              label: const Text('Hủy lịch'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        if (showLandlordCancel && showLandlordComplete)
                          const SizedBox(width: 16),
                        if (showLandlordComplete)
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _handleComplete(appointment),
                              icon: const Icon(Icons.done_all, size: 16),
                              label: const Text('Đã xem phòng'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],

                  if (showTenantCancel) ...[
                    const Divider(height: 24, thickness: 0.8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _handleTenantCancel(appointment),
                            icon: const Icon(Icons.cancel_outlined, size: 16),
                            label: const Text('Hủy lịch hẹn'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: theme.hintColor),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: theme.hintColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
