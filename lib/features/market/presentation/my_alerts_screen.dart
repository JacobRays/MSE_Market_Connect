import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/price_alert_service.dart';
import 'package:mse_market_connect/core/theme/app_theme.dart';
import 'package:mse_market_connect/features/market/presentation/set_price_alert_screen.dart';
import 'package:mse_market_connect/shared/models/price_alert_model.dart';

class MyAlertsScreen extends StatefulWidget {
  const MyAlertsScreen({super.key});

  @override
  State<MyAlertsScreen> createState() => _MyAlertsScreenState();
}

class _MyAlertsScreenState extends State<MyAlertsScreen> {
  final _service = PriceAlertService();
  late Future<List<PriceAlertModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getMyAlerts();
  }

  Future<void> _refresh() async {
    setState(() => _future = _service.getMyAlerts());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Price Alerts')),
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
                children: [Text('Failed to load alerts.\n${snapshot.error}')],
              );
            }

            final alerts = snapshot.data ?? [];
            if (alerts.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: const [
                  SizedBox(height: 50),
                  Icon(Icons.notifications_none, size: 64),
                  SizedBox(height: 12),
                  Center(child: Text('No price alerts yet.')),
                  SizedBox(height: 8),
                  Center(child: Text('Open a stock and tap "Set Price Alert".')),
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
                final color = a.isBuy ? AppTheme.primaryColor : AppTheme.secondaryColor;

                final currentPriceText = a.currentPrice == null
                    ? '—'
                    : 'MWK ${a.currentPrice!.toStringAsFixed(2)}';

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Row(
                      children: [
                        Text(a.stockSymbol, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            a.isBuy ? 'BUY' : 'SELL',
                            style: TextStyle(color: color, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.companyName ?? ''),
                          const SizedBox(height: 6),
                          Text('Target: MWK ${a.targetPrice.toStringAsFixed(2)}'),
                          const SizedBox(height: 6),
                          Text('Current: $currentPriceText'),
                        ],
                      ),
                    ),
                    trailing: Icon(
                      a.isActive ? Icons.chevron_right : Icons.check,
                      color: a.isActive ? null : AppTheme.gainColor,
                    ),
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
