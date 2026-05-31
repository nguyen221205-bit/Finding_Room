import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_spacing.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: SafeArea(
        child: Consumer<SettingsProvider>(
          builder:
              (BuildContext context, SettingsProvider settingsProvider, _) {
                final prefs = settingsProvider.notificationPreferences;

                return ListView(
                  padding: AppSpacing.paddingAllLg,
                  children: <Widget>[
                    // 1. Theme Section
                    _buildSectionHeader(context, 'Giao diện'),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.1),
                        ),
                      ),
                      child: SwitchListTile(
                        value: settingsProvider.isDarkMode,
                        title: const Text('Chế độ tối (Dark Mode)'),
                        subtitle: const Text(
                          'Chuyển đổi giao diện sáng/tối toàn ứng dụng',
                        ),
                        secondary: const Icon(Icons.dark_mode_outlined),
                        onChanged: (bool value) {
                          settingsProvider.toggleDarkMode(value);
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 2. Notifications Section
                    _buildSectionHeader(context, 'Cấu hình thông báo'),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        children: <Widget>[
                          SwitchListTile(
                            value: prefs.verificationNotificationsEnabled,
                            title: const Text('Thông báo xác minh danh tính'),
                            subtitle: const Text(
                              'Thông báo trạng thái duyệt chủ trọ',
                            ),
                            secondary: const Icon(Icons.verified_user_outlined),
                            onChanged: (bool value) {
                              settingsProvider.toggleVerificationNotifications(
                                value,
                              );
                            },
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            value: prefs.roomApprovalNotificationsEnabled,
                            title: const Text('Thông báo duyệt phòng trọ'),
                            subtitle: const Text(
                              'Thông báo duyệt/từ chối đăng tin phòng',
                            ),
                            secondary: const Icon(Icons.home_work_outlined),
                            onChanged: (bool value) {
                              settingsProvider.toggleRoomApprovalNotifications(
                                value,
                              );
                            },
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            value: prefs.appointmentNotificationsEnabled,
                            title: const Text('Thông báo lịch hẹn xem phòng'),
                            subtitle: const Text(
                              'Thông báo đặt hẹn, duyệt/từ chối hẹn',
                            ),
                            secondary: const Icon(
                              Icons.calendar_month_outlined,
                            ),
                            onChanged: (bool value) {
                              settingsProvider.toggleAppointmentNotifications(
                                value,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.grey[600],
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
