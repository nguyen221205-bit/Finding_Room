import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/launchers.dart';
import '../../../domain/entities/app_enums.dart';
import '../../../domain/entities/room_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/conversation_provider.dart';
import '../../providers/room_provider.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/app_image.dart';
import '../../widgets/section_header.dart';
import '../../widgets/booking_appointment_dialog.dart';
import '../chat/chat_detail_screen.dart';

class RoomDetailScreen extends StatefulWidget {
  final String roomId;

  const RoomDetailScreen({super.key, required this.roomId});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  int _imageIndex = 0;
  late final PageController _pageController;
  Future<UserEntity?>? _landlordFuture;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  IconData _getAmenityIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('wifi') || lower.contains('internet')) return Icons.wifi;
    if (lower.contains('máy lạnh') ||
        lower.contains('điều hòa') ||
        lower.contains('ac')) {
      return Icons.ac_unit;
    }
    if (lower.contains('giữ xe') ||
        lower.contains('đỗ xe') ||
        lower.contains('bãi xe') ||
        lower.contains('parking')) {
      return Icons.local_parking;
    }
    if (lower.contains('nội thất') ||
        lower.contains('furniture') ||
        lower.contains('giường') ||
        lower.contains('tủ')) {
      return Icons.chair_outlined;
    }
    if (lower.contains('máy giặt') || lower.contains('washing')) {
      return Icons.local_laundry_service_outlined;
    }
    if (lower.contains('chợ') ||
        lower.contains('siêu thị') ||
        lower.contains('market')) {
      return Icons.storefront;
    }
    if (lower.contains('trường') || lower.contains('school')) {
      return Icons.school_outlined;
    }
    if (lower.contains('tự do') || lower.contains('clock')) {
      return Icons.access_time;
    }
    if (lower.contains('bếp') || lower.contains('kitchen')) {
      return Icons.kitchen;
    }
    if (lower.contains('an ninh') ||
        lower.contains('bảo vệ') ||
        lower.contains('security')) {
      return Icons.security;
    }
    return Icons.check_circle_outline;
  }

  Widget _buildDimensionCard(Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(item['icon'] as IconData, color: Colors.blue.shade700, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item['label'] as String,
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item['value'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use context.watch to subscribe to both providers at the top level
    final roomProvider = context.watch<RoomProvider>();
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    final RoomEntity? room = roomProvider.byId(widget.roomId);

    // Show loading spinner while rooms are still being fetched
    if (roomProvider.isLoading && room == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Đang tải...'),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (room == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const SafeArea(
          child: EmptyState(icon: Icons.home_outlined, title: 'Room not found'),
        ),
      );
    }

    // ── Prepare data ─────────────────────────────────────────
    _landlordFuture ??= authProvider.getUserById(room.ownerId);

    final List<String> imageUrls = room.imageUrls.isNotEmpty
        ? room.imageUrls
        : <String>[room.primaryImageUrl];
    final int safeImageIndex = _imageIndex.clamp(0, imageUrls.length - 1);

    final String formattedPrice;
    if (room.price <= 0) {
      formattedPrice = 'Thỏa thuận';
    } else {
      formattedPrice =
          '${(room.price / 1000000).toStringAsFixed(1).replaceAll('.0', '')} triệu/tháng';
    }

    final String currentUserId = authProvider.userId;
    final bool isOwner =
        currentUserId.isNotEmpty &&
        room.ownerId.isNotEmpty &&
        room.ownerId == currentUserId;

    // ── Dimensions ───────────────────────────────────────────
    final List<Map<String, dynamic>> dimensionItems = [];
    if (room.area > 0) {
      dimensionItems.add({
        'icon': Icons.aspect_ratio_outlined,
        'label': 'Diện tích đất',
        'value': '${room.area.toStringAsFixed(0)} m²',
      });
    }
    if (room.usableArea != null && room.usableArea! > 0) {
      dimensionItems.add({
        'icon': Icons.layers_outlined,
        'label': 'Diện tích sử dụng',
        'value': '${room.usableArea!.toStringAsFixed(0)} m²',
      });
    }
    if (room.length != null && room.length! > 0) {
      dimensionItems.add({
        'icon': Icons.straighten_outlined,
        'label': 'Chiều dài',
        'value': '${room.length!.toStringAsFixed(1)} m',
      });
    }
    if (room.width != null && room.width! > 0) {
      dimensionItems.add({
        'icon': Icons.compare_arrows_outlined,
        'label': 'Chiều rộng',
        'value': '${room.width!.toStringAsFixed(1)} m',
      });
    }

    final List<Widget> dimensionRows = [];
    for (int i = 0; i < dimensionItems.length; i += 2) {
      final item1 = dimensionItems[i];
      final item2 = (i + 1 < dimensionItems.length)
          ? dimensionItems[i + 1]
          : null;
      dimensionRows.add(
        Row(
          children: [
            Expanded(child: _buildDimensionCard(item1)),
            const SizedBox(width: 12),
            Expanded(
              child: item2 != null
                  ? _buildDimensionCard(item2)
                  : const SizedBox(),
            ),
          ],
        ),
      );
      if (i + 2 < dimensionItems.length) {
        dimensionRows.add(const SizedBox(height: 12));
      }
    }

    // ── Amenities ────────────────────────────────────────────
    final List<Widget> amenityRows = [];
    for (int i = 0; i < room.amenities.length; i += 2) {
      final String amenity1 = room.amenities[i];
      final String? amenity2 = (i + 1 < room.amenities.length)
          ? room.amenities[i + 1]
          : null;

      amenityRows.add(
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getAmenityIcon(amenity1),
                      color: Colors.green.shade700,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      amenity1,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: amenity2 != null
                  ? Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getAmenityIcon(amenity2),
                            color: Colors.green.shade700,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            amenity2,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox(),
            ),
          ],
        ),
      );
      if (i + 2 < room.amenities.length) {
        amenityRows.add(const SizedBox(height: 12));
      }
    }

    // ── Build UI ─────────────────────────────────────────────
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          room.title.isEmpty ? 'Không có tiêu đề' : room.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            onPressed: () =>
                context.read<RoomProvider>().toggleFavorite(room.id),
            icon: Icon(
              room.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: room.isFavorite ? Colors.red : AppColors.textSecondary,
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (String val) {
              AppSnackbar.show(context, 'Tính năng đang phát triển');
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Chia sẻ'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.report_problem_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Báo cáo tin đăng'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.paddingAllLg,
          children: <Widget>[
            // ── 1. Image Carousel ──────────────────────────────
            ClipRRect(
              borderRadius: AppRadius.largeAll,
              child: SizedBox(
                height: 240,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    PageView.builder(
                      controller: _pageController,
                      onPageChanged: (int i) {
                        if (i != _imageIndex && mounted) {
                          setState(() => _imageIndex = i);
                        }
                      },
                      itemCount: imageUrls.length,
                      itemBuilder: (BuildContext ctx, int i) {
                        return AppImage(
                          imagePath: imageUrls[i],
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                    Positioned(
                      right: AppSpacing.md,
                      bottom: AppSpacing.md,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: AppRadius.pillAll,
                        ),
                        child: Text(
                          '${safeImageIndex + 1}/${imageUrls.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── 2. Price + Availability ────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Text(
                    '$formattedPrice  •  ${room.area > 0 ? '${room.area.toStringAsFixed(0)}m²' : 'Chưa rõ diện tích'}',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                ),
                _AvailabilityBadge(availability: room.availability),
              ],
            ),
            if (authProvider.hasRole(UserRole.admin) &&
                room.roomCode.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.tag, size: 14, color: Colors.blue.shade700),
                  const SizedBox(width: 4),
                  Text(
                    'Mã tin đăng: ${room.roomCode}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),

            // ── 3. Title ───────────────────────────────────────
            Text(
              room.title.isEmpty ? 'Không có tiêu đề' : room.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: theme.colorScheme.onSurface,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),

            // ── 4. Address ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.location_on_outlined,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      room.address.isEmpty
                          ? 'Chưa cập nhật địa chỉ'
                          : room.address,
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── 5. Posted time ─────────────────────────────────
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Đăng gần đây',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── 6. Book Schedule CTA ───────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final String renterId = authProvider.userId;
                  if (renterId.isEmpty) {
                    AppSnackbar.show(
                      context,
                      'Vui lòng đăng nhập để đặt lịch xem phòng.',
                    );
                    return;
                  }
                  if (room.ownerId.isNotEmpty && renterId == room.ownerId) {
                    AppSnackbar.show(
                      context,
                      'Bạn là chủ của phòng này, không thể tự đặt lịch.',
                    );
                    return;
                  }
                  showDialog<bool>(
                    context: context,
                    builder: (_) => BookingAppointmentDialog(room: room),
                  );
                },
                icon: const Icon(
                  Icons.calendar_month,
                  color: Colors.orange,
                  size: 20,
                ),
                label: const Text(
                  'Đặt lịch xem nhà',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.orange.shade50,
                  side: const BorderSide(color: Colors.orange, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── 7. Landlord Management (owner only) ────────────
            if (isOwner) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Quản lý phòng (Chủ nhà)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    AppSpacing.vSm,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const Text(
                          'Trạng thái phòng:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        DropdownButton<RoomAvailability>(
                          value: room.availability,
                          items: RoomAvailability.values.map((
                            RoomAvailability a,
                          ) {
                            return DropdownMenuItem<RoomAvailability>(
                              value: a,
                              child: Text(
                                a == RoomAvailability.available
                                    ? 'Còn trống'
                                    : 'Đã thuê',
                              ),
                            );
                          }).toList(),
                          onChanged: (RoomAvailability? val) async {
                            if (val != null) {
                              final provider = context.read<RoomProvider>();
                              final bool ok = await provider.updateAvailability(
                                room.id,
                                val,
                              );
                              if (!context.mounted) return;
                              if (ok) {
                                AppSnackbar.success(
                                  context,
                                  'Cập nhật trạng thái phòng thành công!',
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── 8. Dimensions ──────────────────────────────────
            if (dimensionItems.isNotEmpty) ...[
              const SectionHeader(title: 'Kích thước & Diện tích'),
              AppSpacing.vSm,
              Column(children: dimensionRows),
              const SizedBox(height: 20),
            ],

            // ── 9. Amenities ───────────────────────────────────
            if (room.amenities.isNotEmpty) ...[
              const SectionHeader(title: 'Tiện ích phòng trọ'),
              AppSpacing.vSm,
              Column(children: amenityRows),
              const SizedBox(height: 20),
            ],

            // ── 10. Room Position Map ──────────────────────────
            const SectionHeader(title: 'Vị trí phòng'),
            AppSpacing.vSm,
            _buildMapSection(room),
            const SizedBox(height: 20),
          ],
        ),
      ),
      // ── Bottom Bar ───────────────────────────────────────────
      bottomNavigationBar: FutureBuilder<UserEntity?>(
        future: _landlordFuture,
        builder: (BuildContext context, AsyncSnapshot<UserEntity?> snapshot) {
          final UserEntity? landlord = snapshot.data;

          final String landlordPhone =
              landlord?.phoneNumber ?? room.landlordPhone;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: SafeArea(
              child: Row(
                children: <Widget>[
                  if (landlordPhone.isNotEmpty) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final bool ok = await Launchers.callPhone(
                            landlordPhone,
                          );
                          if (!context.mounted) return;
                          if (!ok) {
                            AppSnackbar.error(
                              context,
                              'Không thể mở trình gọi điện.',
                            );
                          }
                        },
                        icon: const Icon(Icons.call, size: 20),
                        label: const Text(
                          'Gọi điện',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue.shade700,
                          side: BorderSide(
                            color: Colors.blue.shade700,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        final String renterId = authProvider.userId;
                        final String landlordId = room.ownerId.isEmpty
                            ? 'unknown'
                            : room.ownerId;

                        if (renterId.isEmpty) {
                          AppSnackbar.show(
                            context,
                            'Vui lòng đăng nhập để nhắn tin.',
                          );
                          return;
                        }

                        if (renterId == landlordId) {
                          AppSnackbar.show(
                            context,
                            'Bạn không thể tự nhắn tin cho chính mình.',
                          );
                          return;
                        }

                        final conversation = await context
                            .read<ConversationProvider>()
                            .createConversation(
                              participantIds: [renterId, landlordId],
                              roomId: room.id,
                            );

                        if (context.mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ChatDetailScreen(
                                conversationId: conversation.id,
                                otherParticipantId: landlordId,
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.chat_bubble_outline, size: 20),
                      label: const Text(
                        'Nhắn tin',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMapSection(RoomEntity room) {
    if (room.latitude == null || room.longitude == null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.map_outlined, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Chưa có dữ liệu vị trí.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(16),
            ),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(room.latitude!, room.longitude!),
                initialZoom: 15.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.room_finder_app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(room.latitude!, room.longitude!),
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 38,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () async {
            final Uri uri = Uri.parse(
              'https://www.google.com/maps/search/?api=1&query=${room.latitude},${room.longitude}',
            );
            try {
              final bool launched = await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
              if (!launched && mounted) {
                AppSnackbar.error(context, 'Không thể mở bản đồ.');
              }
            } catch (e) {
              if (mounted) {
                AppSnackbar.error(context, 'Không thể mở bản đồ.');
              }
            }
          },
          icon: const Icon(Icons.open_in_new, size: 16),
          label: const Text(
            'Mở Google Maps',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  final RoomAvailability availability;

  const _AvailabilityBadge({required this.availability});

  @override
  Widget build(BuildContext context) {
    final bool isRented = availability == RoomAvailability.rented;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isRented ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: AppRadius.pillAll,
        border: Border.all(
          color: isRented ? Colors.red.shade200 : Colors.green.shade200,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            isRented ? Icons.lock : Icons.check_circle_outline,
            size: 16,
            color: isRented ? Colors.red.shade700 : Colors.green.shade700,
          ),
          const SizedBox(width: 6),
          Text(
            isRented ? 'Đã thuê' : 'Còn trống',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isRented ? Colors.red.shade700 : Colors.green.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
