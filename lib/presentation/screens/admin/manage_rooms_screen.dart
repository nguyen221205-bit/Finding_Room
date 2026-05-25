import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../domain/entities/app_enums.dart';
import '../../../domain/entities/room_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/role_provider.dart';
import '../../providers/room_provider.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_placeholder.dart';
import '../../widgets/status_badge.dart';

class ManageRoomsScreen extends StatefulWidget {
  const ManageRoomsScreen({super.key});

  @override
  State<ManageRoomsScreen> createState() => _ManageRoomsScreenState();
}

class _ManageRoomsScreenState extends State<ManageRoomsScreen> {
  String? _processingRoomId;

  Future<String?> _askRejectReason(BuildContext context) {
    final TextEditingController reasonController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Reject room listing'),
          content: TextField(
            controller: reasonController,
            maxLines: 3,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Reason',
              hintText: 'Explain why this room was rejected (e.g. details missing)',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(reasonController.text);
              },
              child: const Text('Reject'),
            ),
          ],
        );
      },
    ).whenComplete(reasonController.dispose);
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
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
      appBar: AppBar(title: const Text('Manage Rooms')),
      body: Consumer<RoomProvider>(
        builder: (BuildContext context, RoomProvider provider, _) {
          if (provider.isLoading && !provider.hasLoaded) {
            return Padding(
              padding: AppSpacing.paddingAllLg,
              child: const LoadingPlaceholderList(itemCount: 3),
            );
          }

          final List<RoomEntity> rooms = provider.rooms;
          if (rooms.isEmpty) {
            return const EmptyState(
              icon: Icons.home_outlined,
              title: 'No rooms found',
              message: 'Submitted room listings will appear here.',
            );
          }

          return ListView.separated(
            padding: AppSpacing.paddingAllLg,
            itemCount: rooms.length,
            separatorBuilder: (BuildContext context, int index) =>
                AppSpacing.vMd,
            itemBuilder: (BuildContext context, int index) {
              final RoomEntity room = rooms[index];
              final bool isProcessing = _processingRoomId == room.id;

              final StatusBadge badge = switch (room.status) {
                RoomStatus.pending => const StatusBadge.pending(),
                RoomStatus.approved => const StatusBadge.approved(),
                RoomStatus.rejected => const StatusBadge.rejected(),
              };

              return Card(
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
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          badge,
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Owner: ${room.ownerId}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (room.rejectionReason != null &&
                          room.rejectionReason!.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 6),
                        Text(
                          'Reason: ${room.rejectionReason!}',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (room.status == RoomStatus.pending) ...<Widget>[
                        AppSpacing.vMd,
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: FilledButton(
                                onPressed: isProcessing
                                    ? null
                                    : () async {
                                        final messenger = ScaffoldMessenger.of(context);
                                        final bool confirm = await AppDialogs.confirmApprove(
                                          context,
                                          "room listing: '${room.title}'",
                                        );
                                        if (!confirm || !mounted) return;

                                        setState(
                                          () => _processingRoomId = room.id,
                                        );
                                        final bool ok = provider.approveRoom(
                                          room.id,
                                        );
                                        if (mounted) {
                                          setState(
                                            () => _processingRoomId = null,
                                          );
                                          AppSnackbar.showWithMessenger(
                                            messenger,
                                            ok
                                                ? 'Room approved.'
                                                : 'Could not approve room.',
                                          );
                                        }
                                      },
                                child: isProcessing
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Approve'),
                              ),
                            ),
                            AppSpacing.hMd,
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isProcessing
                                    ? null
                                    : () async {
                                        final messenger = ScaffoldMessenger.of(context);
                                        final String? reason =
                                            await _askRejectReason(context);
                                        if (reason == null) return;

                                        if (!mounted) return;
                                        setState(
                                          () => _processingRoomId = room.id,
                                        );
                                        final bool ok = provider.rejectRoom(
                                          roomId: room.id,
                                          reason: reason,
                                        );
                                        if (mounted) {
                                          setState(
                                            () => _processingRoomId = null,
                                          );
                                          AppSnackbar.showWithMessenger(
                                            messenger,
                                            ok
                                                ? 'Room rejected.'
                                                : 'Could not reject room.',
                                          );
                                        }
                                      },
                                child: const Text('Reject'),
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
          );
        },
      ),
    );
  }
}
