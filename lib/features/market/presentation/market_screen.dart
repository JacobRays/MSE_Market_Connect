import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mse_market_connect/core/services/market_service.dart';
import 'package:mse_market_connect/core/services/price_alert_service.dart';
import 'package:mse_market_connect/core/theme/app_theme.dart';
import 'package:mse_market_connect/features/market/presentation/market_action_sheet.dart';
import 'package:mse_market_connect/features/market/presentation/my_alerts_screen.dart';
import 'package:mse_market_connect/features/market/presentation/stock_detail_screen.dart';
import 'package:mse_market_connect/features/notifications/presentation/notifications_screen.dart';
import 'package:mse_market_connect/shared/models/price_alert_model.dart';
import 'package:mse_market_connect/shared/models/stock_model.dart';

enum MarketView { all, alerts }

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final MarketService _marketService = MarketService();
  final PriceAlertService _alertService = PriceAlertService();

  late Future<List<StockModel>> _stocksFuture;

  bool _loadingAlerts = true;
  MarketView _view = MarketView.all;
  final Map<String, PriceAlertModel> _activeAlertBySymbol = {};

  RealtimeChannel? _stocksChannel;

  @override
  void initState() {
    super.initState();
    _stocksFuture = _marketService.getStocks();
    _loadActiveAlerts();
    _listenToStockUpdates();
  }

  void _listenToStockUpdates() {
    _stocksChannel = Supabase.instance.client
        .channel('stocks-live')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'stocks',
          callback: (payload) async {
            await _refresh(silent: true);
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    if (_stocksChannel != null) {
      Supabase.instance.client.removeChannel(_stocksChannel!);
    }
    super.dispose();
  }

  Future<void> _loadActiveAlerts() async {
    setState(() => _loadingAlerts = true);
    try {
      final list = await _alertService.getMyAlerts(activeOnly: true);
      if (!mounted) return;

      _activeAlertBySymbol
        ..clear()
        ..addEntries(list.map((a) => MapEntry(a.stockSymbol, a)));

      setState(() => _loadingAlerts = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAlerts = false);
    }
  }

  Future<void> _refresh({bool silent = false}) async {
    setState(() {
      _stocksFuture = _marketService.getStocks();
    });
    await _stocksFuture;
    await _loadActiveAlerts();

    if (!silent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Market refreshed')),
      );
    }
  }

  String _alertLine(PriceAlertModel a) {
    final isBuy = a.alertType == 'buy';
    return isBuy
        ? 'Watching: BUY when price ≤ MWK ${a.targetPrice.toStringAsFixed(2)}'
        : 'Watching: SELL when price ≥ MWK ${a.targetPrice.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final canShowToggle = !_loadingAlerts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Market'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
            icon: const Icon(Icons.notifications_outlined),
          ),
          IconButton(
            tooltip: 'Watch (Price Alerts)',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MyAlertsScreen()),
            ),
            icon: const Icon(Icons.track_changes_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(),
        child: FutureBuilder<List<StockModel>>(
          future: _stocksFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 40),
                  const Icon(Icons.error_outline, color: AppTheme.lossColor, size: 64),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load market data.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }

            final allStocks = snapshot.data ?? [];

            final stocks = _view == MarketView.all
                ? allStocks
                : allStocks.where((s) => _activeAlertBySymbol.containsKey(s.symbol)).toList();

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (canShowToggle) ...[
                  SegmentedButton<MarketView>(
                    segments: const [
                      ButtonSegment(value: MarketView.all, label: Text('All')),
                      ButtonSegment(value: MarketView.alerts, label: Text('Alerts')),
                    ],
                    selected: {_view},
                    onSelectionChanged: (set) => setState(() => _view = set.first),
                  ),
                  const SizedBox(height: 16),
                ],
                if (stocks.isEmpty) ...[
                  const SizedBox(height: 60),
                  const Icon(Icons.show_chart, size: 64),
                  const SizedBox(height: 12),
                  Text(
                    _view == MarketView.alerts
                        ? 'No watched companies yet.\nSet a price alert to start watching.'
                        : 'No stocks available yet.',
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  ...stocks.map((stock) {
                    final isPositive = stock.changePercent >= 0;
                    final alert = _activeAlertBySymbol[stock.symbol];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: ListTile(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => StockDetailScreen(stock: stock)),
                            );
                          },
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(stock.symbol,
                              style: Theme.of(context).textTheme.titleMedium),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(stock.companyName),
                                if (alert != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    _alertLine(alert),
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          trailing: SizedBox(
                            width: 210,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => MarketActionSheet.show(context, stock),
                                  child: const Text('Trade'),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'MWK ${stock.price.toStringAsFixed(2)}',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                                          size: 14,
                                          color: isPositive ? AppTheme.gainColor : AppTheme.lossColor,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${isPositive ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
                                          style: TextStyle(
                                            color: isPositive ? AppTheme.gainColor : AppTheme.lossColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
