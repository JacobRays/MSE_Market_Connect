import 'package:flutter/material.dart';
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

  static const double brokerageRate = 0.02;

  int get quantity => int.tryParse(_quantityController.text.trim()) ?? 0;

  double get subtotal => quantity * widget.stock.price;
  double get brokerageFee => subtotal * brokerageRate;
  double get totalEstimate => subtotal + brokerageFee;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stock = widget.stock;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy Shares'),
      ),
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
                      Text(
                        stock.symbol,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        stock.companyName,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Current Price: MWK ${stock.price.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enter quantity',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Number of shares',
                          hintText: 'e.g. 100',
                        ),
                        onChanged: (_) {
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Minimum trade on MSE is often 100 shares, depending on the stock.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Estimate',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      _SummaryRow(
                        label: 'Quantity',
                        value: quantity.toString(),
                      ),
                      const SizedBox(height: 10),
                      _SummaryRow(
                        label: 'Subtotal',
                        value: 'MWK ${subtotal.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 10),
                      _SummaryRow(
                        label: 'Brokerage Fee (2%)',
                        value: 'MWK ${brokerageFee.toStringAsFixed(2)}',
                      ),
                      const Divider(height: 24),
                      _SummaryRow(
                        label: 'Total Estimate',
                        value: 'MWK ${totalEstimate.toStringAsFixed(2)}',
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Broker Routing',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Broker selection will be added next. For now, this screen prepares the investor order estimate before routing to a licensed broker.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: quantity > 0
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Next step: broker selection and order submission',
                              ),
                            ),
                          );
                        }
                      : null,
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final valueStyle = isBold
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyLarge;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: valueStyle,
        ),
      ],
    );
  }
}
