#!/usr/bin/env bash
set -Eeuo pipefail

STATUS_SVC="lib/core/services/market_status_service.dart"
SCREEN="lib/features/market/presentation/market_screen.dart"

backup() { [[ -f "$1" ]] && cp -a "$1" "$1.bak.$(date +%Y%m%d_%H%M%S)" && echo "Backup: $1.bak.*"; }

# 1) Add a small MarketStatus service (Supabase-backed if table exists, with heuristics fallback)
mkdir -p "$(dirname "$STATUS_SVC")"
cat > "$STATUS_SVC" << 'DART'
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mse_market_connect/shared/models/stock_model.dart';

class MarketStatusData {
  final String status; // 'open' | 'closed' | 'holiday' | 'unknown'
  final String source; // 'supabase' | 'heuristic'
  final DateTime checkedAt;
  final String? message;
  const MarketStatusData({
    required this.status,
    required this.source,
    required this.checkedAt,
    this.message,
  });
}

class MarketStatusService {
  final SupabaseClient _db = Supabase.instance.client;

  // Primary: try Supabase table 'market_status' (status, message, updated_at)
  // Fallback: infer from stocks' changePercent + Malawi time window
  Future<MarketStatusData> getStatus({List<StockModel>? snapshot}) async {
    try {
      final row = await _db
          .from('market_status')
          .select('status, message, updated_at')
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (row != null) {
        final st = (row['status'] ?? '').toString().toLowerCase();
        final norm = _normalize(st);
        final when = DateTime.tryParse((row['updated_at'] ?? '').toString()) ?? DateTime.now().toUtc();
        return MarketStatusData(
          status: norm,
          source: 'supabase',
          checkedAt: when,
          message: (row['message'] ?? '').toString(),
        );
      }
    } catch (_) {
      // table may not exist yet; ignore
    }
    // Heuristic fallback
    return _inferFromStocks(snapshot);
  }

  MarketStatusData _inferFromStocks(List<StockModel>? stocks) {
    final nowUtc = DateTime.now().toUtc();
    // Malawi time is UTC+2 (CAT). No DST.
    final mw = nowUtc.add(const Duration(hours: 2));
    final isWeekday = mw.weekday >= DateTime.monday && mw.weekday <= DateTime.friday;
    final inWindow = (mw.hour > 9 && mw.hour < 16) || (mw.hour == 9 && mw.minute >= 0) || (mw.hour == 16 && mw.minute == 0);

    bool anyMovement = false;
    DateTime? latest;
    if (stocks != null && stocks.isNotEmpty) {
      anyMovement = stocks.any((s) => s.changePercent.abs() > 1e-6);
      for (final s in stocks) {
        final t = s.updatedAt;
        if (t != null && (latest == null || t.isAfter(latest!))) latest = t;
      }
    }
    // If any stock moved today during window, call it open
    if (anyMovement && isWeekday && inWindow) {
      return MarketStatusData(
        status: 'open',
        source: 'heuristic',
        checkedAt: nowUtc,
        message: 'Movement detected',
      );
    }
    // Else, likely closed (or pre-open). Add a soft hint if within window.
    final msg = isWeekday && inWindow ? 'No movement yet' : 'Outside trading hours';
    return MarketStatusData(
      status: 'closed',
      source: 'heuristic',
      checkedAt: nowUtc,
      message: msg,
    );
  }

  String _normalize(String s) {
    switch (s) {
      case 'open':
      case 'opened':
        return 'open';
      case 'closed':
      case 'close':
        return 'closed';
      case 'holiday':
        return 'holiday';
      default:
        return 'unknown';
    }
  }
}
DART

# 2) Replace MarketScreen with placeholders + status chip
backup "$SCREEN"
cat > "$SCREEN" << 'DART'
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mse_market_connect/core/services/market_service.dart';
import 'package:mse_market_connect/core/services/price_alert_service.dart';
import 'package:mse_market_connect/core/services/market_status_service.dart';

import 'package:mse_market_connect/shared/widgets/company_logo.dart';
import 'package:mse_market_connect/features/market/presentation/market_action_sheet.dart';
import 'package:mse_market_connect/features/market/presentation/my_alerts_screen.dart';
import 'package:mse_market_connect/features/market/presentation/stock_detail_screen.dart';
import 'package:mse_market_connect/features/notifications/presentation/notifications_screen.dart';
import 'package:mse_market_connect/shared/models/price_alert_model.dart';
import 'package:mse_market_connect/shared/models/stock_model.dart';
import 'package:mse_market_connect/core/theme/app_theme.dart';

