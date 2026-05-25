import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../domain/entities/app_enums.dart';
import '../../providers/auth_provider.dart';
import '../../providers/role_provider.dart';
import '../../providers/room_provider.dart';
import '../../widgets/count_tile.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';
import 'add_room_screen.dart';
import 'my_rooms_screen.dart';

class LandlordDashboard extends StatelessWidget {
  const LandlordDashboard({super.key});

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
            title: 'Landlord mode is unavailable',
            message: 'Switch to landlord mode after your request is approved.',
          ),
        ),
      );
    }

    final RoomProvider roomProvider = context.watch<RoomProvider>();
    final pendingCount = roomProvider
        .roomsForOwnerByStatus(auth.userId, RoomStatus.pending)
        .length;
    final approvedCount = roomProvider
        .roomsForOwnerByStatus(auth.userId, RoomStatus.approved)
        .length;
    final rejectedCount = roomProvider
        .roomsForOwnerByStatus(auth.userId, RoomStatus.rejected)
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Landlord Dashboard')),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.paddingAllLg,
          children: <Widget>[
            Card(
              child: Padding(
                padding: AppSpacing.paddingAllLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SectionHeader(title: 'My listing overview'),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: CountTile(
                            label: 'Pending',
                            count: pendingCount,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CountTile(
                            label: 'Approved',
                            count: approvedCount,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CountTile(
                            label: 'Rejected',
                            count: rejectedCount,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.vMd,
            Card(
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.home_work_outlined),
                    title: const Text('My Rooms'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const MyRoomsScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.add_business_outlined),
                    title: const Text('Add Room'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AddRoomScreen(),
                        ),
                      );
                    },
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
