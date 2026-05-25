import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../domain/entities/app_enums.dart';
import '../../../domain/entities/room_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/role_provider.dart';
import '../../providers/room_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_placeholder.dart';
import '../../widgets/room_card.dart';
import '../room/room_detail_screen.dart';

class MyRoomsScreen extends StatelessWidget {
  const MyRoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final bool canAccess =
        auth.hasRole(UserRole.landlord) &&
        context.watch<RoleProvider>().currentMode == UserRole.landlord;

    if (!canAccess) {
      return const Scaffold(
        body: SafeArea(
          child: EmptyState(
            icon: Icons.lock_outline,
            title: 'Access Denied',
            message: 'Only landlords can view their rooms in landlord mode.',
          ),
        ),
      );
    }

    final String ownerId = auth.userId;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Rooms'),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(text: 'Pending'),
              Tab(text: 'Approved'),
              Tab(text: 'Rejected'),
            ],
          ),
        ),
        body: Consumer<RoomProvider>(
          builder: (BuildContext context, RoomProvider roomProvider, _) {
            if (roomProvider.isLoading && !roomProvider.hasLoaded) {
              return Padding(
                padding: AppSpacing.paddingAllLg,
                child: const LoadingPlaceholderList(itemCount: 3),
              );
            }

            return TabBarView(
              children: <Widget>[
                _StatusRoomList(
                  rooms: roomProvider.roomsForOwnerByStatus(
                    ownerId,
                    RoomStatus.pending,
                  ),
                ),
                _StatusRoomList(
                  rooms: roomProvider.roomsForOwnerByStatus(
                    ownerId,
                    RoomStatus.approved,
                  ),
                ),
                _StatusRoomList(
                  rooms: roomProvider.roomsForOwnerByStatus(
                    ownerId,
                    RoomStatus.rejected,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatusRoomList extends StatelessWidget {
  final List<RoomEntity> rooms;

  const _StatusRoomList({required this.rooms});

  @override
  Widget build(BuildContext context) {
    if (rooms.isEmpty) {
      return const EmptyState(
        icon: Icons.inbox_outlined,
        title: 'No rooms in this status',
        message: 'Your room listings for this status will show up here.',
      );
    }

    return ListView.separated(
      padding: AppSpacing.paddingAllLg,
      itemCount: rooms.length,
      separatorBuilder: (BuildContext context, int index) => AppSpacing.vMd,
      itemBuilder: (BuildContext context, int index) {
        final room = rooms[index];
        return Column(
          children: <Widget>[
            RoomCard(
              room: room,
              onToggleFavorite: () {},
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RoomDetailScreen(roomId: room.id),
                  ),
                );
              },
            ),
            if (room.status == RoomStatus.rejected &&
                room.rejectionReason != null &&
                room.rejectionReason!.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                padding: AppSpacing.paddingAllMd,
                decoration: BoxDecoration(
                  color: AppColors.errorTint,
                  borderRadius: AppRadius.mediumAll,
                ),
                child: Text(
                  'Reason: ${room.rejectionReason!}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        );
      },
    );
  }
}
