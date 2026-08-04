import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/broker_service.dart';
import 'package:mse_market_connect/shared/models/broker_model.dart';

class BrokerSelectScreen extends StatelessWidget {
  const BrokerSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = BrokerService();

    return Scaffold(
      appBar: AppBar(title: const Text('Select Broker')),
      body: FutureBuilder<List<BrokerModel>>(
        future: service.getActiveBrokers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(child: Text('Failed to load brokers.\n${snapshot.error}')),
            );
          }

          final brokers = snapshot.data ?? [];
          if (brokers.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text('No active brokers available yet. Please try again later.'),
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
                  subtitle: Text('Estimated fee rate: ${(b.feeRate * 100).toStringAsFixed(2)}%'),
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
