import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/theme/theme_mode_controller.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _kHideBalances = 'hide_balances';
  static const _kNewsAutoRefresh = 'news_auto_refresh';

  bool _loading = true;
  bool _hideBalances = false;
  bool _newsAutoRefresh = true;

  ThemeMode _mode = ThemeMode.system;

  String _version = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final info = await PackageInfo.fromPlatform();

    setState(() {
      _hideBalances = prefs.getBool(_kHideBalances) ?? false;
      _newsAutoRefresh = prefs.getBool(_kNewsAutoRefresh) ?? true;
      _mode = ThemeModeController.themeMode.value;
      _version = '${info.version} (${info.buildNumber})';
      _loading = false;
    });
  }

  Future<void> _setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  String _modeLabel(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
      default:
        return 'System';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const SizedBox(height: 6),
                ListTile(
                  leading: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Theme'),
                  subtitle: Text(_modeLabel(_mode)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final selected = await showModalBottomSheet<ThemeMode>(
                      context: context,
                      showDragHandle: true,
                      builder: (_) {
                        return SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              RadioListTile(
                                title: const Text('System'),
                                value: ThemeMode.system,
                                groupValue: _mode,
                                onChanged: (v) => Navigator.pop(context, v),
                              ),
                              RadioListTile(
                                title: const Text('Light'),
                                value: ThemeMode.light,
                                groupValue: _mode,
                                onChanged: (v) => Navigator.pop(context, v),
                              ),
                              RadioListTile(
                                title: const Text('Dark'),
                                value: ThemeMode.dark,
                                groupValue: _mode,
                                onChanged: (v) => Navigator.pop(context, v),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        );
                      },
                    );

                    if (selected == null) return;
                    setState(() => _mode = selected);
                    await ThemeModeController.setThemeMode(selected);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Hide balances'),
                  subtitle: const Text('Hide portfolio values on screens'),
                  value: _hideBalances,
                  onChanged: (v) async {
                    setState(() => _hideBalances = v);
                    await _setBool(_kHideBalances, v);
                  },
                ),
                SwitchListTile(
                  title: const Text('Auto-refresh news'),
                  subtitle: const Text('Refresh news periodically'),
                  value: _newsAutoRefresh,
                  onChanged: (v) async {
                    setState(() => _newsAutoRefresh = v);
                    await _setBool(_kNewsAutoRefresh, v);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('App version'),
                  subtitle: Text(_version),
                ),
              ],
            ),
    );
  }
}
