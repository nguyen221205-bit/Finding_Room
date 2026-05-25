import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.paddingAllLg,
          child: Card(
            child: Column(
              children: <Widget>[
                SwitchListTile(
                  value: _darkMode,
                  title: const Text('Dark mode (mock)'),
                  onChanged: (bool v) => setState(() => _darkMode = v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: _notifications,
                  title: const Text('Notifications (mock)'),
                  onChanged: (bool v) => setState(() => _notifications = v),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
