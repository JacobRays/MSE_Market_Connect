import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/market_service.dart';
import 'package:mse_market_connect/shared/models/stock_model.dart';

class StockPickerScreen extends StatelessWidget {
  const StockPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = MarketService();

    return Scaffold(
      appBar: AppBar(title: const Text('Choose a company')),
      body: FutureBuilder<List<StockModel>>(
        future: service.getStocks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(child: Text('Failed to load companies.\n${snapshot.error}')),
            );
          }

          final stocks = snapshot.data ?? [];
          if (stocks.isEmpty) {
            return const Center(child: Text('No companies available.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: stocks.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final s = stocks[index];
              return Card(
                child: ListTile(
                  title: Text(s.symbol),
                  subtitle: Text(s.companyName),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).pop(s),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
