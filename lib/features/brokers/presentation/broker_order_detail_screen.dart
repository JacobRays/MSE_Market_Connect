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
  String? _status;
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final row = await Supabase.instance.client
        .from('trade_orders')
        .select('*, profiles!user_id(email, full_name, phone)')
        .eq('id', widget.orderId)
        .maybeSingle();

    if (mounted) {
      setState(() {
        _order = row;
        _status = _order?['status'];
        _note.text = _order?['broker_note'] ?? '';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    await Supabase.instance.client.from('trade_orders').update({
      'status': _status,
      'broker_note': _note.text,
    }).eq('id', widget.orderId);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order Updated & User Notified')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    final profile = _order?['profiles'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(title: const Text('Review Order')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.blue.shade50,
            child: ListTile(
              title: const Text('SENDER DETAILS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              subtitle: Text('Name: ${profile?['full_name'] ?? 'Not set'}\nEmail: ${profile?['email']}\nPhone: ${profile?['phone'] ?? 'Not provided'}\nUser ID: ${_order?['user_id']}'),
            ),
          ),
          const SizedBox(height: 16),
          Text('Order: ${_order?['stock_symbol']} ${_order?['side']?.toString().toUpperCase()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('Quantity: ${_order?['quantity']}'),
          const Divider(),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _status,
            items: ['submitted', 'received', 'approved', 'rejected', 'executed', 'settled']
                .map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
            onChanged: (v) => setState(() => _status = v),
            decoration: const InputDecoration(labelText: 'Set Status'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _note,
            decoration: const InputDecoration(labelText: 'Response / Note to User', hintText: 'Example: Payment not seen'),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _save, child: const Text('SAVE & NOTIFY USER')),
        ],
      ),
    );
  }
}
