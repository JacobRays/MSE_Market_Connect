import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/trade_order_service.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final _service = TradeOrderService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getMyOrders();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _service.getMyOrders();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: RefreshIndicator(
        onRefresh: _refresh,
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
                return Card(
                  child: ListTile(
                    title: Text('${o['stock_symbol']} • ${(o['side'] as String).toUpperCase()}'),
                    subtitle: Text('Qty: ${o['quantity']}  •  Status: ${o['status']}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Later: order detail screen
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Order Details'),
                          content: Text('Order ID:\n${o['id']}'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
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
