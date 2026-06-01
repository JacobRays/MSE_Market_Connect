import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/broker_service.dart';
import 'package:mse_market_connect/shared/models/broker_model.dart';
import 'package:url_launcher/url_launcher.dart';

class BrokerListScreen extends StatelessWidget {
  const BrokerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = BrokerService();

    return Scaffold(
      appBar: AppBar(title: const Text('Licensed Brokers')),
      body: FutureBuilder<List<BrokerModel>>(
        future: service.getActiveBrokers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final brokers = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: brokers.length,
            itemBuilder: (context, i) => Card(
              child: ListTile(
                title: Text(brokers[i].name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Fee: ${(brokers[i].feeRate * 100).toStringAsFixed(1)}%\n${brokers[i].email ?? ""}\n${brokers[i].phone ?? ""}'),
                trailing: const Icon(Icons.contact_phone_outlined),
                onTap: () {
                  if (brokers[i].phone != null) launchUrl(Uri.parse('tel:${brokers[i].phone}'));
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
