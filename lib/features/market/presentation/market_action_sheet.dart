import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/price_alert_service.dart';
import 'package:mse_market_connect/core/services/subscription_service.dart';
import 'package:mse_market_connect/core/services/trade_order_service.dart';
import 'package:mse_market_connect/core/theme/app_theme.dart';
import 'package:mse_market_connect/features/brokers/presentation/broker_select_screen.dart';
import 'package:mse_market_connect/features/profile/presentation/upgrade_screen.dart';
import 'package:mse_market_connect/shared/models/broker_model.dart';
import 'package:mse_market_connect/shared/models/stock_model.dart';

class MarketActionSheet extends StatefulWidget {
  final StockModel stock;

  const MarketActionSheet({
    super.key,
    required this.stock,
  });

  static Future<void> show(BuildContext context, StockModel stock) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MarketActionSheet(stock: stock),
    );
  }

  @override
  State<MarketActionSheet> createState() => _MarketActionSheetState();
}

class _MarketActionSheetState extends State<MarketActionSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  // Order
  final _qty = TextEditingController();
  final _note = TextEditingController();
  BrokerModel? _broker;
  bool _submitting = false;

  // Alert (standalone tab)
  final _alertTarget = TextEditingController();
  String _alertType = 'buy'; // buy|sell

  // Optional alert-with-order
  bool _alsoCreateAlert = false;
  final _alsoAlertTarget = TextEditingController();
  String _alsoAlertType = 'buy';

  final _orders = TradeOrderService();
  final _alerts = PriceAlertService();
  final _subs = SubscriptionService();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);

    // sensible defaults
    _qty.text = '100';
    _alertTarget.text = widget.stock.price.toStringAsFixed(2);
    _alsoAlertTarget.text = widget.stock.price.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _qty.dispose();
    _note.dispose();
    _alertTarget.dispose();
    _alsoAlertTarget.dispose();
    super.dispose();
  }

  int get _quantity => int.tryParse(_qty.text.trim()) ?? 0;

  double get _feeRate => _broker?.feeRate ?? 0.02;
  double get _subtotal => _quantity * widget.stock.price;
  double get _fee => _subtotal * _feeRate;
  double get _total => _subtotal + _fee;

  Future<void> _pickBroker() async {
    final b = await Navigator.of(context).push<BrokerModel>(
      MaterialPageRoute(builder: (_) => const BrokerSelectScreen()),
    );
    if (!mounted) return;
    if (b != null) setState(() => _broker = b);
  }

  Future<bool> _ensureAlertAllowed() async {
    final sub = await _subs.getOrCreateMySubscription();
    if (!sub.isPremium) {
      final count = await _alerts.getMyActiveAlertsCount();
      if (count >= 1) {
        if (!mounted) return false;
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Premium required'),
            content: const Text(
              'Free users can set only 1 active price alert.\n\n'
              'Upgrade to Premium (MWK 50,000/month) for unlimited alerts.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Not now'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const UpgradeScreen()),
                  );
                },
                child: const Text('Upgrade'),
              ),
            ],
          ),
        );
        return false;
      }
    }
    return true;
  }

  String _conditionForType(String type) {
    // buy alert triggers when price <= target
    // sell alert triggers when price >= target
    return type == 'buy' ? 'lte' : 'gte';
  }

  Future<void> _createStandaloneAlert() async {
    final messenger = ScaffoldMessenger.of(context);

    final target = double.tryParse(_alertTarget.text.trim());
    if (target == null || target <= 0) {
      messenger.showSnackBar(const SnackBar(content: Text('Enter a valid target price')));
      return;
    }

    final allowed = await _ensureAlertAllowed();
    if (!allowed) return;

    try {
      await _alerts.createAlert(
        stockSymbol: widget.stock.symbol,
        alertType: _alertType,
        condition: _conditionForType(_alertType),
        targetPrice: target,
      );
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Alert created')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed to create alert: $e')));
    }
  }

  Future<void> _submitOrder(String side) async {
    final messenger = ScaffoldMessenger.of(context);

    if (_quantity <= 0) {
      messenger.showSnackBar(const SnackBar(content: Text('Enter a valid quantity')));
      return;
    }

    if (_broker == null) {
      await _pickBroker();
      if (_broker == null) {
        messenger.showSnackBar(const SnackBar(content: Text('Please select a broker')));
        return;
      }
    }

    // If also creating an alert with the order:
    double? alsoTarget;
    if (_alsoCreateAlert) {
      alsoTarget = double.tryParse(_alsoAlertTarget.text.trim());
      if (alsoTarget == null || alsoTarget <= 0) {
        messenger.showSnackBar(const SnackBar(content: Text('Enter a valid alert target price')));
        return;
      }
      final allowed = await _ensureAlertAllowed();
      if (!allowed) return;
    }

    setState(() => _submitting = true);

    try {
      final orderId = await _orders.createMarketRequestOrder(
        stock: widget.stock,
        broker: _broker!,
        side: side,
        quantity: _quantity,
        investorNote: _note.text.trim().isEmpty ? null : _note.text.trim(),
      );

      // Create alert if requested
      if (_alsoCreateAlert && alsoTarget != null) {
        await _alerts.createAlert(
          stockSymbol: widget.stock.symbol,
          alertType: _alsoAlertType,
          condition: _conditionForType(_alsoAlertType),
          targetPrice: alsoTarget,
        );
      }

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Submitted $side request (Order ID: $orderId)')),
      );
      Navigator.pop(context);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Order failed: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stock = widget.stock;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.86,
        minChildSize: 0.45,
        maxChildSize: 0.96,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),

                // Header card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${stock.symbol} • MWK ${stock.price.toStringAsFixed(2)}',
                                    style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 4),
                                Text(stock.companyName,
                                    style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: (stock.changePercent >= 0
                                      ? AppTheme.gainColor
                                      : AppTheme.lossColor)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${stock.changePercent >= 0 ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: stock.changePercent >= 0
                                    ? AppTheme.gainColor
                                    : AppTheme.lossColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 6),
                TabBar(
                  controller: _tabs,
                  tabs: const [
                    Tab(text: 'Buy'),
                    Tab(text: 'Sell'),
                    Tab(text: 'Alert'),
                  ],
                ),

                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _orderTab(scrollController, side: 'buy'),
                      _orderTab(scrollController, side: 'sell'),
                      _alertTab(scrollController),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _orderTab(ScrollController sc, {required String side}) {
    final isBuy = side == 'buy';

    return ListView(
      controller: sc,
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isBuy ? 'Buy request' : 'Sell request',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'This app does not execute trades or hold funds. Your request is routed to a licensed broker.',
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _qty,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity (shares)',
                    hintText: 'e.g. 100',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_broker?.name ?? 'Select broker'),
                  subtitle: Text(
                    _broker == null
                        ? 'Choose broker to route request'
                        : 'Fee rate: ${(_feeRate * 100).toStringAsFixed(2)}%',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickBroker,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _note,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Instruction to broker (optional)',
                    hintText: isBuy
                        ? 'e.g. Buy if price <= MWK 100.00'
                        : 'e.g. Sell if price >= MWK 150.00',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Estimate', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                _row('Subtotal', 'MWK ${_subtotal.toStringAsFixed(2)}'),
                const SizedBox(height: 6),
                _row('Broker fee', 'MWK ${_fee.toStringAsFixed(2)}'),
                const Divider(height: 18),
                _row('Total estimate', 'MWK ${_total.toStringAsFixed(2)}', bold: true),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _alsoCreateAlert,
                  onChanged: (v) => setState(() => _alsoCreateAlert = v),
                  title: const Text('Also create a price alert'),
                  subtitle: const Text('Get notified when price hits your target'),
                ),
                if (_alsoCreateAlert) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _alsoAlertType,
                    items: const [
                      DropdownMenuItem(value: 'buy', child: Text('Buy alert (price <= target)')),
                      DropdownMenuItem(value: 'sell', child: Text('Sell alert (price >= target)')),
                    ],
                    onChanged: (v) => setState(() => _alsoAlertType = v ?? 'buy'),
                    decoration: const InputDecoration(labelText: 'Alert type'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _alsoAlertTarget,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Alert target price (MWK)',
                      hintText: 'e.g. 100.00',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: _submitting ? null : () => _submitOrder(side),
            child: _submitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isBuy ? 'Submit Buy Request' : 'Submit Sell Request'),
          ),
        ),
      ],
    );
  }

  Widget _alertTab(ScrollController sc) {
    return ListView(
      controller: sc,
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Price alert', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                const Text('Alerts are informational only and do not execute trades.'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _alertType,
                  items: const [
                    DropdownMenuItem(value: 'buy', child: Text('Buy alert (price <= target)')),
                    DropdownMenuItem(value: 'sell', child: Text('Sell alert (price >= target)')),
                  ],
                  onChanged: (v) => setState(() => _alertType = v ?? 'buy'),
                  decoration: const InputDecoration(labelText: 'Alert type'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _alertTarget,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Target price (MWK)',
                    hintText: 'e.g. 100.00',
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _createStandaloneAlert,
                    child: const Text('Create alert'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
