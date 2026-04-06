import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/theme/app_theme.dart';
import 'package:mse_market_connect/features/trade/presentation/buy_order_screen.dart';
import 'package:mse_market_connect/shared/models/stock_model.dart';

class StockDetailScreen extends StatelessWidget {
  final StockModel stock;

  const StockDetailScreen({
    super.key,
    required this.stock,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = stock.changePercent >= 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(stock.symbol),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stock.symbol,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        stock.companyName,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _MetricItem(
                            label: 'Price',
                            value: 'MWK ${stock.price.toStringAsFixed(2)}',
                          ),
                          _MetricItem(
                            label: 'Change',
                            value:
                                '${isPositive ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
                            valueColor: isPositive
                                ? AppTheme.gainColor
                                : AppTheme.lossColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _MetricItem(
                        label: 'Volume',
                        value: stock.volume.toString(),
                      ),
                      if (stock.updatedAt != null) ...[
                        const SizedBox(height: 20),
                        _MetricItem(
                          label: 'Last Updated',
                          value: _formatDate(stock.updatedAt!),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About this stock',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'View current market price, track daily movement, and place a broker-routed buy order directly from your phone.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BuyOrderScreen(stock: stock),
                      ),
                    );
                  },
                  child: const Text('Buy Shares'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _MetricItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }
}
