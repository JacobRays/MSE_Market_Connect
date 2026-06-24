import 'package:flutter/material.dart';
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
      _version = '${info.version} (${info.buildNumber})';
      _loading = false;
    });
  }

  Future<void> _setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
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
