import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../appointment/viewing_appointments_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    final LandlordRequestProvider requestProvider = context
        .read<LandlordRequestProvider>();
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
    final LandlordRequestProvider requestProvider = context
        .read<LandlordRequestProvider>();

    final request = auth.userId.isEmpty
        ? null
        : requestProvider.getUserRequest(auth.userId);
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
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Chọn vai trò phù hợp với nhu cầu của bạn',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
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
                    AppSnackbar.success(
                      context,
                      'Đã chuyển sang vai trò Người thuê trọ',
                    );
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
                    final bool hasLandlordRole =
                        auth.hasRole(UserRole.landlord) ||
                        auth.hasRole(UserRole.admin);

                    if (hasLandlordRole) {
                      // CASE 1: Switch immediately
                      roleProvider.switchActiveMode(ActiveUserMode.landlord);
                      auth.updateActiveRole(UserRole.landlord);
                      Navigator.pop(context);
                      AppSnackbar.success(
                        context,
                        'Đã chuyển sang vai trò Chủ nhà trọ',
                      );
                    } else if (request == null) {
                      // CASE 2: Not created, go to verification
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const LandlordVerificationScreen(),
                        ),
                      );
                    } else if (request.status ==
                        LandlordRequestStatus.pending) {
                      // CASE 3: Pending state
                      Navigator.pop(context);
                      _showPendingDialog(context);
                    } else if (request.status ==
                        LandlordRequestStatus.rejected) {
                      // CASE 4: Rejected state, let them resubmit
                      Navigator.pop(context);
                      _showRejectedDialog(context, request.rejectionReason);
                    } else {
                      // fallback
                      auth.addRole(UserRole.landlord);
                      roleProvider.switchActiveMode(ActiveUserMode.landlord);
                      auth.updateActiveRole(UserRole.landlord);
                      Navigator.pop(context);
                      AppSnackbar.success(
                        context,
                        'Đã chuyển sang vai trò Chủ nhà trọ',
                      );
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
            color: isActive ? theme.colorScheme.primary : theme.dividerColor,
            width: isActive ? 2 : 1,
          ),
          color: isActive
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              backgroundColor: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              child: Icon(
                icon,
                color: isActive ? Colors.white : theme.hintColor,
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
                      color: isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isActive)
              Icon(Icons.check_circle, color: theme.colorScheme.primary),
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

  Widget _buildRoleSwitchCard(
    BuildContext context,
    ActiveUserMode activeMode,
    bool isAdmin,
  ) {
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
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Chế độ xem hoạt động',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
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

  Widget _buildRoleBadge(
    BuildContext context,
    ActiveUserMode activeMode,
    bool isAdmin,
  ) {
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

  String _getAccountCreatedDate(String userId) {
    try {
      if (userId.startsWith('u_admin_')) return '24/05/2026';
      if (userId.startsWith('u_landlord_')) return '24/05/2026';
      if (userId.startsWith('u_user_1')) return '25/05/2026';
      if (userId.startsWith('u_user_3')) return '25/05/2026';

      final List<String> parts = userId.split('_');
      if (parts.length >= 3) {
        final String tsStr = parts[1];
        final int? ts = int.tryParse(tsStr);
        if (ts != null) {
          final DateTime date = DateTime.fromMillisecondsSinceEpoch(ts);
          return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
        }
      }
      if (parts.length >= 2) {
        final String tsStr = parts[parts.length - 1];
        final int? ts = int.tryParse(tsStr);
        if (ts != null) {
          final DateTime date = DateTime.fromMicrosecondsSinceEpoch(ts);
          return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
        }
      }
    } catch (_) {}
    return '25/05/2026';
  }

  Widget _buildIdentityCard(BuildContext context, AuthProvider auth) {
    final theme = Theme.of(context);
    final LandlordRequestProvider requestProvider = context
        .watch<LandlordRequestProvider>();
    final request = auth.userId.isEmpty
        ? null
        : requestProvider.getUserRequest(auth.userId);

    // Determine verification status
    String statusText = 'Chưa xác thực';
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.help_outline;
    bool showVerifyBtn = true;

    if (auth.hasRole(UserRole.admin)) {
      statusText = 'Đã xác thực (Admin)';
      statusColor = Colors.purple;
      statusIcon = Icons.verified_user;
      showVerifyBtn = false;
    } else if (request == null) {
      if (auth.hasRole(UserRole.landlord)) {
        statusText = 'Đã xác thực';
        statusColor = Colors.green;
        statusIcon = Icons.verified;
        showVerifyBtn = false;
      } else {
        statusText = 'Chưa xác thực';
        statusColor = Colors.grey;
        statusIcon = Icons.info_outline;
        showVerifyBtn = true;
      }
    } else {
      switch (request.status) {
        case LandlordRequestStatus.pending:
          statusText = 'Đang chờ duyệt';
          statusColor = Colors.orange;
          statusIcon = Icons.hourglass_empty;
          showVerifyBtn = false;
          break;
        case LandlordRequestStatus.approved:
          statusText = 'Đã xác thực';
          statusColor = Colors.green;
          statusIcon = Icons.verified;
          showVerifyBtn = false;
          break;
        case LandlordRequestStatus.rejected:
          statusText = 'Bị từ chối';
          statusColor = Colors.red;
          statusIcon = Icons.cancel_outlined;
          showVerifyBtn = true;
          break;
      }
    }

    final createdDate = _getAccountCreatedDate(auth.userId);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Thông tin tài khoản & Định danh',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 0.8),

            // User Code
            if (auth.hasRole(UserRole.admin) &&
                auth.currentUser != null &&
                auth.currentUser!.userCode.isNotEmpty) ...[
              _buildIdentityRow(
                context,
                label: 'Mã người dùng',
                value: auth.currentUser!.userCode,
                trailing: IconButton(
                  icon: const Icon(Icons.copy, size: 16, color: Colors.blue),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  tooltip: 'Sao chép mã người dùng',
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: auth.currentUser!.userCode),
                    );
                    AppSnackbar.success(
                      context,
                      'Đã sao chép mã người dùng vào bộ nhớ tạm!',
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],

            // UID
            _buildIdentityRow(
              context,
              label: 'Mã định danh (UID)',
              value: auth.userId,
              trailing: IconButton(
                icon: const Icon(Icons.copy, size: 16, color: Colors.blue),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                tooltip: 'Sao chép UID',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: auth.userId));
                  AppSnackbar.success(
                    context,
                    'Đã sao chép mã định danh vào bộ nhớ tạm!',
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Email
            _buildIdentityRow(
              context,
              label: 'Email tài khoản',
              value: auth.email.isEmpty ? 'Chưa thiết lập' : auth.email,
            ),
            const SizedBox(height: 12),

            // Created At
            _buildIdentityRow(
              context,
              label: 'Ngày tham gia',
              value: createdDate,
            ),
            const SizedBox(height: 12),

            // Landlord Verification Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Xác minh Chủ trọ',
                    style: TextStyle(color: theme.hintColor, fontSize: 13),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 14, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (showVerifyBtn) ...[
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    const LandlordVerificationScreen(),
                              ),
                            );
                          },
                          child: Text(
                            request?.status == LandlordRequestStatus.rejected
                                ? 'Gửi lại yêu cầu xác minh →'
                                : 'Yêu cầu xác minh ngay →',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentityRow(
    BuildContext context, {
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13),
          ),
        ),
        Expanded(
          flex: 5,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing],
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final RoleProvider roleProvider = context.watch<RoleProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản'), elevation: 0),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.paddingAllLg,
          children: <Widget>[
            // 1. Role switching card at the very top
            _buildRoleSwitchCard(
              context,
              roleProvider.activeMode,
              roleProvider.isAdmin,
            ),
            const SizedBox(height: 24),

            // 2. Profile Header section
            Center(
              child: Column(
                children: <Widget>[
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    backgroundImage: () {
                      final String? path = user?.avatarPath;
                      if (path == null || path.isEmpty) return null;
                      if (path.startsWith('http')) {
                        return NetworkImage(path) as ImageProvider;
                      }
                      if (path.startsWith('assets/')) {
                        return AssetImage(path) as ImageProvider;
                      }
                      if (!kIsWeb) {
                        return FileImage(File(path)) as ImageProvider;
                      }
                      return null;
                    }(),
                    child: user?.avatarPath == null || user!.avatarPath!.isEmpty
                        ? Text(
                            auth.username.isNotEmpty
                                ? auth.username[0].toUpperCase()
                                : 'U',
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    auth.username,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (auth.hasRole(UserRole.admin) &&
                      user != null &&
                      user.userCode.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.userCode,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _buildRoleBadge(
                    context,
                    roleProvider.activeMode,
                    roleProvider.isAdmin,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // 2.5 Identity & Verification Card
            _buildIdentityCard(context, auth),
            const SizedBox(height: 24),

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
                    leading: const Icon(
                      Icons.calendar_month_outlined,
                      color: Colors.orange,
                    ),
                    title: const Text('Lịch xem phòng'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ViewingAppointmentsScreen(),
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
                      leading: const Icon(
                        Icons.admin_panel_settings_outlined,
                        color: Colors.purple,
                      ),
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
