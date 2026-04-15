import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mse_market_connect/core/services/trade_order_service.dart';
import 'package:mse_market_connect/features/trade/presentation/my_orders_screen.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final _orders = TradeOrderService();
  late Future<List<Map<String, dynamic>>> _future;
  late final RealtimeChannel _ordersChannel;

  @override
  void initState() {
    super.initState();
    _future = _orders.getMyOrders();
    _listenToOrders();
  }

  void _listenToOrders() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _ordersChannel = Supabase.instance.client
        .channel('my-orders-live')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'trade_orders',
          callback: (payload) async {
            // Only refresh if the changed row relates to this user
            final newRow = payload.newRecord;
            final oldRow = payload.oldRecord;

            final uid = user.id;
            final newUserId = newRow['user_id'];
            final oldUserId = oldRow['user_id'];

            if (newUserId == uid || oldUserId == uid) {
              await _refresh(silent: true);
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    Supabase.instance.client.removeChannel(_ordersChannel);
    super.dispose();
  }

  Future<void> _refresh({bool silent = false}) async {
    setState(() => _future = _orders.getMyOrders());
    await _future;
    if (!silent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Portfolio refreshed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio'),
        actions: [
          IconButton(
            tooltip: 'My Orders',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
              );
            },
            icon: const Icon(Icons.receipt_long),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [Text('Failed to load portfolio.\n${snapshot.error}')],
              );
            }

            final orders = snapshot.data ?? [];
            final submitted = orders.where((o) => o['status'] == 'submitted').length;
            final executed = orders.where((o) => o['status'] == 'executed').length;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _Metric(label: 'Total Orders', value: orders.length.toString()),
                        _Metric(label: 'Submitted', value: submitted.toString()),
                        _Metric(label: 'Executed', value: executed.toString()),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Note: Holdings/positions will appear after broker execution and settlement tracking is added. '
                      'For now, Portfolio shows your live order activity.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Recent Orders', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                if (orders.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No orders yet. Submit a buy request from a stock page.'),
                    ),
                  )
                else
                  ...orders.take(10).map((o) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: ListTile(
                          title: Text('${o['stock_symbol']} • ${(o['side'] as String).toUpperCase()}'),
                          subtitle: Text('Qty: ${o['quantity']}  •  Status: ${o['status']}'),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
