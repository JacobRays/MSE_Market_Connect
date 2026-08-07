import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/theme/app_theme.dart';
import 'package:mse_market_connect/core/theme/theme_mode_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _priceAlerts = true;
  bool _emailNotifications = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _sectionHeader(context, 'Appearance'),
          _tile(
            icon: Icons.brightness_6,
            title: 'Theme Mode',
            subtitle: 'Switch between light, dark, or system',
            onTap: () => _showThemeDialog(context),
            trailing: Text(
              _currentThemeLabel(),
              style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
            ),
          ),
          const Divider(),
          _sectionHeader(context, 'Notifications'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive alerts and updates'),
            value: _pushNotifications,
            onChanged: (v) => setState(() => _pushNotifications = v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.trending_up),
            title: const Text('Price Alerts'),
            subtitle: const Text('Get notified when target price is hit'),
            value: _priceAlerts,
            onChanged: (v) => setState(() => _priceAlerts = v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.email),
            title: const Text('Email Notifications'),
            subtitle: const Text('Send updates to your email'),
            value: _emailNotifications,
            onChanged: (v) => setState(() => _emailNotifications = v),
          ),
          const Divider(),
          _sectionHeader(context, 'Data & Storage'),
          _tile(
            icon: Icons.delete_sweep,
            title: 'Clear Cache',
            subtitle: 'Free up space',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared')),
              );
            },
          ),
          _tile(
            icon: Icons.delete,
            title: 'Clear All Notifications',
            subtitle: 'Remove notification history',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications cleared')),
              );
            },
          ),
          const Divider(),
          _sectionHeader(context, 'About'),
          _tile(
            icon: Icons.info_outline,
            title: 'Version',
            subtitle: '1.0.0',
            trailing: const SizedBox.shrink(),
          ),
          _tile(
            icon: Icons.policy,
            title: 'Privacy Policy',
            onTap: () { /* open URL */ },
          ),
          _tile(
            icon: Icons.gavel,
            title: 'Terms of Service',
            onTap: () { /* open URL */ },
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('System'),
              value: ThemeMode.system,
              groupValue: ThemeModeController.themeMode.value,
              onChanged: (v) {
                ThemeModeController.themeMode.value = v!;
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: ThemeModeController.themeMode.value,
              onChanged: (v) {
                ThemeModeController.themeMode.value = v!;
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: ThemeModeController.themeMode.value,
              onChanged: (v) {
                ThemeModeController.themeMode.value = v!;
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _currentThemeLabel() {
    switch (ThemeModeController.themeMode.value) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }
}
