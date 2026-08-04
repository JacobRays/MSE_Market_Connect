#!/usr/bin/env bash
set -Eeuo pipefail

backup() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  local ts
  ts="$(date +%Y%m%d_%H%M%S)"
  cp -a "$f" "${f}.bak.${ts}"
  echo "Backup: ${f}.bak.${ts}"
}

MODEL="lib/shared/models/trade_order_model.dart"
SERVICE="lib/core/services/trade_order_service.dart"
SCREEN="lib/features/trade/presentation/my_orders_screen.dart"

echo "==> Patching model (add rejectReason)"
backup "$MODEL"
cat > "$MODEL" << 'DART'
class TradeOrderModel {
  final String id;
  final String stockSymbol; // e.g. 'AHL'
  final String side;        // 'buy' | 'sell'
  final int quantity;
  final String status;

  final String brokerId;
  final String? brokerName;

  final double? totalEstimate;

  final String? rejectReason; // optional: reason from broker when status == 'rejected'

  final DateTime createdAt;
  final DateTime updatedAt;

  const TradeOrderModel({
    required this.id,
    required this.stockSymbol,
    required this.side,
    required this.quantity,
    required this.status,
    required this.brokerId,
    required this.createdAt,
    required this.updatedAt,
    this.brokerName,
    this.totalEstimate,
    this.rejectReason,
  });

