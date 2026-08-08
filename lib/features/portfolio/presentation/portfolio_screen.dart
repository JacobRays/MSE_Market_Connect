import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/portfolio_service.dart';
import 'package:mse_market_connect/core/services/trade_order_service.dart';
import 'package:mse_market_connect/core/theme/app_theme.dart';
import 'package:mse_market_connect/features/trade/presentation/my_orders_screen.dart';
import 'package:mse_market_connect/features/trade/presentation/order_detail_screen.dart';
import 'package:mse_market_connect/shared/models/holding_model.dart';
import 'package:mse_market_connect/shared/models/trade_order_model.dart';
import 'package:mse_market_connect/shared/widgets/company_logo.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final _portfolioService = PortfolioService();
  final _orderService = TradeOrderService();

  List<HoldingModel> _holdings = [];
  List<TradeOrderModel> _recentOrders = [];
  bool _loading = true;
  bool _hideBalances = false;

  RealtimeChannel? _stocksChannel;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _loadData();
    _listenStocksRealtime();
  }

  @override
  void dispose() {
    if (_stocksChannel != null) {
      Supabase.instance.client.removeChannel(_stocksChannel!);
    }
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _hideBalances = prefs.getBool('hide_balances') ?? false;
    });
  }

  Future<void> _toggleHideBalances() async {
    final newVal = !_hideBalances;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hide_balances', newVal);
    if (!mounted) return;
    setState(() => _hideBalances = newVal);
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final h = await _portfolioService.getMyHoldings();
    final o = await _orderService.getMyOrders(limit: 5);
    if (!mounted) return;
    setState(() {
      _holdings = h;
      _recentOrders = o;
      _loading = false;
    });
  }

  void _listenStocksRealtime() {
    _stocksChannel = Supabase.instance.client
        .channel('portfolio-stocks-live')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'stocks',
          callback: (payload) {
            final rec = payload.newRecord;
            if (rec.isEmpty) return;
            final symbol = (rec['symbol'] ?? '').toString().toUpperCase();
            if (symbol.isEmpty) return;
            final idx = _holdings.indexWhere((h) => h.symbol == symbol);
            if (idx == -1) return;
            final price = (rec['price'] as num?)?.toDouble();
            final chg = (rec['change_percent'] as num?)?.toDouble();
            setState(() {
              final updated = _holdings[idx].copyWith(
                currentPrice: price ?? _holdings[idx].currentPrice,
                changePercent: chg ?? _holdings[idx].changePercent,
              );
              final copy = [..._holdings];
              copy[idx] = updated;
              _holdings = copy;
            });
          },
        )
        .subscribe();
  }

  String _formatMoney(double v) {
    if (_hideBalances) return 'MWK ••••';
    return 'MWK ${v.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final totalValue = _holdings.fold<double>(0, (s, h) => s + h.marketValue);
    final totalCost = _holdings.fold<double>(0, (s, h) => s + h.totalCost);
    final totalGain = totalValue - totalCost;
    final totalGainPct = totalCost > 0 ? (totalGain / totalCost) * 100 : 0.0;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio'),
        actions: [
          IconButton(
            icon: Icon(_hideBalances ? Icons.visibility_off : Icons.visibility),
            tooltip: _hideBalances ? 'Show balances' : 'Hide balances',
            onPressed: _toggleHideBalances,
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'My Orders',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Total Value Card ──
            _TotalValueCard(
              value: totalValue,
              gain: totalGain,
              gainPercent: totalGainPct,
              hide: _hideBalances,
            ),
            const SizedBox(height: 24),

            // ── Holdings Section ──
            _SectionTitle(title: 'Your Holdings'),
            const SizedBox(height: 8),
            if (_holdings.isEmpty)
              const _EmptyCard(
                  icon: Icons.bar_chart,
                  message: 'No shares owned yet.\nStart trading to build your portfolio.')
            else
              ..._holdings.map((h) => _HoldingCard(holding: h, hideBalances: _hideBalances)),

            const SizedBox(height: 24),

            // ── Recent Orders Section ──
            _SectionTitle(title: 'Recent Orders'),
            const SizedBox(height: 8),
            if (_recentOrders.isEmpty)
              const _EmptyCard(
                  icon: Icons.receipt,
                  message: 'No orders placed yet.\nYour trading activity will appear here.')
            else
              ..._recentOrders.map((o) => _OrderCard(order: o)),
          ],
        ),
      ),
    );
  }
}

// ────────────────── Total Value Card ──────────────────
class _TotalValueCard extends StatelessWidget {
  final double value;
  final double gain;
  final double gainPercent;
  final bool hide;
  const _TotalValueCard({
    required this.value,
    required this.gain,
    required this.gainPercent,
    required this.hide,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = gain >= 0;
    final gainColor = isPositive ? AppTheme.gainColor : AppTheme.lossColor;
    final sign = isPositive ? '+' : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0D47A1),
            const Color(0xFF1565C0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D47A1).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL VALUE',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hide ? 'MWK ••••' : 'MWK ${value.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: gainColor,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                hide ? 'P/L ••••' : '$sign${gain.toStringAsFixed(2)} ($sign${gainPercent.toStringAsFixed(2)}%)',
                style: TextStyle(
                  color: gainColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ────────────────── Holding Card ──────────────────
class _HoldingCard extends StatelessWidget {
  final HoldingModel holding;
  final bool hideBalances;
  const _HoldingCard({required this.holding, required this.hideBalances});

  @override
  Widget build(BuildContext context) {
    final isUp = holding.changePercent >= 0;
    final trendColor = isUp ? AppTheme.gainColor : AppTheme.lossColor;
    final sign = isUp ? '+' : '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CompanyLogo(symbol: holding.symbol, logoUrl: holding.logoUrl, size: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    holding.symbol,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    holding.companyName.isNotEmpty ? holding.companyName : 'Company',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${holding.shares} shrs @ ${holding.avgCost.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Price ${hideBalances ? "••••" : holding.currentPrice.toStringAsFixed(2)} | Value ${hideBalances ? "••••" : holding.marketValue.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$sign${holding.changePercent.toStringAsFixed(2)}%',
                  style: TextStyle(color: trendColor, fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 10),
                Text(
                  'P/L ${holding.gainLoss >= 0 ? '+' : ''}${holding.gainLoss.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: holding.gainLoss >= 0 ? AppTheme.gainColor : AppTheme.lossColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────── Order Card ──────────────────
class _OrderCard extends StatelessWidget {
  final TradeOrderModel order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)),
        ),
        leading: CircleAvatar(
          backgroundColor: order.side == 'buy'
              ? AppTheme.gainColor.withValues(alpha: 0.1)
              : AppTheme.lossColor.withValues(alpha: 0.1),
          child: Icon(
            order.side == 'buy' ? Icons.call_made : Icons.call_received,
            color: order.side == 'buy' ? AppTheme.gainColor : AppTheme.lossColor,
            size: 20,
          ),
        ),
        title: Text(
          '${order.stockSymbol} ${order.side.toUpperCase()}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('Qty: ${order.quantity} • ${order.status.toUpperCase()}'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

// ────────────────── Shared Widgets ──────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: Colors.grey[700],
            letterSpacing: 0.5,
          ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
