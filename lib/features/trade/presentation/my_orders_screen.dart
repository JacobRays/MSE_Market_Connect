import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/trade_order_service.dart';
import 'package:mse_market_connect/features/trade/presentation/order_detail_screen.dart';
import 'package:mse_market_connect/shared/models/trade_order_model.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final _service = TradeOrderService();
  late Future<List<TradeOrderModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getMyOrders(limit: 100);
  }

  Future<void> _refresh() async {
    setState(() => _future = _service.getMyOrders(limit: 100));
    await _future;
  }

  String _fmt(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: RefreshIndicator(
        onRefresh: _refresh,
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
                children: [
                  Text('Failed to load orders.\n${snapshot.error}'),
                ],
              );
            }

            final orders = snapshot.data ?? [];
            if (orders.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: const [
                  SizedBox(height: 40),
                  Center(child: Text('No orders yet.')),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final o = orders[index];
                final total = o.totalEstimate == null
                    ? '—'
                    : 'MWK ${o.totalEstimate!.toStringAsFixed(2)}';

                return Card(
                  child: ListTile(
                    isThreeLine: true,
                    title: Text('${o.stockSymbol} • ${o.side.toUpperCase()}'),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Broker: ${o.brokerName ?? '—'}'),
                          Text('Date: ${_fmt(o.createdAt)}'),
                          Text('Qty: ${o.quantity}  •  Total: $total'),
                          Text('Status: ${o.status.toUpperCase()}'),
                        ],
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OrderDetailScreen(orderId: o.id),
                        ),
                      );
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
