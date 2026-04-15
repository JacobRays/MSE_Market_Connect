import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/price_alert_service.dart';
import 'package:mse_market_connect/core/services/subscription_service.dart';
import 'package:mse_market_connect/features/profile/presentation/upgrade_screen.dart';
import 'package:mse_market_connect/shared/models/price_alert_model.dart';

class SetPriceAlertScreen extends StatefulWidget {
  final String stockSymbol;
  final String companyName;
  final double currentPrice;
  final PriceAlertModel? existingAlert;

  const SetPriceAlertScreen({
    super.key,
    required this.stockSymbol,
    required this.companyName,
    required this.currentPrice,
    this.existingAlert,
  });

  @override
  State<SetPriceAlertScreen> createState() => _SetPriceAlertScreenState();
}

class _SetPriceAlertScreenState extends State<SetPriceAlertScreen> {
  final _alerts = PriceAlertService();
  final _subs = SubscriptionService();

  final _targetController = TextEditingController();

  String _type = 'buy'; // buy|sell
  bool _active = true;
  bool _saving = false;

  String get _condition => _type == 'buy' ? 'lte' : 'gte';

  @override
  void initState() {
    super.initState();

    final e = widget.existingAlert;
    if (e != null) {
      _type = e.alertType;
      _active = e.isActive;
      _targetController.text = e.targetPrice.toStringAsFixed(2);
    } else {
      // default suggestion
      _targetController.text = widget.currentPrice.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final target = double.tryParse(_targetController.text.trim());
    if (target == null || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid target price')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final isNew = widget.existingAlert == null;

      // Premium gate: Free users can have only 1 active alert
      if (isNew && _active) {
        final sub = await _subs.getOrCreateMySubscription();
        if (!sub.isPremium) {
          final activeCount = await _alerts.getMyActiveAlertsCount();
          if (activeCount >= 1) {
            if (!mounted) return;
            await showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Premium required'),
                content: const Text(
                  'Free users can set only 1 active price alert.\n\nUpgrade to Premium (MWK 50,000/month) for unlimited alerts.',
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
                    child: const Text('View Premium'),
                  ),
                ],
              ),
            );
            return;
          }
        }
      }

      if (widget.existingAlert == null) {
        await _alerts.createAlert(
          stockSymbol: widget.stockSymbol,
          alertType: _type,
          condition: _condition,
          targetPrice: target,
        );
      } else {
        await _alerts.updateAlert(
          id: widget.existingAlert!.id,
          alertType: _type,
          condition: _condition,
          targetPrice: target,
          isActive: _active,
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save alert: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final e = widget.existingAlert;
    if (e == null) return;

    setState(() => _saving = true);
    try {
      await _alerts.deleteAlert(e.id);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete alert: $err')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingAlert != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Price Alert' : 'Set Price Alert')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.stockSymbol,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 6),
                      Text(widget.companyName),
                      const SizedBox(height: 12),
                      Text('Current: MWK ${widget.currentPrice.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Alert type', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: _type,
                        items: const [
                          DropdownMenuItem(value: 'buy', child: Text('Buy alert (price <= target)')),
                          DropdownMenuItem(value: 'sell', child: Text('Sell alert (price >= target)')),
                        ],
                        onChanged: (v) => setState(() => _type = v ?? 'buy'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _targetController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Target price (MWK)',
                          hintText: 'e.g. 100.00',
                        ),
                      ),
                      if (isEdit) ...[
                        const SizedBox(height: 16),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _active,
                          onChanged: (v) => setState(() => _active = v),
                          title: const Text('Active'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Alert'),
                ),
              ),
              if (isEdit) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 54,
                  child: OutlinedButton(
                    onPressed: _saving ? null : _delete,
                    child: const Text('Delete Alert'),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Text(
                'Disclaimer: Alerts are informational only and do not execute trades. Orders are still routed to licensed brokers.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
