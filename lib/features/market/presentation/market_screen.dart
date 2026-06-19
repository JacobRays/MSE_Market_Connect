import 'dart:async';
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

enum MarketView { all, watching }

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final _marketService = MarketService();
  final _alertService = PriceAlertService();

  bool _loading = true;
  String? _error;

  List<StockModel> _stocks = [];

  MarketView _view = MarketView.all;
  bool _loadingAlerts = true;
  final Map<String, PriceAlertModel> _activeAlertBySymbol = {};

  RealtimeChannel? _stocksChannel;

  // live price flash
  final Map<String, double> _lastPrice = {};
  final Map<String, int> _flashDir = {};
  final Map<String, Timer> _flashTimers = {};

  @override
  void initState() {
    super.initState();
    _loadAll();
    _listenStocksRealtime();
  }

  @override
  void dispose() {
    if (_stocksChannel != null) {
      Supabase.instance.client.removeChannel(_stocksChannel!);
    }
    for (final t in _flashTimers.values) {
      t.cancel();
    }
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final stocks = await _marketService.getStocks();
      if (!mounted) return;

      setState(() {
        _stocks = stocks;
        _loading = false;
      });

      for (final s in stocks) {
        _lastPrice[s.symbol] = s.price;
      }

      await _loadActiveAlerts();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadActiveAlerts() async {
    setState(() => _loadingAlerts = true);
    try {
      final alerts = await _alertService.getMyAlerts(activeOnly: true);
      if (!mounted) return;

      _activeAlertBySymbol
        ..clear()
        ..addEntries(alerts.map((a) => MapEntry(a.stockSymbol, a)));

      setState(() => _loadingAlerts = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAlerts = false);
    }
  }

  Future<void> _refresh() async {
    await _loadAll();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Market refreshed')));
  }

  void _listenStocksRealtime() {
    _stocksChannel = Supabase.instance.client
        .channel('stocks-live')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'stocks',
          callback: (payload) {
            final rec = payload.newRecord;
            if (rec.isEmpty) return;
            if (rec['is_active'] == false) return;

            final updated = StockModel.fromMap(rec);

            final prev = _lastPrice[updated.symbol];
            if (prev != null) {
              final dir = updated.price > prev
                  ? 1
                  : (updated.price < prev ? -1 : 0);
              if (dir != 0) _triggerFlash(updated.symbol, dir);
            }
            _lastPrice[updated.symbol] = updated.price;

            final idx = _stocks.indexWhere((s) => s.symbol == updated.symbol);
            setState(() {
              if (idx == -1) {
                _stocks = [..._stocks, updated]
                  ..sort((a, b) => a.symbol.compareTo(b.symbol));
              } else {
                final copy = [..._stocks];
                copy[idx] = updated;
                _stocks = copy;
              }
            });
          },
        )
        .subscribe();
  }

  void _triggerFlash(String symbol, int dir) {
    _flashTimers[symbol]?.cancel();
    setState(() => _flashDir[symbol] = dir);

    _flashTimers[symbol] = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _flashDir.remove(symbol));
    });
  }

  String _watchLine(PriceAlertModel a) {
    final isBuy = a.alertType == 'buy';
    return isBuy
        ? 'Watching: BUY when price ≤ MWK ${a.targetPrice.toStringAsFixed(2)}'
        : 'Watching: SELL when price ≥ MWK ${a.targetPrice.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final canShowToggle = !_loadingAlerts;

    final visible = _view == MarketView.all
        ? _stocks
        : _stocks
              .where((s) => _activeAlertBySymbol.containsKey(s.symbol))
              .toList();

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
            tooltip: 'Watch (Targets)',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const MyAlertsScreen())),
            icon: const Icon(Icons.track_changes_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : (_error != null)
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 40),
                  const Icon(
                    Icons.error_outline,
                    color: AppTheme.lossColor,
                    size: 64,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load market data.\n$_error',
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (canShowToggle) ...[
                    SegmentedButton<MarketView>(
                      segments: const [
                        ButtonSegment(
                          value: MarketView.all,
                          label: Text('All'),
                        ),
                        ButtonSegment(
                          value: MarketView.watching,
                          label: Text('Watching'),
                        ),
                      ],
                      selected: {_view},
                      onSelectionChanged: (set) =>
                          setState(() => _view = set.first),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (visible.isEmpty) ...[
                    const SizedBox(height: 60),
                    const Icon(Icons.show_chart, size: 64),
                    const SizedBox(height: 12),
                    Text(
                      _view == MarketView.watching
                          ? 'You are not watching any companies yet.\nCreate a price target in Trade → Alert.'
                          : 'No stocks available yet.',
                      textAlign: TextAlign.center,
                    ),
                  ] else ...[
                    ...visible.map((stock) {
                      final alert = _activeAlertBySymbol[stock.symbol];
                      final isPositive = stock.changePercent >= 0;

                      final flash = _flashDir[stock.symbol] ?? 0;
                      final flashColor = flash == 1
                          ? AppTheme.gainColor.withValues(alpha: 0.10)
                          : flash == -1
                          ? AppTheme.lossColor.withValues(alpha: 0.10)
                          : Colors.transparent;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => StockDetailScreen(stock: stock),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                14,
                                12,
                                14,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Left: symbol + company + (alert)
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          stock.symbol,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          stock.companyName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                        ),
                                        if (alert != null) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            _watchLine(alert),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 10),

                                  // Right: price + % change + trade
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minWidth: 110,
                                      maxWidth: 200,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 250,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: flashColor,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              AnimatedSwitcher(
                                                duration: const Duration(
                                                  milliseconds: 200,
                                                ),
                                                transitionBuilder:
                                                    (child, anim) =>
                                                        FadeTransition(
                                                          opacity: anim,
                                                          child: child,
                                                        ),
                                                child: Text(
                                                  'MWK ${stock.price.toStringAsFixed(2)}',
                                                  key: ValueKey(stock.price),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleSmall
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    isPositive
                                                        ? Icons.arrow_upward
                                                        : Icons.arrow_downward,
                                                    size: 13,
                                                    color: isPositive
                                                        ? AppTheme.gainColor
                                                        : AppTheme.lossColor,
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    '${isPositive ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
                                                    style: TextStyle(
                                                      color: isPositive
                                                          ? AppTheme.gainColor
                                                          : AppTheme.lossColor,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          height: 32,
                                          child: OutlinedButton(
                                            onPressed: () =>
                                                MarketActionSheet.show(
                                                  context,
                                                  stock,
                                                ),
                                            style: OutlinedButton.styleFrom(
                                              visualDensity:
                                                  VisualDensity.compact,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                  ),
                                            ),
                                            child: const Text('Trade'),
                                          ),
                                        ),
                                      ],
                                    ),
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
              ),
      ),
    );
  }
}
