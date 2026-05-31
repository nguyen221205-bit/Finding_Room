import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../domain/entities/app_enums.dart';
import '../../../domain/entities/room_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/room_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_placeholder.dart';
import '../../widgets/status_badge.dart';
import 'room_review_detail_screen.dart';

class ManageRoomsScreen extends StatefulWidget {
  const ManageRoomsScreen({super.key});

  @override
  State<ManageRoomsScreen> createState() => _ManageRoomsScreenState();
}

class _ManageRoomsScreenState extends State<ManageRoomsScreen> {
  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final bool canAccess = auth.hasRole(UserRole.admin);
    if (!canAccess) {
      return const Scaffold(
        body: SafeArea(
          child: EmptyState(
            icon: Icons.lock_outline,
            title: 'Access Denied',
            message: 'Only admins can manage rooms in admin mode.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiểm duyệt phòng trọ'),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: Consumer<RoomProvider>(
        builder: (BuildContext context, RoomProvider provider, Widget? child) {
          if (provider.isLoading && provider.rooms.isEmpty) {
            return const Padding(
              padding: AppSpacing.paddingAllLg,
              child: LoadingPlaceholderList(itemCount: 3),
            );
          }

          final List<RoomEntity> rooms = provider.rooms;
          if (rooms.isEmpty) {
            return const EmptyState(
              icon: Icons.home_outlined,
              title: 'Không tìm thấy phòng nào',
              message: 'Các tin đăng phòng trọ chờ duyệt sẽ xuất hiện ở đây.',
            );
          }

          return ListView.separated(
            padding: AppSpacing.paddingAllLg,
            itemCount: rooms.length,
            separatorBuilder: (BuildContext context, int index) =>
                AppSpacing.vMd,
            itemBuilder: (BuildContext context, int index) {
              final RoomEntity room = rooms[index];

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
                RoomStatus.hiddenByAdmin => const StatusBadge.rejected(
                  label: 'Đã ẩn',
                ),
              };

              return Card(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                elevation: 0,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) =>
                            AdminRoomDetailScreenV2(roomId: room.id),
                      ),
                    );
                  },
                  child: Padding(
                    padding: AppSpacing.paddingAllLg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                room.title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            badge,
                          ],
                        ),
                        if (room.roomCode.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.tag,
                                size: 14,
                                color: Colors.blue.shade700,
                              ),
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
                        const SizedBox(height: 8),
                        FutureBuilder<UserEntity?>(
                          future: context.read<AuthProvider>().getUserById(
                            room.ownerId,
                          ),
                          builder: (context, snapshot) {
                            final user = snapshot.data;
                            final displayOwner =
                                user != null && user.userCode.isNotEmpty
                                ? 'Chủ nhà: ${user.username} (${user.userCode})'
                                : 'Chủ nhà: ${room.landlordName}';
                            return Row(
                              children: [
                                const Icon(
                                  Icons.person_outline,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    displayOwner,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        if (room.rejectionReason != null &&
                            room.rejectionReason!.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Lý do từ chối: ${room.rejectionReason!}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Xem chi tiết & duyệt',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
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
