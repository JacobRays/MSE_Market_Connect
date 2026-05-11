import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BrokerOrderDetailScreen extends StatefulWidget {
  final String orderId;
  const BrokerOrderDetailScreen({super.key, required this.orderId});

  @override
  State<BrokerOrderDetailScreen> createState() => _BrokerOrderDetailScreenState();
}

class _BrokerOrderDetailScreenState extends State<BrokerOrderDetailScreen> {
  Map<String, dynamic>? _order;
  bool _loading = true;
  bool _saving = false;

  String? _status;
  final _note = TextEditingController();

  static const statuses = [
    'submitted',
    'received',
    'approved',
    'rejected',
    'executed',
    'settled',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final row = await Supabase.instance.client
        .from('trade_orders')
        .select('id, stock_symbol, side, quantity, status, investor_note, broker_note, created_at, updated_at, total_estimate')
        .eq('id', widget.orderId)
        .maybeSingle();

    if (!mounted) return;
    setState(() {
      _order = row as Map<String, dynamic>?;
      _status = _order?['status'] as String?;
      _note.text = (_order?['broker_note'] as String?) ?? '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_order == null) return;
    setState(() => _saving = true);

    try {
      await Supabase.instance.client
          .from('trade_orders')
          .update({
            'status': _status,
            'broker_note': _note.text.trim().isEmpty ? null : _note.text.trim(),
          })
          .eq('id', widget.orderId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Updated')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order (Broker)')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_order == null)
              ? const Center(child: Text('Order not found'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          '${_order!['stock_symbol']} • ${(_order!['side'] as String).toUpperCase()}\n'
                          'Qty: ${_order!['quantity']}\n'
                          'Status: ${_order!['status']}\n'
                          'Total: ${_order!['total_estimate'] ?? '—'}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: _status,
                              items: statuses
                                  .map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase())))
                                  .toList(),
                              onChanged: (v) => setState(() => _status = v),
                              decoration: const InputDecoration(labelText: 'Update status'),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _note,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Broker note (optional)',
                                hintText: 'Reason for rejection / execution notes',
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _saving ? null : _save,
                                child: _saving
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('Save'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
