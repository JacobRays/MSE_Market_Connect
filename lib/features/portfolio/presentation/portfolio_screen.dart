import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/theme/app_theme.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Portfolio Value',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'MWK 245,600.00',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '+ MWK 12,400.00 (5.32%)',
                      style: TextStyle(
                        color: AppTheme.gainColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Your Holdings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const _HoldingTile(
              symbol: 'TNM',
              shares: '500 shares',
              value: 'MWK 9,250.00',
            ),
            const SizedBox(height: 12),
            const _HoldingTile(
              symbol: 'NICO',
              shares: '200 shares',
              value: 'MWK 39,800.00',
            ),
            const SizedBox(height: 12),
            const _HoldingTile(
              symbol: 'FDHB',
              shares: '1,000 shares',
              value: 'MWK 145,000.00',
            ),
          ],
        ),
      ),
    );
  }
}

class _HoldingTile extends StatelessWidget {
  final String symbol;
  final String shares;
  final String value;

  const _HoldingTile({
    required this.symbol,
    required this.shares,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          child: const Icon(
            Icons.pie_chart,
            color: AppTheme.primaryColor,
          ),
        ),
        title: Text(
          symbol,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(shares),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
