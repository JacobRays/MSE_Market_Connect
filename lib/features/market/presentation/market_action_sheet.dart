import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/broker_service.dart';
import 'package:mse_market_connect/core/services/price_alert_service.dart';
import 'package:mse_market_connect/core/services/subscription_service.dart';
import 'package:mse_market_connect/core/services/trade_order_service.dart';
import 'package:mse_market_connect/features/profile/presentation/upgrade_screen.dart';
import 'package:mse_market_connect/shared/models/broker_model.dart';
import 'package:mse_market_connect/shared/models/stock_model.dart';

class MarketActionSheet extends StatefulWidget {
  final StockModel stock;

  const MarketActionSheet({super.key, required this.stock});

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

  final _brokerService = BrokerService();
  List<BrokerModel> _brokers = [];
  bool _brokersLoading = true;

  final _qty = TextEditingController(text: '100');
  final _note = TextEditingController();
  BrokerModel? _broker;
  bool _submitting = false;

  // Alerts
  final _alerts = PriceAlertService();
  final _subs = SubscriptionService();
  final _orders = TradeOrderService();

  final _alertTarget = TextEditingController();
  String _alertType = 'buy';

  bool _alsoCreateAlert = false;
  final _alsoAlertTarget = TextEditingController();
  String _alsoAlertType = 'buy';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _alertTarget.text = widget.stock.price.toStringAsFixed(2);
    _alsoAlertTarget.text = widget.stock.price.toStringAsFixed(2);
    _loadBrokers();
  }

  Future<void> _loadBrokers() async {
    try {
      final list = await _brokerService.getActiveBrokers();
      if (!mounted) return;
      setState(() {
        _brokers = list;
        _brokersLoading = false;
        if (_broker == null && _brokers.isNotEmpty) _broker = _brokers.first;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _brokersLoading = false);
    }
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

  String _conditionForType(String type) => type == 'buy' ? 'lte' : 'gte';

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

  Future<void> _submitOrder(String side) async {
    final messenger = ScaffoldMessenger.of(context);

    if (_quantity <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Enter a valid quantity')),
      );
      return;
    }
    if (_broker == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please select a broker')),
      );
      return;
    }

    double? alsoTarget;
    if (_alsoCreateAlert) {
      alsoTarget = double.tryParse(_alsoAlertTarget.text.trim());
      if (alsoTarget == null || alsoTarget <= 0) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Enter a valid alert target price')),
        );
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
        SnackBar(content: Text('Submitted ($side). Order ID: $orderId')),
      );
      Navigator.pop(context);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Order failed: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _createAlertOnly() async {
    final messenger = ScaffoldMessenger.of(context);

    final target = double.tryParse(_alertTarget.text.trim());
    if (target == null || target <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Enter a valid target price')),
      );
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
      messenger.showSnackBar(const SnackBar(content: Text('Alert created')));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to create alert: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stock = widget.stock;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.50,
      maxChildSize: 0.96,
      builder: (context, sc) {
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
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${stock.symbol} • MWK ${stock.price.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Text(
                          '${stock.changePercent >= 0 ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
                    _orderTab(sc, side: 'buy'),
                    _orderTab(sc, side: 'sell'),
                    _alertTab(sc),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
                const SizedBox(height: 12),
                TextField(
                  controller: _qty,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity (shares)',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<BrokerModel>(
                  initialValue: _broker,
                  items: _brokers
                      .map(
                        (b) => DropdownMenuItem(value: b, child: Text(b.name)),
                      )
                      .toList(),
                  onChanged: _brokersLoading
                      ? null
                      : (b) => setState(() => _broker = b),
                  decoration: InputDecoration(
                    labelText: _brokersLoading
                        ? 'Loading brokers...'
                        : 'Broker',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _note,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Instruction to broker (optional)',
                    hintText: isBuy
                        ? 'e.g. Buy if price ≤ MWK 100'
                        : 'e.g. Sell if price ≥ MWK 150',
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
                Text(
                  'Estimate',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                _row('Subtotal', 'MWK ${_subtotal.toStringAsFixed(2)}'),
                const SizedBox(height: 6),
                _row('Broker fee', 'MWK ${_fee.toStringAsFixed(2)}'),
                const Divider(height: 18),
                _row(
                  'Total estimate',
                  'MWK ${_total.toStringAsFixed(2)}',
                  bold: true,
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
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _alsoCreateAlert,
                  onChanged: (v) => setState(() => _alsoCreateAlert = v),
                  title: const Text('Also create a price alert'),
                ),
                if (_alsoCreateAlert) ...[
                  DropdownButtonFormField<String>(
                    initialValue: _alsoAlertType,
                    items: const [
                      DropdownMenuItem(
                        value: 'buy',
                        child: Text('Buy alert (price ≤ target)'),
                      ),
                      DropdownMenuItem(
                        value: 'sell',
                        child: Text('Sell alert (price ≥ target)'),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => _alsoAlertType = v ?? 'buy'),
                    decoration: const InputDecoration(labelText: 'Alert type'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _alsoAlertTarget,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Alert target price (MWK)',
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
                Text(
                  'Price alert',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _alertType,
                  items: const [
                    DropdownMenuItem(
                      value: 'buy',
                      child: Text('Buy alert (price ≤ target)'),
                    ),
                    DropdownMenuItem(
                      value: 'sell',
                      child: Text('Sell alert (price ≥ target)'),
                    ),
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
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _createAlertOnly,
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
