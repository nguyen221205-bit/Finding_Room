import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../domain/entities/app_enums.dart';
import '../../providers/auth_provider.dart';
import '../../providers/landlord_request_provider.dart';
import '../../providers/room_provider.dart';
import '../../widgets/count_tile.dart';
import '../../widgets/empty_state.dart';
import 'manage_requests_screen.dart';
import 'manage_rooms_screen.dart';
import 'landlord_management_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    final LandlordRequestProvider requestProvider = context
        .read<LandlordRequestProvider>();
    Future<void>.microtask(() => requestProvider.loadRequestsIfNeeded());
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
            title: 'Admin mode is unavailable',
          ),
        ),
      );
    }

    final requestProvider = context.watch<LandlordRequestProvider>();
    final roomProvider = context.watch<RoomProvider>();
    final int pendingRequests = requestProvider.pendingRequests.length;
    final int pendingRooms = roomProvider.rooms
        .where((room) => room.status == RoomStatus.pending)
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.paddingAllLg,
          children: <Widget>[
            Card(
              child: Padding(
                padding: AppSpacing.paddingAllLg,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: CountTile(
                        label: 'Pending requests',
                        count: pendingRequests,
                      ),
                    ),
                    AppSpacing.hMd,
                    Expanded(
                      child: CountTile(
                        label: 'Pending rooms',
                        count: pendingRooms,
                      ),
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
                    leading: const Icon(Icons.assignment_outlined),
                    title: const Text('Manage Requests'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ManageRequestsScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.approval_outlined),
                    title: const Text('Manage Rooms'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ManageRoomsScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.people_outline,
                      color: Colors.blue,
                    ),
                    title: const Text('Quản lý chủ nhà'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const LandlordManagementScreen(),
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
