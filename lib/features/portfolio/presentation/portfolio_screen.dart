import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/portfolio_service.dart';
import 'package:mse_market_connect/core/services/trade_order_service.dart';
import 'package:mse_market_connect/core/theme/app_theme.dart';
import 'package:mse_market_connect/shared/models/holding_model.dart';
import 'package:mse_market_connect/shared/models/trade_order_model.dart';
import 'package:mse_market_connect/features/trade/presentation/order_detail_screen.dart';
import 'package:mse_market_connect/features/trade/presentation/my_orders_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final h = await _portfolioService.getMyHoldings();
    final o = await _orderService.getMyOrders(limit: 5);
    if (mounted) {
      setState(() { _holdings = h; _recentOrders = o; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalValue = _holdings.fold(0, (sum, item) => sum + item.marketValue);
    double totalGain = _holdings.fold(0, (sum, item) => sum + item.gainLoss);

    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Portfolio'), actions: [
        IconButton(icon: const Icon(Icons.receipt_long), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOrdersScreen()))),
      ]),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: AppTheme.primaryColor,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text('TOTAL MARKET VALUE', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 8),
                    Text('MWK ${totalValue.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('${totalGain >= 0 ? "+" : ""}MWK ${totalGain.toStringAsFixed(2)}', 
                      style: TextStyle(color: totalGain >= 0 ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('YOUR HOLDINGS', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_holdings.isEmpty) const Center(child: Text('No shares owned yet.'))
            else ..._holdings.map((h) => Card(
              child: ListTile(
                title: Text(h.symbol, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${h.shares} Shares | Avg: ${h.avgCost.toStringAsFixed(2)}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('MWK ${h.marketValue.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${h.gainLossPercent >= 0 ? "+" : ""}${h.gainLossPercent.toStringAsFixed(2)}%', 
                      style: TextStyle(color: h.gainLossPercent >= 0 ? Colors.green : Colors.red, fontSize: 12)),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 24),
            const Text('RECENT ORDERS', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._recentOrders.map((o) => Card(
              child: ListTile(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: o.id))),
                title: Text('${o.stockSymbol} ${o.side.toUpperCase()}'),
                subtitle: Text('Qty: ${o.quantity} | Status: ${o.status.toUpperCase()}'),
                trailing: const Icon(Icons.chevron_right),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
