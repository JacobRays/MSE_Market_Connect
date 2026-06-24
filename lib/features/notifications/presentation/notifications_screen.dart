import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mse_market_connect/core/services/notification_service.dart';
import 'package:mse_market_connect/shared/models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationService();
  late Future<List<NotificationModel>> _future;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _future = _service.getMyNotifications();
    _listenRealtime();
  }

  void _listenRealtime() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _channel = Supabase.instance.client
        .channel('notifications-live')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          callback: (payload) async {
            final newRow = payload.newRecord;
            if (newRow['user_id'] == user.id) {
              await _refresh(silent: true);
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
    }
    super.dispose();
  }

  Future<void> _refresh({bool silent = false}) async {
    setState(() => _future = _service.getMyNotifications());
    await _future;

    if (!silent && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Notifications refreshed')));
    }
  }

  Future<bool> _confirm(String title, String message) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  Future<void> _deleteOne(NotificationModel n) async {
    await _service.deleteNotification(n.id);
    await _refresh(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'read') {
                await _service.markAllAsRead();
                await _refresh(silent: true);
              } else if (v == 'clear') {
                final ok = await _confirm(
                  'Clear all notifications?',
                  'This cannot be undone.',
                );
                if (!ok) return;
                await _service.clearAll();
                await _refresh(silent: true);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'read', child: Text('Mark all read')),
              PopupMenuItem(value: 'clear', child: Text('Clear all')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(),
        child: FutureBuilder<List<NotificationModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Failed to load notifications.\n${snapshot.error}'),
                ],
              );
            }

            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: const [
                  SizedBox(height: 40),
                  Icon(Icons.notifications_none, size: 64),
                  SizedBox(height: 12),
                  Center(child: Text('No notifications yet.')),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final n = items[index];

                return Dismissible(
                  key: ValueKey(n.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) => _confirm(
                    'Delete notification?',
                    'This will remove it from your list.',
                  ),
                  onDismissed: (_) async {
                    try {
                      await _deleteOne(n);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notification deleted')),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Delete failed: $e')),
                      );
                      await _refresh(silent: true);
                    }
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                    ),
                  ),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Icon(
                        n.isRead
                            ? Icons.notifications
                            : Icons.notifications_active,
                      ),
                      title: Text(
                        n.title,
                        style: n.isRead
                            ? null
                            : const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(n.body),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!n.isRead) const Icon(Icons.circle, size: 10),
                          const SizedBox(width: 10),
                          IconButton(
                            tooltip: 'Delete',
                            onPressed: () async {
                              final ok = await _confirm(
                                'Delete notification?',
                                'This will remove it from your list.',
                              );
                              if (!ok) return;
                              await _deleteOne(n);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Notification deleted'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                      onTap: () async {
                        if (!n.isRead) {
                          await _service.markAsRead(n.id);
                          await _refresh(silent: true);
                        }
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