  factory TradeOrderModel.fromMap(Map<String, dynamic> map) {
    String? rr = map['reject_reason'] as String?;
    rr ??= map['rejection_reason'] as String?;
    rr ??= map['broker_reason'] as String?;
    rr ??= map['reason'] as String?;

    return TradeOrderModel(
      id: map['id'] as String,
      stockSymbol: map['stock_symbol'] as String,
      side: map['side'] as String,
      quantity: (map['quantity'] as num).toInt(),
      status: (map['status'] as String?) ?? 'submitted',
      brokerId: map['broker_id'] as String,
      totalEstimate: (map['total_estimate'] as num?)?.toDouble(),
      rejectReason: rr,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  TradeOrderModel copyWith({
    String? brokerName,
    String? rejectReason,
  }) {
    return TradeOrderModel(
      id: id,
      stockSymbol: stockSymbol,
      side: side,
      quantity: quantity,
      status: status,
      brokerId: brokerId,
      brokerName: brokerName ?? this.brokerName,
      totalEstimate: totalEstimate,
      createdAt: createdAt,
      updatedAt: updatedAt,
      rejectReason: rejectReason ?? this.rejectReason,
    );
  }
}
DART

echo
echo "==> Patching service (include reject_reason, keep soft delete & getMyOrderById)"
backup "$SERVICE"
cat > "$SERVICE" << 'DART'
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mse_market_connect/shared/models/broker_model.dart';
import 'package:mse_market_connect/shared/models/stock_model.dart';
import 'package:mse_market_connect/shared/models/trade_order_model.dart';

class TradeOrderService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String> createMarketRequestOrder({
    required StockModel stock,
    required BrokerModel broker,
    required String side,
    required int quantity,
    String? investorNote,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('User not logged in');

    final priceAtSubmission = stock.price;
    final feeRate = broker.feeRate;

    final subtotal = quantity * priceAtSubmission;
    final feeAmount = subtotal * feeRate;
    final totalEstimate = subtotal + feeAmount;

    final inserted = await _client
        .from('trade_orders')
        .insert({
          'user_id': user.id,
          'broker_id': broker.id,
          'stock_symbol': stock.symbol,
          'side': side,
          'quantity': quantity,
          'price_at_submission': priceAtSubmission,
          'fee_rate': feeRate,
          'fee_amount': feeAmount,
          'total_estimate': totalEstimate,
          'status': 'submitted',
          'investor_note': investorNote,
          'deleted_at': null,
        })
        .select('id')
        .single();

    return inserted['id'] as String;
  }

  Future<List<TradeOrderModel>> getMyOrders({int limit = 100}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('User not logged in');

    final resp = await _client
        .from('trade_orders')
        .select(
          'id, stock_symbol, side, quantity, status, broker_id, total_estimate, reject_reason, created_at, updated_at',
        )
        .eq('user_id', user.id)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(limit);

    final orders = (resp as List)
        .map((e) => TradeOrderModel.fromMap(e as Map<String, dynamic>))
        .toList();

    if (orders.isEmpty) return [];

    // Attach broker names
    final brokerIds = orders.map((o) => o.brokerId).toSet().toList();
    final brokersResp = await _client
        .from('brokers')
        .select('id,name')
        .inFilter('id', brokerIds);

    final brokers = (brokersResp as List).cast<Map<String, dynamic>>();
    final nameById = {for (final b in brokers) b['id'] as String: b['name'] as String};

    return orders
        .map((o) => o.copyWith(brokerName: nameById[o.brokerId]))
        .toList();
  }

  Future<TradeOrderModel?> getMyOrderById(String orderId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('User not logged in');

    final row = await _client
        .from('trade_orders')
        .select(
          'id, stock_symbol, side, quantity, status, broker_id, total_estimate, reject_reason, created_at, updated_at',
        )
        .eq('user_id', user.id)
        .eq('id', orderId)
        .isFilter('deleted_at', null)
        .maybeSingle();

    if (row == null) return null;
    return TradeOrderModel.fromMap(Map<String, dynamic>.from(row));
  }

  Future<void> softDeleteMyOrder(String orderId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('User not logged in');

    final row = await _client
        .from('trade_orders')
        .select('status')
        .eq('id', orderId)
        .eq('user_id', user.id)
        .maybeSingle();

    final status = (row?['status'] ?? 'submitted').toString().toLowerCase();
    if (status == 'executed' || status == 'settled') {
      throw StateError('Cannot delete an $status order');
    }

    await _client
        .from('trade_orders')
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', orderId)
        .eq('user_id', user.id);
  }
}
DART

echo
echo "==> Patching MyOrdersScreen (sort toggle, delete/hide, bottom-sheet details)"
backup "$SCREEN"
cat > "$SCREEN" << 'DART'
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mse_market_connect/core/services/trade_order_service.dart';
import 'package:mse_market_connect/shared/models/trade_order_model.dart';
import 'order_detail_screen.dart';

enum OrderSort { newest, oldest }

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final _service = TradeOrderService();
  final _fmt = DateFormat('yMMMd • HH:mm');

  List<TradeOrderModel> _orders = [];
  bool _loading = true;
  String? _error;
  OrderSort _sort = OrderSort.newest;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _service.getMyOrders(limit: 200);
      _applySort(items);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applySort(List<TradeOrderModel> src) {
    final copy = [...src];
    copy.sort((a, b) =>
        _sort == OrderSort.newest ? b.createdAt.compareTo(a.createdAt) : a.createdAt.compareTo(b.createdAt));
    setState(() => _orders = copy);
  }

  Future<void> _confirmDelete(TradeOrderModel o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hide this order?'),
        content: Text(
          'This will hide the order from your list (soft delete). You can’t hide executed/settled orders.\n\n${o.stockSymbol} ${o.side.toUpperCase()} • Qty ${o.quantity}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hide')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _service.softDeleteMyOrder(o.id);
        await _load();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order hidden')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  void _openSheet(TradeOrderModel o) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final isRejected = o.status.toLowerCase() == 'rejected';
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: Text('${o.stockSymbol} • ${o.side.toUpperCase()}',
                    style: Theme.of(context).textTheme.titleLarge),
                subtitle: Text('Qty: ${o.quantity} • ${_fmt.format(o.createdAt)}'),
              ),
              const Divider(),
              _kv('Status', o.status.toUpperCase(),
                  valueColor: isRejected ? Colors.red : null),
              if (isRejected && (o.rejectReason ?? '').trim().isNotEmpty)
                _kv('Reason', o.rejectReason!.trim()),
              if (o.brokerName != null) _kv('Broker', o.brokerName!),
              if (o.totalEstimate != null)
                _kv('Total estimate', 'MWK ${o.totalEstimate!.toStringAsFixed(2)}'),
              _kv('Created', _fmt.format(o.createdAt)),
              _kv('Updated', _fmt.format(o.updatedAt)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open full screen'),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: o.id)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _kv(String k, String v, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(k, style: const TextStyle(color: Colors.black54))),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              v,
              style: TextStyle(fontWeight: FontWeight.w600, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        actions: [
          PopupMenuButton<OrderSort>(
            tooltip: 'Sort',
            initialValue: _sort,
            onSelected: (val) {
              setState(() => _sort = val);
              _applySort(_orders);
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: OrderSort.newest,
                child: ListTile(
                  leading: Icon(Icons.arrow_downward),
                  title: Text('Newest first'),
                ),
              ),
              PopupMenuItem(
                value: OrderSort.oldest,
                child: ListTile(
                  leading: Icon(Icons.arrow_upward),
                  title: Text('Oldest first'),
                ),
              ),
            ],
            icon: const Icon(Icons.sort),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : (_error != null)
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      const SizedBox(height: 40),
                      Text('Failed to load orders.\n$_error'),
                    ],
                  )
                : _orders.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        children: const [
                          SizedBox(height: 40),
                          Center(child: Text('No orders yet')),
                        ],
                      )
                    : ListView.separated(
                        itemCount: _orders.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final o = _orders[i];
                          final isRejected = o.status.toLowerCase() == 'rejected';
                          return Card(
                            child: ListTile(
                              onTap: () => _openSheet(o),
                              title: Text('${o.stockSymbol} ${o.side.toUpperCase()}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Qty: ${o.quantity} • ${_fmt.format(o.createdAt)}'),
                                  Row(
                                    children: [
                                      Text(
                                        'Status: ${o.status.toUpperCase()}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: isRejected ? Colors.red : null,
                                        ),
                                      ),
                                      if (isRejected && (o.rejectReason ?? '').trim().isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        const Text('•'),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Reason: ${o.rejectReason!}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: Colors.black87),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                tooltip: 'Hide',
                                onPressed: () => _confirmDelete(o),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
DART

echo
echo "==> Done. Now rebuild:"
echo "   flutter clean && flutter pub get && flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080"
