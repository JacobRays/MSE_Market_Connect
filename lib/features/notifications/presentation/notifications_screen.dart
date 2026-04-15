import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/notification_service.dart';
import 'package:mse_market_connect/shared/models/app_notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationService();
  late Future<List<AppNotificationModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getMyNotifications();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _service.getMyNotifications();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alerts & Notifications')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<AppNotificationModel>>(
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
                  const SizedBox(height: 40),
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
                  SizedBox(height: 60),
                  Icon(Icons.notifications_none, size: 64),
                  SizedBox(height: 12),
                  Text(
                    'No notifications yet.',
                    textAlign: TextAlign.center,
                  ),
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
                return Card(
                  child: ListTile(
                    title: Text(n.title),
                    subtitle: Text(n.body),
                    trailing: n.isRead
                        ? const Icon(Icons.done, size: 18)
                        : const Icon(Icons.circle, size: 10),
                    onTap: () async {
                      if (!n.isRead) {
                        await _service.markRead(n.id);
                        if (!mounted) return;
                        await _refresh();
                      }
                    },
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
