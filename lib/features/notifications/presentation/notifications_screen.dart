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
  late Future<List<NotificationModel>> _userNotifications;

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
      if (!admin) {
        _userNotifications = _notifService.getMyNotifications();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isAdmin ? 'Admin Panel' : 'Notifications')),
      body: _isAdmin ? const _AdminPanel() : _UserNotifications(notifications: _userNotifications),
    );
  }
}

// ─── User Notifications View ──────────────────────────────
class _UserNotifications extends StatelessWidget {
  final Future<List<NotificationModel>> notifications;
  const _UserNotifications({required this.notifications});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NotificationModel>>(
      future: notifications,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return const Center(child: Text('No notifications yet'));
        }
        return ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final n = list[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                child: const Icon(Icons.campaign, color: AppTheme.primaryColor, size: 22),
              ),
              title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: Text(
                _formatDate(n.createdAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            );
          },
        );
      },
    );
  }

  static String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${d.day}/${d.month}/${d.year}';
  }
}

// ─── Admin Panel (Tabs) ────────────────────────────────────
class _AdminPanel extends StatefulWidget {
  const _AdminPanel();

  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<_AdminPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminNotificationService _admin = AdminNotificationService();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _bodyCtrl = TextEditingController();
  late Future<List<Map<String, dynamic>>> _pendingKyc;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pendingKyc = _admin.getPendingKyc();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    await _admin.sendToAll(_titleCtrl.text, _bodyCtrl.text);
    _titleCtrl.clear();
    _bodyCtrl.clear();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Notification sent!')));
  }

  Future<void> _refreshKyc() async {
    setState(() {
      _pendingKyc = _admin.getPendingKyc();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Send Notification'),
              Tab(text: 'KYC Approvals'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Send Notification
              Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _bodyCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Message',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _sendNotification,
                          icon: const Icon(Icons.send),
                          label: const Text('Send to All Users'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Tab 2: KYC Approvals
              RefreshIndicator(
                onRefresh: _refreshKyc,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _pendingKyc,
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(child: Text('Error: ${snap.error}'));
                    }
                    final list = snap.data ?? [];
                    if (list.isEmpty) {
                      return const Center(
                        child: Text('No pending verifications'),
                      );
                    }
                    return ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final item = list[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: ListTile(
                            title: Text(item['full_name'] ?? ''),
                            subtitle: Text(item['email'] ?? ''),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check,
                                      color: AppTheme.gainColor),
                                  onPressed: () async {
                                    await _admin.approveKyc(item['id']);
                                    _refreshKyc();
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close,
                                      color: AppTheme.lossColor),
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
    );
  }
}
