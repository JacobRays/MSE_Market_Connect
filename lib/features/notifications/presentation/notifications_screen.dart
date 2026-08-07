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
  List<NotificationModel> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkAdminAndLoad();
  }

  Future<void> _checkAdminAndLoad() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final profile = await Supabase.instance.client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    final admin = (profile?['role'] ?? '') == 'admin';
    final notifs = await _notifService.getMyNotifications();

    if (!mounted) return;
    setState(() {
      _isAdmin = admin;
      _notifications = notifs;
      _loading = false;
    });
  }

  Future<void> _refresh() async {
    final notifs = await _notifService.getMyNotifications();
    if (!mounted) return;
    setState(() => _notifications = notifs);
  }

  Future<void> _markAllRead() async {
    await _notifService.markAllAsRead();
    _refresh();
  }

  Future<void> _deleteNotification(int index) async {
    final notif = _notifications[index];
    await _notifService.deleteNotification(notif.id);
    _refresh();
  }

  void _openAdminPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AdminBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton.icon(
              onPressed: _markAllRead,
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Mark all read'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: _openAdminPanel,
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.admin_panel_settings, color: Colors.white),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: _notifications.isEmpty
                  ? const Center(child: Text('No notifications yet'))
                  : ListView.separated(
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final n = _notifications[index];
                        final timeAgo = _timeAgo(n.createdAt);

                        return Dismissible(
                          key: Key(n.id.toString()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: AppTheme.lossColor,
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) => _deleteNotification(index),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppTheme.primaryColor.withOpacity(0.1),
                              child: const Icon(Icons.campaign,
                                  color: AppTheme.primaryColor, size: 22),
                            ),
                            title: Text(n.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(n.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            trailing: Text(
                              timeAgo,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 60) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${d.day}/${d.month}/${d.year}';
  }
}

// ─── Admin bottom sheet (kept separate, not a tab) ──────
class _AdminBottomSheet extends StatefulWidget {
  const _AdminBottomSheet();

  @override
  _AdminBottomSheetState createState() => _AdminBottomSheetState();
}

class _AdminBottomSheetState extends State<_AdminBottomSheet> {
  final AdminNotificationService _admin = AdminNotificationService();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _bodyCtrl = TextEditingController();
  late Future<List<Map<String, dynamic>>> _pendingKyc;

  @override
  void initState() {
    super.initState();
    _pendingKyc = _admin.getPendingKyc();
  }

  @override
  void dispose() {
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
    setState(() => _pendingKyc = _admin.getPendingKyc());
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Admin Panel'),
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: AppTheme.primaryColor,
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
                        // KYC Approvals tab
                        RefreshIndicator(
                          onRefresh: _refreshKyc,
                          child: FutureBuilder<List<Map<String, dynamic>>>(
                            future: _pendingKyc,
                            builder: (ctx, snap) {
                              if (snap.connectionState ==
                                  ConnectionState.waiting)
                                return const Center(
                                    child: CircularProgressIndicator());
                              if (snap.hasError)
                                return Center(
                                    child: Text('Error: ${snap.error}'));
                              final list = snap.data ?? [];
                              if (list.isEmpty)
                                return const Center(
                                  child: Text('No pending verifications'),
                                );
                              return ListView.builder(
                                controller: scrollController,
                                itemCount: list.length,
                                itemBuilder: (_, i) {
                                  final item = list[i];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
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
                                              await _admin
                                                  .approveKyc(item['id']);
                                              _refreshKyc();
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close,
                                                color: AppTheme.lossColor),
                                            onPressed: () async {
                                              await _admin
                                                  .rejectKyc(item['id']);
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
            ),
          ),
        );
      },
    );
  }
}
