import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/app_enums.dart';
import '../../providers/auth_provider.dart';
import '../../providers/conversation_provider.dart';
import '../../providers/role_provider.dart';
import '../../providers/room_provider.dart';
import '../../providers/notification_provider.dart';
import '../admin/admin_dashboard.dart';
import '../admin/manage_requests_screen.dart';
import '../admin/manage_rooms_screen.dart';
import '../chat/chat_list_screen.dart';
import '../home/home_screen.dart';
import '../landlord/my_rooms_screen.dart';
import '../landlord/landlord_dashboard.dart';
import '../profile/profile_screen.dart';
import '../saved/saved_screen.dart';
import '../search/search_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _index = 0;
  UserRole? _lastEffectiveRole;
  String? _lastUserId;

  @override
  void initState() {
    super.initState();
    final RoomProvider roomProvider = context.read<RoomProvider>();
    final ConversationProvider conversationProvider = context
        .read<ConversationProvider>();
    Future<void>.microtask(() async {
      await roomProvider.loadRoomsIfNeeded();
      await conversationProvider.loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final RoleProvider roleProvider = context.watch<RoleProvider>();

    if (auth.isAuthenticated && auth.userId != _lastUserId) {
      _lastUserId = auth.userId;
      final NotificationProvider notificationProvider = context
          .read<NotificationProvider>();
      Future<void>.microtask(
        () => notificationProvider.loadNotifications(auth.userId),
      );
    }

    final UserRole effectiveRole;
    if (auth.hasRole(UserRole.admin)) {
      effectiveRole = roleProvider.activeMode == ActiveUserMode.landlord
          ? UserRole.landlord
          : UserRole.user;
    } else {
      final UserRole requestedRole = roleProvider.currentMode;
      effectiveRole = auth.hasRole(requestedRole)
          ? requestedRole
          : UserRole.user;
    }

    if (_lastEffectiveRole != effectiveRole) {
      _lastEffectiveRole = effectiveRole;
      if (_index != 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _index = 0);
        });
      }
    }

    late final List<Widget> tabs;
    late final List<NavigationDestination> destinations;

    switch (effectiveRole) {
      case UserRole.admin:
        tabs = <Widget>[
          const AdminDashboard(),
          const ManageRequestsScreen(),
          const ManageRoomsScreen(),
          const ProfileScreen(),
        ];
        destinations = const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            label: 'Admin',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            label: 'Requests',
          ),
          NavigationDestination(
            icon: Icon(Icons.approval_outlined),
            label: 'Rooms',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ];
      case UserRole.landlord:
        tabs = <Widget>[
          const LandlordDashboard(),
          const MyRoomsScreen(),
          const ChatListScreen(),
          const ProfileScreen(),
        ];
        destinations = const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.home_work_outlined),
            label: 'My Rooms',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ];
      case UserRole.user:
        tabs = <Widget>[
          const HomeScreen(),
          const SearchScreen(),
          const SavedScreen(),
          const ChatListScreen(),
          const ProfileScreen(),
        ];
        destinations = const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ];
    }

    final int selectedIndex = _index >= tabs.length ? tabs.length - 1 : _index;

    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (int i) => setState(() => _index = i),
        destinations: destinations,
      ),
    );
  }
}
