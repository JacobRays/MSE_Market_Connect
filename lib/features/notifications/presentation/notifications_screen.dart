import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/notification_service.dart';
import 'package:mse_market_connect/shared/models/notification_model.dart';

class NotificationsScreen extends StatelessWidget {
  final ScrollController? scrollController;
  const NotificationsScreen({super.key, this.scrollController});

  @override
  Widget build(BuildContext context) {
    final service = NotificationService();

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
        ),
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: FutureBuilder<List<NotificationModel>>(
            future: service.getMyNotifications(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final items = snapshot.data!;
              if (items.isEmpty) return const Center(child: Text('No notifications yet.'));

              return ListView.builder(
                controller: scrollController,
                itemCount: items.length,
                itemBuilder: (context, i) => ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(items[i].title),
                  subtitle: Text(items[i].body),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
