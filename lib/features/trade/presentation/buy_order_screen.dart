import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/trade_order_service.dart';
import 'package:mse_market_connect/features/brokers/presentation/broker_select_screen.dart';
import 'package:mse_market_connect/features/trade/presentation/order_success_screen.dart';
import 'package:mse_market_connect/shared/models/broker_model.dart';
import 'package:mse_market_connect/shared/models/stock_model.dart';

class BuyOrderScreen extends StatefulWidget {
  final StockModel stock;

  const BuyOrderScreen({
    super.key,
    required this.stock,
  });

  @override
  State<BuyOrderScreen> createState() => _BuyOrderScreenState();
}

class _BuyOrderScreenState extends State<BuyOrderScreen> {
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  final _orderService = TradeOrderService();

  BrokerModel? _selectedBroker;
  bool _submitting = false;

  static const double fallbackBrokerageRate = 0.02;

  int get quantity => int.tryParse(_quantityController.text.trim()) ?? 0;

  double get feeRate => _selectedBroker?.feeRate ?? fallbackBrokerageRate;
  double get subtotal => quantity * widget.stock.price;
  double get brokerageFee => subtotal * feeRate;
  double get totalEstimate => subtotal + brokerageFee;

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickBroker() async {
    final broker = await Navigator.of(context).push<BrokerModel>(
      MaterialPageRoute(builder: (_) => const BrokerSelectScreen()),
    );

    if (!mounted) return;
    if (broker != null) {
      setState(() => _selectedBroker = broker);
    }
  }

  Future<void> _submitOrder() async {
    if (quantity <= 0) return;
    if (_selectedBroker == null) {
      await _pickBroker();
      if (_selectedBroker == null) return;
    }

    setState(() => _submitting = true);

    try {
      final orderId = await _orderService.createBuyOrder(
        stock: widget.stock,
        broker: _selectedBroker!,
        quantity: quantity,
        investorNote: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(orderId: orderId),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order submission failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stock = widget.stock;

    return Scaffold(
      appBar: AppBar(title: const Text('Buy Shares')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stock.symbol, style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Text(stock.companyName),
                      const SizedBox(height: 12),
                      Text('Current Price: MWK ${stock.price.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Disclaimer: This app does not execute trades or hold funds. '
                    'Your request is routed to a licensed broker for execution on the MSE.',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quantity', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Number of shares',
                          hintText: 'e.g. 100',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _noteController,
                        decoration: const InputDecoration(
                          labelText: 'Note (optional)',
                          hintText: 'Any instructions for the broker',
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Broker', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(_selectedBroker?.name ?? 'Select a broker'),
                        subtitle: Text(
                          _selectedBroker == null
                              ? 'Choose a licensed broker to route your order.'
                              : 'Fee rate: ${(feeRate * 100).toStringAsFixed(2)}%',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _pickBroker,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order Estimate', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      _row('Subtotal', 'MWK ${subtotal.toStringAsFixed(2)}'),
                      const SizedBox(height: 8),
                      _row('Brokerage Fee', 'MWK ${brokerageFee.toStringAsFixed(2)}'),
                      const Divider(height: 24),
                      _row('Total Estimate', 'MWK ${totalEstimate.toStringAsFixed(2)}', bold: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: (_submitting || quantity <= 0) ? null : _submitOrder,
                  child: _submitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit Order Request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String left, String right, {bool bold = false}) {
    final style = bold ? Theme.of(context).textTheme.titleMedium : null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(left),
        Text(right, style: style),
      ],
    );
  }
}
