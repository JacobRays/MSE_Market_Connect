import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/admin_notification_service.dart';
import 'package:mse_market_connect/core/services/notification_service.dart';
import 'package:mse_market_connect/core/theme/app_theme.dart';
import 'package:mse_market_connect/shared/models/notification_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notifService = NotificationService();
  final AdminNotificationService _adminService = AdminNotificationService();
  bool _isAdmin = false;
  late Future<List<AppNotificationModel>> _userNotifications;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final profile = await Supabase.instance.client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();
    final admin = (profile?['role'] ?? '') == 'admin';
    if (!mounted) return;
    setState(() {
      _isAdmin = admin;
      _userNotifications = _notifService.getMyNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isAdmin ? 'Admin Panel' : 'Notifications')),
      body: _isAdmin ? _AdminPanel() : _UserNotifications(notifications: _userNotifications),
    );
  }
}

class _UserNotifications extends StatelessWidget {
  final Future<List<AppNotificationModel>> notifications;
  const _UserNotifications({required this.notifications});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AppNotificationModel>>(
      future: notifications,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snap.hasError)
          return Center(child: Text('Error: ${snap.error}'));
        final list = snap.data ?? [];
        if (list.isEmpty)
          return const Center(child: Text('No notifications yet'));
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) => ListTile(
            title: Text(list[i].title),
            subtitle: Text(list[i].body),
          ),
        );
      },
    );
  }
}

class _AdminPanel extends StatefulWidget {
  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<_AdminPanel> {
  final AdminNotificationService _admin = AdminNotificationService();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _bodyCtrl = TextEditingController();
  late Future<List<Map<String, dynamic>>> _pendingKyc;

  @override
  void initState() {
    super.initState();
    _pendingKyc = _admin.getPendingKyc();
  }

  Future<void> _sendNotification() async {
    await _admin.sendToAll(_titleCtrl.text, _bodyCtrl.text);
    _titleCtrl.clear();
    _bodyCtrl.clear();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Notification sent!')));
  }

  Future<void> _refreshKyc() => setState(() => _pendingKyc = _admin.getPendingKyc());

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Send Notification'),
              Tab(text: 'KYC Approvals'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Send Notification tab
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
                      const SizedBox(height: 12),
                      TextField(controller: _bodyCtrl, decoration: const InputDecoration(labelText: 'Body'), maxLines: 4),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _sendNotification,
                        child: const Text('Send to All Users'),
                      ),
                    ],
                  ),
                ),
                // KYC Approvals tab
                RefreshIndicator(
                  onRefresh: _refreshKyc,
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _pendingKyc,
                    builder: (ctx, snap) {
                      if (snap.connectionState == ConnectionState.waiting)
                        return const Center(child: CircularProgressIndicator());
                      if (snap.hasError)
                        return Center(child: Text('Error: ${snap.error}'));
                      final list = snap.data ?? [];
                      if (list.isEmpty)
                        return const Center(child: Text('No pending verifications'));
                      return ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (_, i) {
                          final item = list[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: ListTile(
                              title: Text(item['full_name'] ?? ''),
                              subtitle: Text(item['email'] ?? ''),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check, color: AppTheme.gainColor),
                                    onPressed: () async {
                                      await _admin.approveKyc(item['id']);
                                      _refreshKyc();
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: AppTheme.lossColor),
                                    onPressed: () async {
                                      await _admin.rejectKyc(item['id']);
                                      _refreshKyc();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
