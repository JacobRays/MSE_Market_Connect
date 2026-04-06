import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/market_service.dart';
import 'package:mse_market_connect/core/theme/app_theme.dart';
import 'package:mse_market_connect/features/market/presentation/stock_detail_screen.dart';
import 'package:mse_market_connect/shared/models/stock_model.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final MarketService _marketService = MarketService();
  late Future<List<StockModel>> _stocksFuture;

  @override
  void initState() {
    super.initState();
    _stocksFuture = _marketService.getStocks();
  }

  Future<void> _refreshStocks() async {
    setState(() {
      _stocksFuture = _marketService.getStocks();
    });

    await _stocksFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Market'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshStocks,
        child: FutureBuilder<List<StockModel>>(
          future: _stocksFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingState();
            }

            if (snapshot.hasError) {
              return _ErrorState(
                message: 'Failed to load market data.\n${snapshot.error}',
                onRetry: _refreshStocks,
              );
            }

            final stocks = snapshot.data ?? [];

            if (stocks.isEmpty) {
              return const _EmptyState();
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: stocks.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final stock = stocks[index];
                final isPositive = stock.changePercent >= 0;

                return Card(
                  child: ListTile(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StockDetailScreen(stock: stock),
                        ),
                      );
                    },
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      stock.symbol,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(stock.companyName),
                          const SizedBox(height: 6),
                          Text(
                            'Volume: ${stock.volume}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'MWK ${stock.price.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${isPositive ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: isPositive
                                ? AppTheme.gainColor
                                : AppTheme.lossColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: const [
        SizedBox(height: 100),
        Icon(Icons.show_chart, size: 64),
        SizedBox(height: 16),
        Center(
          child: Text(
            'No stocks available yet.',
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        const Icon(
          Icons.error_outline,
          size: 64,
          color: AppTheme.lossColor,
        ),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: onRetry,
            child: const Text('Try Again'),
          ),
        ),
      ],
    );
  }
}