enum MarketView { all, watching }

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final _marketService = MarketService();
  final _alertService = PriceAlertService();
  final _statusService = MarketStatusService();

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

  // Market status
  MarketStatusData? _marketStatus;
  bool _statusLoading = false;
  Timer? _statusDebounce;

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
    _statusDebounce?.cancel();
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
      _loadStatusDebounced(); // update status after stocks load
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadStatus() async {
    if (_statusLoading) return;
    setState(() => _statusLoading = true);
    try {
      final st = await _statusService.getStatus(snapshot: _stocks);
      if (!mounted) return;
      setState(() => _marketStatus = st);
    } catch (_) {
      if (!mounted) return;
      setState(() => _marketStatus = null);
    } finally {
      if (mounted) setState(() => _statusLoading = false);
    }
  }

  void _loadStatusDebounced() {
    _statusDebounce?.cancel();
    _statusDebounce = Timer(const Duration(milliseconds: 500), _loadStatus);
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

            // refresh market status (debounced) when a stock changes
            _loadStatusDebounced();
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

  Widget _statusChip() {
    final st = _marketStatus?.status ?? 'unknown';
    Color c;
    String label;
    switch (st) {
      case 'open':
        c = Colors.green;
        label = 'Open';
        break;
      case 'closed':
        c = Colors.redAccent;
        label = 'Closed';
        break;
      case 'holiday':
        c = Colors.orange;
        label = 'Holiday';
        break;
      default:
        c = Colors.grey;
        label = 'Unknown';
    }
    final sub = _marketStatus?.message ?? (_statusLoading ? 'Checking…' : null);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('Market: $label', style: const TextStyle(fontWeight: FontWeight.w700)),
        if (sub != null) ...[
          const SizedBox(width: 8),
          Text(sub, style: const TextStyle(color: Colors.black54, fontSize: 12)),
        ]
      ],
    );
  }

  Widget _emptyCard(String title, String line) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(line, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canShowToggle = !_loadingAlerts;

    final watching = _stocks
        .where((s) => _activeAlertBySymbol.containsKey(s.symbol))
        .toList();
    final gainers = _stocks.where((s) => s.changePercent > 0).toList()
      ..sort((a, b) => b.changePercent.compareTo(a.changePercent));
    final losers = _stocks.where((s) => s.changePercent < 0).toList()
      ..sort((a, b) => a.changePercent.compareTo(b.changePercent));
    final unchanged = _stocks.where((s) => s.changePercent == 0).toList()
      ..sort((a, b) => a.symbol.compareTo(b.symbol));

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
                  Icon(
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
                  // Market status row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _statusChip(),
                      IconButton(
                        tooltip: 'Refresh status',
                        onPressed: _loadStatus,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

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

                  if (_view == MarketView.watching) ...[
                    if (watching.isEmpty) ...[
                      const SizedBox(height: 60),
                      const Icon(Icons.star, size: 64),
                      const SizedBox(height: 12),
                      const Text(
                        'You are not watching any companies yet.\nCreate a price target in Trade → Alert.',
                        textAlign: TextAlign.center,
                      ),
                    ] else ...[
                      ...watching.map(
                        (s) => _StockCard(
                          stock: s,
                          alert: _activeAlertBySymbol[s.symbol],
                          flashDir: _flashDir[s.symbol] ?? 0,
                          onTrade: () => MarketActionSheet.show(context, s),
                          onOpen: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => StockDetailScreen(stock: s),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ] else ...[
                    _SectionHeader(title: 'Gainers'),
                    const SizedBox(height: 8),
                    if (gainers.isEmpty)
                      _emptyCard('No gainers yet', 'Prices haven’t moved up today.'),
                    ...gainers.map(
                      (s) => _StockCard(
                        stock: s,
                        alert: _activeAlertBySymbol[s.symbol],
                        flashDir: _flashDir[s.symbol] ?? 0,
                        onTrade: () => MarketActionSheet.show(context, s),
                        onOpen: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StockDetailScreen(stock: s),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _SectionHeader(title: 'Losers'),
                    const SizedBox(height: 8),
                    if (losers.isEmpty)
                      _emptyCard('No losers yet', 'Prices haven’t moved down today.'),
                    ...losers.map(
                      (s) => _StockCard(
                        stock: s,
                        alert: _activeAlertBySymbol[s.symbol],
                        flashDir: _flashDir[s.symbol] ?? 0,
                        onTrade: () => MarketActionSheet.show(context, s),
                        onOpen: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StockDetailScreen(stock: s),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _SectionHeader(title: 'Unchanged'),
                    const SizedBox(height: 8),
                    if (unchanged.isEmpty)
                      _emptyCard('No data yet', 'No stocks loaded. Pull to refresh.'),
                    ...unchanged.map(
                      (s) => _StockCard(
                        stock: s,
                        alert: _activeAlertBySymbol[s.symbol],
                        flashDir: _flashDir[s.symbol] ?? 0,
                        onTrade: () => MarketActionSheet.show(context, s),
                        onOpen: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StockDetailScreen(stock: s),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
    );
  }
}

class _StockCard extends StatelessWidget {
  final StockModel stock;
  final PriceAlertModel? alert;
  final int flashDir; // 1 up, -1 down
  final VoidCallback onTrade;
  final VoidCallback onOpen;

  const _StockCard({
    required this.stock,
    required this.alert,
    required this.flashDir,
    required this.onTrade,
    required this.onOpen,
  });

  String _watchLine(PriceAlertModel a) {
    final isBuy = a.alertType == 'buy';
    return isBuy
        ? 'Watching: BUY when price ≤ MWK ${a.targetPrice.toStringAsFixed(2)}'
        : 'Watching: SELL when price ≥ MWK ${a.targetPrice.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = stock.changePercent >= 0;
    final flashColor = flashDir == 1
        ? AppTheme.gainColor.withValues(alpha: 0.10)
        : flashDir == -1
        ? AppTheme.lossColor.withValues(alpha: 0.10)
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                CompanyLogo(
                  symbol: stock.symbol,
                  logoUrl: stock.logoUrl,
                  size: 44,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stock.symbol,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stock.companyName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (alert != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _watchLine(alert!),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: flashColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'MWK ${stock.price.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
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
                                  fontWeight: FontWeight.w800,
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
                        onPressed: onTrade,
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text('Trade'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
DART

echo "Patched market status + placeholders."
