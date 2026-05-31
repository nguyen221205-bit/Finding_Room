import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../domain/entities/app_enums.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/entities/landlord_request_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/landlord_request_provider.dart';
import '../../providers/room_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/app_snackbar.dart';
import '../../providers/appointment_provider.dart';
import 'landlord_detail_screen.dart';

class LandlordManagementScreen extends StatefulWidget {
  const LandlordManagementScreen({super.key});

  @override
  State<LandlordManagementScreen> createState() =>
      _LandlordManagementScreenState();
}

class _LandlordManagementScreenState extends State<LandlordManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<UserEntity> _allLandlords = <UserEntity>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() => _loadLandlords());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLandlords() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final users = await authProvider.getAllUsers();
      if (!mounted) return;

      // Filter users who are landlords (exclude current admin to prevent self-revocation)
      final String currentUserId = authProvider.userId;
      setState(() {
        _allLandlords = users
            .where(
              (u) =>
                  u.roles.contains(UserRole.landlord) && u.id != currentUserId,
            )
            .toList();
      });
    } catch (_) {
      if (mounted) {
        AppSnackbar.error(context, 'Không thể tải danh sách chủ nhà.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleRevoke(UserEntity landlord) async {
    final String? reason = await AppDialogs.showRejectionDialog(
      context: context,
      title: 'Thu hồi quyền chủ nhà',
      label: 'Lý do thu hồi',
      hint: 'Nhập lý do thu hồi quyền chủ nhà trọ này...',
      confirmLabel: 'Thu hồi',
    );

    if (reason == null || reason.trim().isEmpty || !mounted) return;

    setState(() => _isLoading = true);

    try {
      final requestProvider = context.read<LandlordRequestProvider>();
      final roomProvider = context.read<RoomProvider>();
      final appointmentProvider = context.read<AppointmentProvider>();
      final authProvider = context.read<AuthProvider>();
      final notificationProvider = context.read<NotificationProvider>();

      // 1. Revoke verification request
      await requestProvider.revokeVerificationByUserId(
        userId: landlord.id,
        reason: reason,
      );

      // 2. Hide all rooms of this landlord
      await roomProvider.hideAllRoomsForOwner(
        ownerId: landlord.id,
        reason: reason,
      );

      // Tự động hủy tất cả lịch hẹn đang chờ/đã duyệt của chủ nhà này
      final cancelledApts = await appointmentProvider
          .cancelAppointmentsForLandlordByAdmin(landlord.id);

      // 3. Revoke privileges from Auth provider
      final bool success = await authProvider.revokeLandlordPrivileges(
        landlord.id,
      );

      if (success && mounted) {
        // 4. Create Notification cho chủ nhà
        await notificationProvider.createNotification(
          userId: landlord.id,
          title: 'Quyền chủ nhà bị thu hồi',
          content:
              'Quyền hạn chủ nhà của bạn đã bị thu hồi. Lý do: $reason. Tất cả phòng của bạn đã bị ẩn.',
          type: NotificationType.landlordPrivilegeRevoked,
        );

        // Tạo thông báo cho các khách thuê bị ảnh hưởng
        for (final apt in cancelledApts) {
          final String dateStr =
              '${apt.appointmentTime.day}/${apt.appointmentTime.month}/${apt.appointmentTime.year} ${apt.appointmentTime.hour.toString().padLeft(2, '0')}:${apt.appointmentTime.minute.toString().padLeft(2, '0')}';
          await notificationProvider.createNotification(
            userId: apt.tenantId,
            title: 'Lịch xem phòng bị hủy',
            content:
                'Lịch hẹn xem phòng vào lúc $dateStr đã bị quản trị viên hủy do chủ nhà trọ này bị thu hồi quyền hạn hoặc vi phạm quy định.',
            type: NotificationType.appointmentCancelledByAdmin,
            relatedId: apt.id,
          );
        }

        if (!mounted) return;
        AppSnackbar.success(
          context,
          'Đã thu hồi quyền chủ nhà của ${landlord.username} thành công.',
        );
        _loadLandlords();
      } else if (mounted) {
        AppSnackbar.error(context, 'Thu hồi quyền chủ nhà thất bại.');
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.error(context, 'Đã xảy ra lỗi khi thu hồi quyền chủ nhà.');
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roomProvider = context.watch<RoomProvider>();
    final requestProvider = context.watch<LandlordRequestProvider>();

    final List<UserEntity> filteredLandlords = _allLandlords.where((landlord) {
      final String query = _searchQuery.toLowerCase();
      return landlord.username.toLowerCase().contains(query) ||
          landlord.email.toLowerCase().contains(query) ||
          (landlord.phoneNumber ?? '').contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý chủ nhà'),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: AppSpacing.paddingAllLg,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm theo tên, email, sđt...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),

            // Landlord list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredLandlords.isEmpty
                  ? const EmptyState(
                      icon: Icons.people_outline,
                      title: 'Không tìm thấy chủ nhà nào',
                      message:
                          'Danh sách chủ nhà đã được phê duyệt xác minh sẽ hiển thị tại đây.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 24,
                      ),
                      itemCount: filteredLandlords.length,
                      separatorBuilder: (_, _) => AppSpacing.vMd,
                      itemBuilder: (context, index) {
                        final landlord = filteredLandlords[index];
                        final landlordRooms = roomProvider.roomsForOwner(
                          landlord.id,
                        );
                        final int totalRooms = landlordRooms.length;
                        final int activeRooms = landlordRooms
                            .where((r) => r.status == RoomStatus.approved)
                            .length;

                        final LandlordRequestEntity? request = requestProvider
                            .getUserRequest(landlord.id);
                        final String approvedDateStr = request != null
                            ? _formatDate(request.createdAt)
                            : 'Chưa rõ';

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
                                // Landlord Header
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor:
                                          theme.colorScheme.primaryContainer,
                                      child: Text(
                                        landlord.username.isNotEmpty
                                            ? landlord.username[0].toUpperCase()
                                            : 'L',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: theme
                                              .colorScheme
                                              .onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                    AppSpacing.hMd,
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            landlord.username,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            landlord.email,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: theme.hintColor,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Divider(height: 1),
                                const SizedBox(height: 12),

                                // Info Rows
                                _buildInfoRow(
                                  context: context,
                                  icon: Icons.phone_outlined,
                                  label: 'Số điện thoại: ',
                                  value:
                                      landlord.phoneNumber ??
                                      landlord.zaloNumber ??
                                      'Không có',
                                ),
                                const SizedBox(height: 6),
                                _buildInfoRow(
                                  context: context,
                                  icon: Icons.home_work_outlined,
                                  label: 'Số lượng phòng: ',
                                  value:
                                      '$totalRooms phòng ($activeRooms đang hoạt động)',
                                ),
                                const SizedBox(height: 6),
                                _buildInfoRow(
                                  context: context,
                                  icon: Icons.verified_outlined,
                                  label: 'Ngày phê duyệt: ',
                                  value: approvedDateStr,
                                ),
                                const SizedBox(height: 16),
                                const Divider(height: 1),
                                const SizedBox(height: 12),

                                // Actions
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                LandlordDetailScreen(
                                                  landlord: landlord,
                                                ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.visibility_outlined,
                                        size: 18,
                                      ),
                                      label: const Text('Xem phòng'),
                                    ),
                                    AppSpacing.hMd,
                                    TextButton.icon(
                                      onPressed: () => _handleRevoke(landlord),
                                      icon: Icon(
                                        Icons.gpp_maybe_outlined,
                                        size: 18,
                                        color: theme.colorScheme.error,
                                      ),
                                      label: Text(
                                        'Thu hồi quyền',
                                        style: TextStyle(
                                          color: theme.colorScheme.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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

  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.hintColor),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
