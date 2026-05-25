import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../domain/entities/app_enums.dart';
import '../../providers/auth_provider.dart';
import '../../providers/landlord_request_provider.dart';
import '../../providers/role_provider.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/app_snackbar.dart';
import '../admin/admin_dashboard.dart';
import 'landlord_verification_screen.dart';
import 'personal_info_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    final LandlordRequestProvider requestProvider =
        context.read<LandlordRequestProvider>();
    Future<void>.microtask(() => requestProvider.loadRequestsIfNeeded());
  }

  Future<void> _handleLogout() async {
    final bool confirmed = await AppDialogs.confirmLogout(context);
    if (!confirmed || !mounted) return;

    context.read<AuthProvider>().logout();
    Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst);
  }

  void _showRoleSwitchSheet(BuildContext context) {
    final AuthProvider auth = context.read<AuthProvider>();
    final RoleProvider roleProvider = context.read<RoleProvider>();
    final LandlordRequestProvider requestProvider = context.read<LandlordRequestProvider>();
    
    final request = auth.userId.isEmpty ? null : requestProvider.getUserRequest(auth.userId);
    final ActiveUserMode activeMode = roleProvider.activeMode;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Chuyển đổi vai trò',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Chọn vai trò phù hợp với nhu cầu của bạn',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                
                // Renter (Người thuê trọ)
                _buildRoleOption(
                  context: context,
                  title: 'Người thuê trọ',
                  subtitle: 'Tìm kiếm và liên hệ phòng trọ',
                  icon: Icons.search,
                  isActive: activeMode == ActiveUserMode.renter,
                  onTap: () {
                    roleProvider.switchActiveMode(ActiveUserMode.renter);
                    auth.updateActiveRole(UserRole.user);
                    Navigator.pop(context);
                    AppSnackbar.success(context, 'Đã chuyển sang vai trò Người thuê trọ');
                  },
                ),
                const SizedBox(height: 12),
                
                // Landlord (Chủ nhà trọ)
                _buildRoleOption(
                  context: context,
                  title: 'Chủ nhà trọ',
                  subtitle: 'Đăng và quản lý phòng cho thuê',
                  icon: Icons.home_work_outlined,
                  isActive: activeMode == ActiveUserMode.landlord,
                  onTap: () {
                    // Admin inherently has landlord privileges, otherwise check hasRole
                    final bool hasLandlordRole = auth.hasRole(UserRole.landlord) || auth.hasRole(UserRole.admin);
                    
                    if (hasLandlordRole) {
                      // CASE 1: Switch immediately
                      roleProvider.switchActiveMode(ActiveUserMode.landlord);
                      auth.updateActiveRole(UserRole.landlord);
                      Navigator.pop(context);
                      AppSnackbar.success(context, 'Đã chuyển sang vai trò Chủ nhà trọ');
                    } else if (request == null) {
                      // CASE 2: Not created, go to verification
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const LandlordVerificationScreen(),
                        ),
                      );
                    } else if (request.status == LandlordRequestStatus.pending) {
                      // CASE 3: Pending state
                      Navigator.pop(context);
                      _showPendingDialog(context);
                    } else if (request.status == LandlordRequestStatus.rejected) {
                      // CASE 4: Rejected state, let them resubmit
                      Navigator.pop(context);
                      _showRejectedDialog(context, request.rejectionReason);
                    } else {
                      // fallback
                      auth.addRole(UserRole.landlord);
                      roleProvider.switchActiveMode(ActiveUserMode.landlord);
                      auth.updateActiveRole(UserRole.landlord);
                      Navigator.pop(context);
                      AppSnackbar.success(context, 'Đã chuyển sang vai trò Chủ nhà trọ');
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? theme.colorScheme.primary : Colors.grey[300]!,
            width: isActive ? 2 : 1,
          ),
          color: isActive ? theme.colorScheme.primaryContainer.withValues(alpha: 0.1) : Colors.transparent,
        ),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              backgroundColor: isActive ? theme.colorScheme.primary : Colors.grey[100],
              child: Icon(
                icon,
                color: isActive ? Colors.white : Colors.grey[600],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isActive ? theme.colorScheme.primary : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (isActive)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  void _showPendingDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.hourglass_empty, color: Colors.orange),
            SizedBox(width: 8),
            Text('Đang chờ duyệt'),
          ],
        ),
        content: const Text(
          'Yêu cầu đăng ký làm chủ nhà trọ của bạn đang được kiểm duyệt. Hệ thống sẽ thông báo ngay khi có kết quả từ quản trị viên.',
          style: TextStyle(height: 1.4),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showRejectedDialog(BuildContext context, String? reason) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.red),
            SizedBox(width: 8),
            Text('Yêu cầu bị từ chối'),
          ],
        ),
        content: Text(
          'Yêu cầu xác minh của bạn đã bị từ chối.\nLý do: ${reason ?? "Không rõ lý do"}.\n\nBạn có muốn gửi lại yêu cầu xác minh không?',
          style: const TextStyle(height: 1.4),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const LandlordVerificationScreen(),
                ),
              );
            },
            child: const Text('Gửi lại yêu cầu'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSwitchCard(BuildContext context, ActiveUserMode activeMode, bool isAdmin) {
    final theme = Theme.of(context);
    String roleName = '';
    IconData icon = Icons.person;

    if (activeMode == ActiveUserMode.landlord) {
      roleName = isAdmin ? 'Chủ nhà trọ (Admin)' : 'Chủ nhà trọ';
      icon = Icons.home_work_outlined;
    } else {
      roleName = isAdmin ? 'Người thuê trọ (Admin)' : 'Người thuê trọ';
      icon = isAdmin ? Icons.admin_panel_settings_outlined : Icons.search;
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Chế độ xem hoạt động',
                    style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    roleName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _showRoleSwitchSheet(context),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Chuyển đổi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(BuildContext context, ActiveUserMode activeMode, bool isAdmin) {
    String label = '';
    Color color = Colors.grey;
    IconData icon = Icons.person;

    if (activeMode == ActiveUserMode.landlord) {
      label = isAdmin ? 'Chủ nhà (Admin)' : 'Chủ nhà trọ';
      color = Colors.green;
      icon = Icons.home_work_outlined;
    } else {
      label = isAdmin ? 'Người thuê (Admin)' : 'Người thuê trọ';
      color = isAdmin ? Colors.purple : Colors.blue;
      icon = isAdmin ? Icons.admin_panel_settings_outlined : Icons.search;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final RoleProvider roleProvider = context.watch<RoleProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản'),
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.paddingAllLg,
          children: <Widget>[
            // 1. Role switching card at the very top
            _buildRoleSwitchCard(context, roleProvider.activeMode, roleProvider.isAdmin),
            const SizedBox(height: 24),

            // 2. Profile Header section
            Center(
              child: Column(
                children: <Widget>[
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    backgroundImage: user?.avatarPath != null && user!.avatarPath!.isNotEmpty
                        ? FileImage(File(user.avatarPath!))
                        : null,
                    child: user?.avatarPath == null || user!.avatarPath!.isEmpty
                        ? Text(
                            auth.username.isNotEmpty ? auth.username[0].toUpperCase() : 'U',
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    auth.username,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildRoleBadge(context, roleProvider.activeMode, roleProvider.isAdmin),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PersonalInfoScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Chỉnh sửa thông tin'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // 3. Operations Menu List
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.badge_outlined),
                    title: const Text('Thông tin cá nhân'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PersonalInfoScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Thiết lập'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  if (auth.hasRole(UserRole.admin)) ...<Widget>[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.admin_panel_settings_outlined, color: Colors.purple),
                      title: const Text(
                        'Quản trị hệ thống',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Đến bảng điều khiển quản trị viên',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AdminDashboard(),
                          ),
                        );
                      },
                    ),
                  ],
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text(
                      'Đăng xuất',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                    onTap: _handleLogout,
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

