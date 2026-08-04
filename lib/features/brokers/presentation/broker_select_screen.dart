import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/broker_service.dart';
import 'package:mse_market_connect/shared/models/broker_model.dart';
import 'package:mse_market_connect/core/services/broker_service_x.dart';

class BrokerSelectScreen extends StatelessWidget {
  const BrokerSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = BrokerService();

    return Scaffold(
      appBar: AppBar(title: const Text('Select Broker')),
      body: FutureBuilder<List<BrokerModel>>(
        future: service.getActiveBrokersUnique(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text('Failed to load brokers.\n${snapshot.error}'),
              ),
            );
          }

          final raw = snapshot.data ?? [];
          final brokers = _dedupeBrokersByName(raw);
          if (raw.length != brokers.length) {
            // ignore: avoid_print
            print(
              'BrokerSelectScreen: removed ${raw.length - brokers.length} duplicate broker(s) by name',
            );
          }

          if (brokers.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No active brokers available yet. Please try again later.',
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: brokers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final b = brokers[index];
              return Card(
                child: ListTile(
                  title: Text(b.name),
                  subtitle: Text(
                    'Estimated fee rate: ${(b.feeRate * 100).toStringAsFixed(2)}%',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).pop(b),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

List<BrokerModel> _dedupeBrokersByName(List<BrokerModel> list) {
  final seen = <String>{};
  final out = <BrokerModel>[];
  for (final b in list) {
    final key = b.name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (seen.add(key)) out.add(b);
  }
  out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return out;
}
