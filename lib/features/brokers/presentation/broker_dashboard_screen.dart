import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/broker_service.dart';
import 'package:mse_market_connect/core/services/broker_user_service.dart';
import 'package:mse_market_connect/shared/models/broker_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'broker_order_detail_screen.dart';

class BrokerDashboardScreen extends StatefulWidget {
  const BrokerDashboardScreen({super.key});

  @override
  State<BrokerDashboardScreen> createState() => _BrokerDashboardScreenState();
}

class _BrokerDashboardScreenState extends State<BrokerDashboardScreen> {
  final _brokerUserService = BrokerUserService();
  final _brokerService = BrokerService();

  bool _loading = true;
  String? _error;

  bool _isAdmin = false;

  // broker view
  String? _brokerId;
  bool _approved = false;

  // admin view
  List<BrokerModel> _brokers = [];
  BrokerModel? _selectedBroker;

  // orders
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Detect admin from profiles role
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw StateError('Not logged in');

      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      _isAdmin = (profile?['role'] as String?) == 'admin';

      if (_isAdmin) {
        _brokers = await _brokerService.getActiveBrokers();
        if (_brokers.isNotEmpty) {
          _selectedBroker = _brokers.first;
        }
      } else {
        final row = await _brokerUserService.getMyBrokerUserRow();
        _brokerId = row?['broker_id'] as String?;
        _approved = row?['is_approved'] as bool? ?? false;
      }

      await _loadOrders();

      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadOrders() async {
    final client = Supabase.instance.client;

    // If broker (not admin) and not approved yet, show empty
    if (!_isAdmin && (!_approved || _brokerId == null)) {
      _orders = [];
      return;
    }

    final brokerIdToUse = _isAdmin ? _selectedBroker?.id : _brokerId;
    if (brokerIdToUse == null) {
      _orders = [];
      return;
    }

    final resp = await client
        .from('trade_orders')
        .select('id, stock_symbol, side, quantity, status, total_estimate, created_at, updated_at')
        .eq('broker_id', brokerIdToUse)
        .order('created_at', ascending: false)
        .limit(200);

    _orders = (resp as List).cast<Map<String, dynamic>>();
  }

  Future<void> _refresh() async {
    await _loadOrders();
    if (!mounted) return;
    setState(() {});
  }

  String _fmt(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Broker Dashboard')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: $_error'),
        ),
      );
    }

    if (!_isAdmin && !_approved) {
      return Scaffold(
        appBar: AppBar(title: const Text('Broker Dashboard')),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Your broker account is pending admin approval.\n\nPlease contact the admin.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isAdmin ? 'Broker Dashboard (Admin)' : 'Broker Dashboard'),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (_isAdmin) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: DropdownButtonFormField<BrokerModel>(
                    initialValue: _selectedBroker,
                    items: _brokers
                        .map((b) => DropdownMenuItem(value: b, child: Text(b.name)))
                        .toList(),
                    onChanged: (b) async {
                      setState(() => _selectedBroker = b);
                      await _refresh();
                    },
                    decoration: const InputDecoration(labelText: 'View broker inbox'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_orders.isEmpty) ...[
              const SizedBox(height: 30),
              const Center(child: Text('No orders found.')),
            ] else ...[
              ..._orders.map((o) {
                final total = (o['total_estimate'] as num?)?.toDouble();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ListTile(
                      title: Text('${o['stock_symbol']} • ${(o['side'] as String).toUpperCase()}'),
                      subtitle: Text(
                        'Qty: ${o['quantity']}  •  Status: ${o['status']}\n'
                        'Total: ${total == null ? '—' : 'MWK ${total.toStringAsFixed(2)}'}\n'
                        'Created: ${_fmt(o['created_at'] as String)}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BrokerOrderDetailScreen(orderId: o['id'] as String),
                          ),
                        );
                        await _refresh();
                      },
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
