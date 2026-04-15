import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/theme/app_theme.dart';
import 'package:mse_market_connect/features/market/presentation/set_price_alert_screen.dart';
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
                      Text(stock.companyName),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricItem(
                              label: 'Price',
                              value: 'MWK ${stock.price.toStringAsFixed(2)}',
                            ),
                          ),
                          Expanded(
                            child: _MetricItem(
                              label: 'Change',
                              value:
                                  '${isPositive ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
                              valueColor: isPositive
                                  ? AppTheme.gainColor
                                  : AppTheme.lossColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _MetricItem(label: 'Volume', value: stock.volume.toString()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'This app routes order requests to licensed brokers and provides market information. '
                    'It does not execute trades or hold client funds.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SetPriceAlertScreen(
                                stockSymbol: stock.symbol,
                                companyName: stock.companyName,
                                currentPrice: stock.price,
                              ),
                            ),
                          );
                        },
                        child: const Text('Set Price Alert'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
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
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: valueColor),
        ),
      ],
    );
  }
}
