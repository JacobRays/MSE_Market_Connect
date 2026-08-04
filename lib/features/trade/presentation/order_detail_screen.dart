import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/trade_order_service.dart';
import 'package:mse_market_connect/shared/models/trade_order_model.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _service = TradeOrderService();
  late Future<TradeOrderModel?> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getMyOrderById(widget.orderId);
  }

  Future<void> _refresh() async {
    setState(() => _future = _service.getMyOrderById(widget.orderId));
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Tracking')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<TradeOrderModel?>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [Text('Failed to load order.\n${snapshot.error}')],
              );
            }

            final o = snapshot.data;
            if (o == null) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: const [
                  SizedBox(height: 40),
                  Center(child: Text('Order not found.')),
                ],
              );
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${o.stockSymbol} • ${o.side.toUpperCase()}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text('Quantity: ${o.quantity}'),
                        Text('Broker: ${o.brokerName ?? o.brokerId}'),
                        const SizedBox(height: 8),
                        Text('Status: ${o.status.toUpperCase()}'),
                        const SizedBox(height: 8),
                        Text('Created: ${o.createdAt}'),
                        Text('Updated: ${o.updatedAt}'),
                        if (o.totalEstimate != null)
                          Text(
                            'Total estimate: MWK ${o.totalEstimate!.toStringAsFixed(2)}',
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
