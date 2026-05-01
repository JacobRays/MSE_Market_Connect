import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/price_alert_service.dart';
import 'package:mse_market_connect/core/services/subscription_service.dart';
import 'package:mse_market_connect/core/theme/app_theme.dart';
import 'package:mse_market_connect/features/market/presentation/set_price_alert_screen.dart';
import 'package:mse_market_connect/features/market/presentation/stock_picker_screen.dart';
import 'package:mse_market_connect/features/profile/presentation/upgrade_screen.dart';
import 'package:mse_market_connect/shared/models/price_alert_model.dart';
import 'package:mse_market_connect/shared/models/stock_model.dart';

class MyAlertsScreen extends StatefulWidget {
  const MyAlertsScreen({super.key});

  @override
  State<MyAlertsScreen> createState() => _MyAlertsScreenState();
}

class _MyAlertsScreenState extends State<MyAlertsScreen> {
  final _alerts = PriceAlertService();
  final _subs = SubscriptionService();

  late Future<List<PriceAlertModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _alerts.getMyAlerts();
  }

  Future<void> _refresh() async {
    setState(() => _future = _alerts.getMyAlerts());
    await _future;
  }

  Future<void> _addAlertFromWatchTab() async {
    final sub = await _subs.getOrCreateMySubscription();
    if (!mounted) return;

    if (!sub.isPremium) {
      final activeCount = await _alerts.getMyActiveAlertsCount();
      if (!mounted) return;

      if (activeCount >= 1) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Premium required'),
            content: const Text(
              'Free users can set only 1 active price alert.\n\n'
              'Upgrade to Premium (MWK 50,000/month) to watch unlimited companies.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Not now'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const UpgradeScreen()),
                  );
                },
                child: const Text('View Premium'),
              ),
            ],
          ),
        );
        return;
      }
    }

    final StockModel? stock = await Navigator.of(context).push<StockModel>(
      MaterialPageRoute(builder: (_) => const StockPickerScreen()),
    );
    if (!mounted || stock == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SetPriceAlertScreen(
          stockSymbol: stock.symbol,
          companyName: stock.companyName,
          currentPrice: stock.price,
        ),
      ),
    );
    if (!mounted) return;

    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watch (Price Alerts)'),
        actions: [
          IconButton(
            tooltip: 'Add watch',
            onPressed: _addAlertFromWatchTab,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<PriceAlertModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [Text('Failed to load watch list.\n${snapshot.error}')],
              );
            }

            final alerts = snapshot.data ?? [];
            if (alerts.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 50),
                  const Icon(Icons.track_changes_outlined, size: 64),
                  const SizedBox(height: 12),
                  const Center(child: Text('You are not watching any companies yet.')),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _addAlertFromWatchTab,
                      icon: const Icon(Icons.add),
                      label: const Text('Add a company to watch'),
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final a = alerts[index];
                final isBuy = a.alertType == 'buy';
                final typeColor = isBuy ? AppTheme.primaryColor : AppTheme.secondaryColor;

                final currentPrice = a.currentPrice;
                final change = a.changePercent;

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Row(
                      children: [
                        Text(a.stockSymbol,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            isBuy ? 'BUY TARGET' : 'SELL TARGET',
                            style: TextStyle(
                              color: typeColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          a.isActive ? Icons.circle : Icons.check_circle,
                          size: 14,
                          color: a.isActive ? Colors.orange : AppTheme.gainColor,
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.companyName ?? ''),
                          const SizedBox(height: 8),
                          Text(
                            'Target: MWK ${a.targetPrice.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                'Current: ${currentPrice == null ? '—' : 'MWK ${currentPrice.toStringAsFixed(2)}'}',
                              ),
                              const SizedBox(width: 10),
                              if (change != null)
                                Text(
                                  '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    color: change >= 0
                                        ? AppTheme.gainColor
                                        : AppTheme.lossColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SetPriceAlertScreen(
                            stockSymbol: a.stockSymbol,
                            companyName: a.companyName ?? a.stockSymbol,
                            currentPrice: a.currentPrice ?? 0,
                            existingAlert: a,
                          ),
                        ),
                      );
                      if (!mounted) return;
                      await _refresh();
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
