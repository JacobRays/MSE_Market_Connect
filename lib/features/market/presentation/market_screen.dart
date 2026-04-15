import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mse_market_connect/core/services/market_service.dart';
import 'package:mse_market_connect/core/services/subscription_service.dart';
import 'package:mse_market_connect/core/services/watchlist_service.dart';
import 'package:mse_market_connect/core/theme/app_theme.dart';
import 'package:mse_market_connect/features/market/presentation/my_alerts_screen.dart';
import 'package:mse_market_connect/features/market/presentation/stock_detail_screen.dart';
import 'package:mse_market_connect/features/profile/presentation/upgrade_screen.dart';
import 'package:mse_market_connect/shared/models/stock_model.dart';
import 'package:mse_market_connect/shared/models/subscription_model.dart';

enum MarketView { all, watchlist }

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final MarketService _marketService = MarketService();
  final WatchlistService _watchlistService = WatchlistService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  late Future<List<StockModel>> _stocksFuture;
  Set<String> _watchSymbols = {};
  SubscriptionModel? _subscription;

  MarketView _view = MarketView.all;
  bool _loadingWatchlist = true;

  late final RealtimeChannel _stocksChannel;

  @override
  void initState() {
    super.initState();
    _stocksFuture = _marketService.getStocks();
    _loadWatchlistAndPlan();
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
            // refresh list when backend updates prices
            await _refreshStocks(silent: true);
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    Supabase.instance.client.removeChannel(_stocksChannel);
    super.dispose();
  }

  Future<void> _loadWatchlistAndPlan() async {
    try {
      final symbols = await _watchlistService.getMyWatchlistSymbols();
      final sub = await _subscriptionService.getOrCreateMySubscription();

      if (!mounted) return;
      setState(() {
        _watchSymbols = symbols;
        _subscription = sub;
        _loadingWatchlist = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingWatchlist = false);
    }
  }

  Future<void> _refreshStocks({bool silent = false}) async {
    setState(() {
      _stocksFuture = _marketService.getStocks();
    });

    await _stocksFuture;
    await _loadWatchlistAndPlan();

    if (!silent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Market refreshed')),
      );
    }
  }

  Future<void> _toggleWatch(String symbol) async {
    final isWatched = _watchSymbols.contains(symbol);
    final sub = _subscription ?? await _subscriptionService.getOrCreateMySubscription();

    // Free: 1 watch item (your current rule)
    if (!isWatched && !sub.isPremium && _watchSymbols.isNotEmpty) {
      if (!mounted) return;
      _showUpgradeDialog();
      return;
    }

    try {
      if (isWatched) {
        await _watchlistService.removeFromWatchlist(symbol);
        setState(() => _watchSymbols.remove(symbol));
      } else {
        await _watchlistService.addToWatchlist(symbol);
        setState(() => _watchSymbols.add(symbol));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Watchlist update failed: $e')),
      );
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Premium required'),
          content: const Text(
            'Free users can watch only 1 company.\n\nUpgrade to Premium (MWK 50,000/month) to watch unlimited companies.',
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final canShowWatchlistToggle = !_loadingWatchlist;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Market'),
        actions: [
          IconButton(
            tooltip: 'Price Alerts',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyAlertsScreen()),
              );
            },
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshStocks(),
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
                : allStocks.where((s) => _watchSymbols.contains(s.symbol)).toList();

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (canShowWatchlistToggle) ...[
                  SegmentedButton<MarketView>(
                    segments: const [
                      ButtonSegment(value: MarketView.all, label: Text('All')),
                      ButtonSegment(value: MarketView.watchlist, label: Text('Watchlist')),
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
                    _view == MarketView.watchlist
                        ? 'No stocks in your watchlist yet.'
                        : 'No stocks available yet.',
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  ...stocks.map((stock) {
                    final isPositive = stock.changePercent >= 0;
                    final isWatched = _watchSymbols.contains(stock.symbol);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: ListTile(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => StockDetailScreen(stock: stock),
                              ),
                            );
                          },
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(stock.symbol,
                              style: Theme.of(context).textTheme.titleMedium),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(stock.companyName),
                          ),
                          trailing: SizedBox(
                            width: 170,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  onPressed: () => _toggleWatch(stock.symbol),
                                  icon: Icon(
                                    isWatched ? Icons.star : Icons.star_border,
                                    color: isWatched ? AppTheme.secondaryColor : null,
                                  ),
                                ),
                                const SizedBox(width: 6),
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
