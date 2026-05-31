import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../domain/entities/app_enums.dart';
import '../../../domain/entities/room_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/entities/landlord_request_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/room_provider.dart';
import '../../providers/landlord_request_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/app_image.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/status_badge.dart';

class AdminRoomDetailScreenV2 extends StatefulWidget {
  final String roomId;

  const AdminRoomDetailScreenV2({super.key, required this.roomId});

  @override
  State<AdminRoomDetailScreenV2> createState() =>
      _AdminRoomDetailScreenV2State();
}

class _AdminRoomDetailScreenV2State extends State<AdminRoomDetailScreenV2> {
  bool _isProcessing = false;

  void _showFullscreenImage(
    BuildContext context,
    String title,
    String imagePath,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (BuildContext context) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Hero(
                  tag: imagePath,
                  child: AppImage(
                    imagePath: imagePath,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<String?> _askRejectReason(BuildContext context) {
    return AppDialogs.showRejectionDialog(
      context: context,
      title: 'Từ chối phòng trọ',
      label: 'Lý do từ chối',
      hint: 'Nhập lý do chi tiết từ chối duyệt phòng này...',
    );
  }

  Widget _buildInfoSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: AppSpacing.paddingAllLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value, {
    int maxLines = 1,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: theme.hintColor,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Chưa cung cấp',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
                fontSize: 14,
              ),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: theme.hintColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roomProvider = context.watch<RoomProvider>();
    final authProvider = context.watch<AuthProvider>();
    final requestProvider = context.watch<LandlordRequestProvider>();

    final RoomEntity? room = roomProvider.byId(widget.roomId);

    if (room == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết tin đăng')),
        body: const Center(child: Text('Không tìm thấy thông tin phòng trọ.')),
      );
    }

    final StatusBadge badge = switch (room.status) {
      RoomStatus.pending => const StatusBadge.pending(label: 'Chờ duyệt'),
      RoomStatus.approved => const StatusBadge.approved(label: 'Đã duyệt'),
      RoomStatus.rejected => const StatusBadge.rejected(label: 'Bị từ chối'),
      RoomStatus.hiddenByAdmin => const StatusBadge.rejected(label: 'Bị ẩn'),
    };

    final String formattedPrice = room.price <= 0
        ? 'Thỏa thuận'
        : '${(room.price / 1000000).toStringAsFixed(1).replaceAll('.0', '')} triệu/tháng';

    // Check landlord verification status
    final LandlordRequestEntity? request = requestProvider.getUserRequest(
      room.ownerId,
    );
    final bool isLandlordVerified =
        request?.status == LandlordRequestStatus.approved;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết tin duyệt phòng'),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Moderation Status Banner
            Container(
              color: switch (room.status) {
                RoomStatus.pending =>
                  theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                RoomStatus.approved =>
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                RoomStatus.rejected =>
                  theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                RoomStatus.hiddenByAdmin =>
                  theme.colorScheme.errorContainer.withValues(alpha: 0.3),
              },
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Trạng thái kiểm duyệt: ',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                                fontSize: 14,
                              ),
                            ),
                            badge,
                          ],
                        ),
                        if (room.status == RoomStatus.rejected &&
                            room.rejectionReason != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Lý do từ chối: ${room.rejectionReason}',
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: AppSpacing.paddingAllLg,
                children: [
                  // SECTION 7: IMAGES (Horizontal gallery)
                  _buildInfoSection(
                    context: context,
                    title: 'Hình ảnh phòng trọ',
                    icon: Icons.photo_library_outlined,
                    children: [
                      if (room.imageUrls.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: Text(
                              'Chưa tải lên hình ảnh nào',
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 120,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: room.imageUrls.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final String imgPath = room.imageUrls[index];
                              return InkWell(
                                onTap: () => _showFullscreenImage(
                                  context,
                                  'Hình ảnh ${index + 1}',
                                  imgPath,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 160,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: theme.colorScheme.outlineVariant,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(11),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Hero(
                                          tag: imgPath,
                                          child: AppImage(imagePath: imgPath),
                                        ),
                                        Positioned(
                                          top: 6,
                                          right: 6,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                alpha: 0.5,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.fullscreen,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // SECTION 1: LANDLORD INFORMATION
                  _buildInfoSection(
                    context: context,
                    title: 'Thông tin chủ nhà',
                    icon: Icons.person_outline,
                    children: [
                      FutureBuilder<UserEntity?>(
                        future: authProvider.getUserById(room.ownerId),
                        builder: (context, snapshot) {
                          final user = snapshot.data;

                          // Determine real-time name
                          final String displayName =
                              user != null && user.username.isNotEmpty
                              ? user.username
                              : (room.landlordName.isNotEmpty
                                    ? room.landlordName
                                    : 'Chưa cập nhật');

                          // Determine real-time phone number
                          final String displayPhone =
                              user != null &&
                                  user.phoneNumber != null &&
                                  user.phoneNumber!.isNotEmpty
                              ? user.phoneNumber!
                              : (room.landlordPhone.isNotEmpty
                                    ? room.landlordPhone
                                    : 'Chưa cung cấp');

                          // Determine real-time Zalo number
                          final String displayZalo =
                              user != null &&
                                  user.zaloNumber != null &&
                                  user.zaloNumber!.isNotEmpty
                              ? user.zaloNumber!
                              : 'Chưa cung cấp';

                          // Determine real-time avatar path/URL
                          final String avatarPath =
                              user != null &&
                                  user.avatarPath != null &&
                                  user.avatarPath!.isNotEmpty
                              ? user.avatarPath!
                              : room.landlordAvatarUrl;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Phân khu 1: Thẻ tiêu đề đại diện (Profile Header Section)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child: SizedBox(
                                      width: 60,
                                      height: 60,
                                      child: AppImage(
                                        imagePath: avatarPath,
                                        placeholderIcon: Icons.person_outline,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayName,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: theme
                                                    .colorScheme
                                                    .surfaceContainerHighest,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: theme
                                                      .colorScheme
                                                      .outlineVariant,
                                                ),
                                              ),
                                              child: Text(
                                                user != null &&
                                                        user.userCode.isNotEmpty
                                                    ? user.userCode
                                                    : 'Mã: ${room.ownerId.length > 8 ? room.ownerId.substring(0, 8) : room.ownerId}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                            ),
                                            isLandlordVerified
                                                ? const StatusBadge.approved(
                                                    label: 'Đã xác thực',
                                                  )
                                                : StatusBadge(
                                                    label: request != null
                                                        ? (request.status ==
                                                                  LandlordRequestStatus
                                                                      .pending
                                                              ? 'Chờ xác thực'
                                                              : 'Bị từ chối')
                                                        : 'Chưa xác thực',
                                                    type: request != null
                                                        ? (request.status ==
                                                                  LandlordRequestStatus
                                                                      .pending
                                                              ? StatusBadgeType
                                                                    .warning
                                                              : StatusBadgeType
                                                                    .error)
                                                        : StatusBadgeType.info,
                                                  ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12.0,
                                ),
                                child: Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: theme.colorScheme.outlineVariant,
                                ),
                              ),

                              // Phân khu 2: Thông tin liên hệ tối giản (Premium Contact List)
                              Column(
                                children: [
                                  _buildContactItem(
                                    context,
                                    label: 'Số điện thoại',
                                    value: displayPhone,
                                  ),
                                  const SizedBox(height: 4),
                                  _buildContactItem(
                                    context,
                                    label: 'Số Zalo',
                                    value: displayZalo,
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // SECTION 2: BASIC INFORMATION
                  _buildInfoSection(
                    context: context,
                    title: 'Thông tin cơ bản',
                    icon: Icons.info_outline,
                    children: [
                      if (room.roomCode.isNotEmpty)
                        _buildInfoItem(context, 'Mã tin đăng', room.roomCode),
                      _buildInfoItem(
                        context,
                        'Tiêu đề tin',
                        room.title,
                        maxLines: 2,
                      ),
                      _buildInfoItem(context, 'Giá thuê', formattedPrice),
                      _buildInfoItem(
                        context,
                        'Sức chứa',
                        '${room.capacity} người',
                      ),
                      _buildInfoItem(context, 'Nội thất', room.furniture),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // SECTION 3: LOCATION
                  _buildInfoSection(
                    context: context,
                    title: 'Địa điểm & Vị trí',
                    icon: Icons.location_on_outlined,
                    children: [
                      _buildInfoItem(
                        context,
                        'Quận/Huyện',
                        room.district ?? 'Chưa cập nhật',
                      ),
                      _buildInfoItem(
                        context,
                        'Địa chỉ đầy đủ',
                        room.address,
                        maxLines: 3,
                      ),
                      _buildInfoItem(
                        context,
                        'Vĩ độ (Latitude)',
                        room.latitude != null
                            ? room.latitude!.toString()
                            : 'Chưa cập nhật',
                      ),
                      _buildInfoItem(
                        context,
                        'Kinh độ (Longitude)',
                        room.longitude != null
                            ? room.longitude!.toString()
                            : 'Chưa cập nhật',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // SECTION 4: DIMENSIONS
                  _buildInfoSection(
                    context: context,
                    title: 'Kích thước & Trạng thái trống',
                    icon: Icons.square_foot_outlined,
                    children: [
                      _buildInfoItem(
                        context,
                        'Diện tích đất',
                        '${room.area.toStringAsFixed(0)} m²',
                      ),
                      _buildInfoItem(
                        context,
                        'Diện tích sử dụng',
                        room.usableArea != null
                            ? '${room.usableArea!.toStringAsFixed(0)} m²'
                            : 'Chưa cập nhật',
                      ),
                      _buildInfoItem(
                        context,
                        'Chiều dài',
                        room.length != null
                            ? '${room.length!.toStringAsFixed(1)} m'
                            : 'Chưa cập nhật',
                      ),
                      _buildInfoItem(
                        context,
                        'Chiều rộng',
                        room.width != null
                            ? '${room.width!.toStringAsFixed(1)} m'
                            : 'Chưa cập nhật',
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 130,
                              child: Text(
                                'Tình trạng thuê',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.outline,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            room.availability == RoomAvailability.available
                                ? const StatusBadge.approved(label: 'Còn trống')
                                : const StatusBadge.rejected(label: 'Đã thuê'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // SECTION 5: AMENITIES
                  _buildInfoSection(
                    context: context,
                    title: 'Tiện ích trọ',
                    icon: Icons.star_border_outlined,
                    children: [
                      if (room.amenities.isEmpty)
                        const Text(
                          'Không có tiện ích nào được liệt kê',
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: room.amenities.map((String amenity) {
                            return Chip(
                              label: Text(
                                amenity,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              backgroundColor: theme
                                  .colorScheme
                                  .primaryContainer
                                  .withValues(alpha: 0.2),
                              side: BorderSide(
                                color: theme.colorScheme.primaryContainer,
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // SECTION 6: DESCRIPTION
                  _buildInfoSection(
                    context: context,
                    title: 'Mô tả chi tiết',
                    icon: Icons.description_outlined,
                    children: [
                      Text(
                        room.description.isNotEmpty
                            ? room.description
                            : 'Không có mô tả',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // SECTION 8: MODERATION ACTION BUTTONS
            if (room.status == RoomStatus.pending)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isProcessing
                            ? null
                            : () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final navigator = Navigator.of(context);
                                final ntfProvider = context
                                    .read<NotificationProvider>();

                                final String? reason = await _askRejectReason(
                                  context,
                                );
                                if (reason == null || reason.trim().isEmpty) {
                                  return;
                                }

                                setState(() => _isProcessing = true);

                                final bool ok = await roomProvider.rejectRoom(
                                  roomId: room.id,
                                  reason: reason,
                                );
                                setState(() => _isProcessing = false);

                                if (ok) {
                                  await ntfProvider.createNotification(
                                    userId: room.ownerId,
                                    title: 'Tin đăng phòng bị từ chối',
                                    content:
                                        'Tin đăng phòng "${room.title}" của bạn đã bị từ chối. Lý do: $reason',
                                    type: NotificationType.roomRejected,
                                    relatedId: room.id,
                                  );
                                  AppSnackbar.showWithMessenger(
                                    messenger,
                                    'Đã từ chối tin đăng phòng trọ.',
                                  );
                                  navigator.pop();
                                } else {
                                  AppSnackbar.showWithMessenger(
                                    messenger,
                                    'Không thể thực hiện hành động từ chối.',
                                  );
                                }
                              },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Từ chối',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isProcessing
                            ? null
                            : () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final navigator = Navigator.of(context);
                                final ntfProvider = context
                                    .read<NotificationProvider>();

                                final bool confirm =
                                    await AppDialogs.confirmApprove(
                                      context,
                                      "tin đăng phòng: '${room.title}'",
                                    );
                                if (!confirm) return;

                                setState(() => _isProcessing = true);

                                final bool ok = await roomProvider.approveRoom(
                                  room.id,
                                );
                                setState(() => _isProcessing = false);

                                if (ok) {
                                  await ntfProvider.createNotification(
                                    userId: room.ownerId,
                                    title: 'Tin đăng phòng đã được duyệt',
                                    content:
                                        'Chúc mừng! Tin đăng phòng "${room.title}" của bạn đã được duyệt và đăng tải thành công.',
                                    type: NotificationType.roomApproved,
                                    relatedId: room.id,
                                  );
                                  AppSnackbar.showWithMessenger(
                                    messenger,
                                    'Đã phê duyệt tin đăng phòng trọ.',
                                  );
                                  navigator.pop();
                                } else {
                                  AppSnackbar.showWithMessenger(
                                    messenger,
                                    'Không thể phê duyệt tin đăng.',
                                  );
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Phê duyệt',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
