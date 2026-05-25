import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/launchers.dart';
import '../../../domain/entities/app_enums.dart';
import '../../../domain/entities/room_entity.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/room_provider.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/app_image.dart';
import '../../widgets/section_header.dart';
import '../chat/chat_detail_screen.dart';

class RoomDetailScreen extends StatefulWidget {
  final String roomId;

  const RoomDetailScreen({super.key, required this.roomId});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  int _imageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final RoomEntity? room = context.select<RoomProvider, RoomEntity?>(
      (RoomProvider p) => p.byId(widget.roomId),
    );

    if (room == null) {
      return const Scaffold(
        body: SafeArea(
          child: EmptyState(icon: Icons.home_outlined, title: 'Room not found'),
        ),
      );
    }
    final List<String> imageUrls = room.imageUrls.isEmpty
        ? <String>[room.primaryImageUrl]
        : room.imageUrls;
    final int safeImageIndex = _imageIndex.clamp(0, imageUrls.length - 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Room details'),
        actions: <Widget>[
          IconButton(
            onPressed: () => context.read<RoomProvider>().toggleFavorite(room.id),
            icon: Icon(
              room.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: room.isFavorite
                  ? Theme.of(context).colorScheme.secondary
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.paddingAllLg,
          children: <Widget>[
            Hero(
              tag: 'room_image_${room.id}',
              child: ClipRRect(
                borderRadius: AppRadius.largeAll,
                child: SizedBox(
                  height: 220,
                  child: Stack(
                    children: <Widget>[
                      PageView.builder(
                        onPageChanged: (int i) => setState(() => _imageIndex = i),
                        itemCount: imageUrls.length,
                        itemBuilder: (BuildContext context, int i) {
                          return AppImage(imagePath: imageUrls[i]);
                        },
                      ),
                      Positioned(
                        right: AppSpacing.md,
                        bottom: AppSpacing.md,
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: AppRadius.pillAll,
                            ),
                            child: Text(
                              '${safeImageIndex + 1}/${imageUrls.length}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  Formatters.pricePerMonth(room.price),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                _AvailabilityBadge(availability: room.availability),
              ],
            ),
            AppSpacing.vXs,
            Text(room.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                const Icon(Icons.location_on_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    room.address,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            if (room.ownerId == context.select<AuthProvider, String>((AuthProvider p) => p.userId)) ...<Widget>[
              AppSpacing.vMd,
              Card(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.largeAll,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: AppSpacing.paddingAllLg,
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
                            items: RoomAvailability.values.map((RoomAvailability a) {
                              return DropdownMenuItem<RoomAvailability>(
                                value: a,
                                child: Text(a == RoomAvailability.available ? 'Còn trống' : 'Đã thuê'),
                              );
                            }).toList(),
                            onChanged: (RoomAvailability? val) {
                              if (val != null) {
                                final bool ok = context.read<RoomProvider>().updateAvailability(room.id, val);
                                if (ok) {
                                  AppSnackbar.success(context, 'Cập nhật trạng thái phòng thành công!');
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            AppSpacing.vLg,
            Card(
              child: Padding(
                padding: AppSpacing.paddingAllLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SectionHeader(title: 'Chi tiết'),
                    _detailRow('Diện tích', '${room.area.toStringAsFixed(0)} m²'),
                    _detailRow('Sức chứa', '${room.capacity} người'),
                    _detailRow('Nội thất', room.furniture),
                  ],
                ),
              ),
            ),
            AppSpacing.vMd,
            Card(
              child: Padding(
                padding: AppSpacing.paddingAllLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SectionHeader(title: 'Mô tả'),
                    Text(room.description),
                  ],
                ),
              ),
            ),
            AppSpacing.vMd,
            Card(
              child: Padding(
                padding: AppSpacing.paddingAllLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SectionHeader(title: 'Tiện ích'),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: room.amenities
                          .map(
                            (String a) => Chip(
                              label: Text(a),
                              backgroundColor: AppColors.shimmerHighlight,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.vMd,
            Card(
              child: Padding(
                padding: AppSpacing.paddingAllLg,
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 22,
                      child: ClipOval(
                        child: AppImage(
                          imagePath: room.landlordAvatarUrl,
                          width: 44,
                          height: 44,
                        ),
                      ),
                    ),
                    AppSpacing.hMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            room.landlordName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            room.landlordPhone,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      final String threadId = context
                          .read<ChatProvider>()
                          .ensureThreadForLandlord(
                            roomId: room.id,
                            userId: context.read<AuthProvider>().userId,
                            landlordId: room.ownerId,
                            landlordName: room.landlordName,
                            landlordAvatarUrl: room.landlordAvatarUrl,
                            landlordPhone: room.landlordPhone,
                          );
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ChatDetailScreen(threadId: threadId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Chat'),
                  ),
                ),
                AppSpacing.hMd,
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final bool ok = await Launchers.callPhone(
                        room.landlordPhone,
                      );
                      if (!context.mounted) return;
                      if (!ok) {
                        AppSnackbar.error(context, 'Could not open dialer.');
                      }
                    },
                    icon: const Icon(Icons.call),
                    label: const Text('Call'),
                  ),
                ),
              ],
            ),
            AppSpacing.vXxl,
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
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
