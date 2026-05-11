import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mse_market_connect/core/services/trade_order_service.dart';
import 'package:mse_market_connect/features/trade/presentation/my_orders_screen.dart';
import 'package:mse_market_connect/features/trade/presentation/order_detail_screen.dart';
import 'package:mse_market_connect/shared/models/trade_order_model.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final _orders = TradeOrderService();
  late Future<List<TradeOrderModel>> _future;
  RealtimeChannel? _ordersChannel;

  @override
  void initState() {
    super.initState();
    _future = _orders.getMyOrders(limit: 50);
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
            final uid = user.id;
            final newUserId = payload.newRecord['user_id'];
            final oldUserId = payload.oldRecord['user_id'];
            if (newUserId == uid || oldUserId == uid) {
              await _refresh(silent: true);
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    if (_ordersChannel != null) {
      Supabase.instance.client.removeChannel(_ordersChannel!);
    }
    super.dispose();
  }

  Future<void> _refresh({bool silent = false}) async {
    setState(() => _future = _orders.getMyOrders(limit: 50));
    await _future;

    if (!silent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Portfolio refreshed')),
      );
    }
  }

  String _fmt(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

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
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(),
        child: FutureBuilder<List<TradeOrderModel>>(
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

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Text('Recent Orders', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),

                if (orders.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No orders yet. Use Market → Trade to submit a request.'),
                    ),
                  )
                else
                  ...orders.take(10).map((o) {
                    final total = o.totalEstimate == null
                        ? '—'
                        : 'MWK ${o.totalEstimate!.toStringAsFixed(2)}';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: ListTile(
                          isThreeLine: true,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => OrderDetailScreen(orderId: o.id),
                              ),
                            );
                          },
                          title: Text('${o.stockSymbol} • ${o.side.toUpperCase()}'),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Broker: ${o.brokerName ?? '—'}'),
                                Text('Date: ${_fmt(o.createdAt)}'),
                                Text('Qty: ${o.quantity}  •  Total: $total'),
                              ],
                            ),
                          ),
                          trailing: _StatusChip(status: o.status),
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

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  Color _color(String s) {
    s = s.toLowerCase();
    if (s == 'submitted' || s == 'received') return Colors.orange;
    if (s == 'approved') return Colors.blue;
    if (s == 'executed' || s == 'settled') return Colors.green;
    if (s == 'rejected' || s == 'cancelled') return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final c = _color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}
