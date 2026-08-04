#!/usr/bin/env bash
set -Eeuo pipefail

backup() { [[ -f "$1" ]] && cp -a "$1" "$1.bak.$(date +%Y%m%d_%H%M%S)" && echo "Backup: $1.bak.*"; }

SERVICE="lib/core/services/trade_order_service.dart"
SCREEN="lib/features/trade/presentation/my_orders_screen.dart"
UTIL_DIR="lib/shared/utils"

# 1) CSV download utils with conditional import (web only implementation)
mkdir -p "$UTIL_DIR"
cat > "$UTIL_DIR/csv_download.dart" << 'DART'
export 'csv_download_stub.dart' if (dart.library.html) 'csv_download_web.dart';
DART

cat > "$UTIL_DIR/csv_download_stub.dart" << 'DART'
Future<bool> downloadCsv(String filename, String csvContent) async {
  // Non-web platforms: no-op (you can wire share/file-saver later)
  return false;
}
DART

cat > "$UTIL_DIR/csv_download_web.dart" << 'DART'
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<bool> downloadCsv(String filename, String csvContent) async {
  final bytes = html.Blob([csvContent], 'text/csv;charset=utf-8;');
  final url = html.Url.createObjectUrlFromBlob(bytes);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
  return true;
}
DART

# 2) Service: add pagination, cancel order, and use trade_orders_app for reads
backup "$SERVICE"
cat > "$SERVICE" << 'DART'
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mse_market_connect/shared/models/broker_model.dart';
import 'package:mse_market_connect/shared/models/stock_model.dart';
import 'package:mse_market_connect/shared/models/trade_order_model.dart';

class TradeOrderService {
  final SupabaseClient _client = Supabase.instance.client;

  // Create order (unchanged)
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

  // Legacy helper kept for compatibility
  Future<List<TradeOrderModel>> getMyOrders({int limit = 100}) async {
    final page = await getMyOrdersPage(limit: limit, offset: 0);
    return page.items;
  }

  // Filtered (non-paged) helper
  Future<List<TradeOrderModel>> getMyOrdersFiltered({
    String? status,
    bool ascending = false,
    int limit = 200,
  }) async {
    final page = await getMyOrdersPage(status: status, ascending: ascending, limit: limit, offset: 0);
    return page.items;
  }

  // Paged API (server-side pagination via range)
  Future<OrdersPage> getMyOrdersPage({
    String? status,
    bool ascending = false,
    int limit = 30,
    int offset = 0,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('User not logged in');

    var q = _client
        .from('trade_orders_app') // view with unified reject_reason
        .select('*')
        .eq('user_id', user.id)
        .isFilter('deleted_at', null);

    if (status != null && status.trim().isNotEmpty) {
      q = q.eq('status', status);
    }

    q = q.order('created_at', ascending: ascending);

    // Ask for limit+1 (inclusive range end) to detect "hasMore"
    final rows = await q.range(offset, offset + limit);

    var list = (rows as List).cast<Map<String, dynamic>>();
    final hasMore = list.length > limit;
    if (hasMore) list = list.sublist(0, limit);

    // Attach broker names
    final models = list.map((e) => TradeOrderModel.fromMap(e)).toList();
    if (models.isEmpty) return OrdersPage(items: const [], hasMore: false, nextOffset: offset);

    final brokerIds = models.map((o) => o.brokerId).toSet().toList();
    final brokersResp = await _client
        .from('brokers')
        .select('id,name')
        .inFilter('id', brokerIds);

    final brokers = (brokersResp as List).cast<Map<String, dynamic>>();
    final nameById = {for (final b in brokers) b['id'] as String: b['name'] as String};

    final enriched = models.map((o) => o.copyWith(brokerName: nameById[o.brokerId])).toList();
    return OrdersPage(items: enriched, hasMore: hasMore, nextOffset: offset + enriched.length);
  }

  // Single order (use the view so reject_reason is unified)
  Future<TradeOrderModel?> getMyOrderById(String orderId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('User not logged in');

    final row = await _client
        .from('trade_orders_app')
        .select('*')
        .eq('user_id', user.id)
        .eq('id', orderId)
        .isFilter('deleted_at', null)
        .maybeSingle();

    if (row == null) return null;
    return TradeOrderModel.fromMap(Map<String, dynamic>.from(row));
  }

  // Hide (soft delete)
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

  // Cancel (allowed for submitted/approved)
  // Adjust 'canceled' -> 'cancelled' if your DB uses British spelling.
  Future<void> cancelMyOrder(String orderId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('User not logged in');

    final row = await _client
        .from('trade_orders')
        .select('status')
        .eq('id', orderId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (row == null) throw StateError('Order not found');

    final status = (row['status'] ?? 'submitted').toString().toLowerCase();
    if (status != 'submitted' && status != 'approved') {
      throw StateError('Only submitted/approved orders can be canceled (current: $status)');
    }

    await _client
        .from('trade_orders')
        .update({'status': 'canceled', 'updated_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', orderId)
        .eq('user_id', user.id);
  }
}

class OrdersPage {
  final List<TradeOrderModel> items;
  final bool hasMore;
  final int nextOffset;
  OrdersPage({required this.items, required this.hasMore, required this.nextOffset});
}
DART

# 3) Screen: infinite scroll + filters + saved sort + cancel + CSV export
backup "$SCREEN"
cat > "$SCREEN" << 'DART'
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mse_market_connect/core/services/trade_order_service.dart';
import 'package:mse_market_connect/shared/models/trade_order_model.dart';
import 'package:mse_market_connect/shared/utils/csv_download.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  final _scroll = ScrollController();

  List<TradeOrderModel> _orders = [];
  bool _loading = true;
  String? _error;

  OrderSort _sort = OrderSort.newest;
  String? _statusFilter; // null = All

  // paging
  static const _pageSize = 30;
  int _offset = 0;
  bool _hasMore = true;
  bool _loadingMore = false;

  RealtimeChannel? _ordersChannel;
  Timer? _debounce;

  static const _prefSort = 'orders_sort';
  static const _prefFilter = 'orders_filter';

  static const List<String> _statuses = [
    'submitted',
    'approved',
    'rejected',
    'executed',
    'settled',
  ];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadPrefs().then((_) {
      _load(reset: true);
      _listenRealtime();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    if (_ordersChannel != null) {
      Supabase.instance.client.removeChannel(_ordersChannel!);
    }
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final sortStr = prefs.getString(_prefSort);
    final filt = prefs.getString(_prefFilter);
    setState(() {
      _sort = sortStr == 'oldest' ? OrderSort.oldest : OrderSort.newest;
      _statusFilter = (filt == null || filt.isEmpty) ? null : filt;
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefSort, _sort == OrderSort.oldest ? 'oldest' : 'newest');
    await prefs.setString(_prefFilter, _statusFilter ?? '');
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _orders = [];
        _offset = 0;
        _hasMore = true;
      });
    }
    try {
      final page = await _service.getMyOrdersPage(
        status: _statusFilter,
        ascending: _sort == OrderSort.oldest,
        limit: _pageSize,
        offset: _offset,
      );
      setState(() {
        _orders = reset ? page.items : [..._orders, ...page.items];
        _offset = page.nextOffset;
        _hasMore = page.hasMore;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _loading) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 240) {
      _loadingMore = true;
      _load(reset: false).whenComplete(() {
        _loadingMore = false;
      });
    }
  }

  void _scheduleReload() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _load(reset: true);
    });
  }

  void _listenRealtime() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _ordersChannel = Supabase.instance.client
        .channel('orders-live-${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'trade_orders',
          callback: (payload) {
            final rec = payload.newRecord.isNotEmpty ? payload.newRecord : payload.oldRecord;
            if (rec.isEmpty) return;
            if ((rec['user_id'] ?? '') != user.id) return;
            _scheduleReload();
          },
        )
        .subscribe();
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
        await _load(reset: true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order hidden')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _confirmCancel(TradeOrderModel o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel order?'),
        content: Text(
          'Only submitted or approved orders can be canceled.\n\n${o.stockSymbol} ${o.side.toUpperCase()} • Qty ${o.quantity}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, cancel')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _service.cancelMyOrder(o.id);
        await _load(reset: true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order canceled')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  void _openSheet(TradeOrderModel o) {
    final isRejected = o.status.toLowerCase() == 'rejected';
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
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
              _kv('Status', o.status.toUpperCase(), valueColor: isRejected ? Colors.red : null),
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

  Widget _filters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: _statusFilter == null,
            onSelected: (v) {
              setState(() => _statusFilter = null);
              _savePrefs();
              _load(reset: true);
            },
          ),
          const SizedBox(width: 8),
          ..._statuses.map((s) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: FilterChip(
                  label: Text(s[0].toUpperCase() + s.substring(1)),
                  selected: _statusFilter == s,
                  onSelected: (v) {
                    setState(() => _statusFilter = v ? s : null);
                    _savePrefs();
                    _load(reset: true);
                  },
                ),
              )),
        ],
      ),
    );
  }

  Future<void> _exportCsv() async {
    try {
      final all = await _service.getMyOrdersFiltered(
        status: _statusFilter,
        ascending: true,
        limit: 2000, // adjust if you want more
      );
      final buf = StringBuffer();
      buf.writeln('Order ID,Date,Stock,Side,Quantity,Status,Broker,Total Estimate,Reject Reason');
      for (final o in all) {
        final dt = DateFormat('yyyy-MM-dd HH:mm').format(o.createdAt);
        final te = (o.totalEstimate ?? 0).toStringAsFixed(2);
        final rr = (o.rejectReason ?? '').replaceAll('"', '""');
        final br = (o.brokerName ?? o.brokerId).replaceAll('"', '""');
        buf.writeln([
          o.id,
          dt,
          o.stockSymbol,
          o.side.toUpperCase(),
          o.quantity,
          o.status.toUpperCase(),
          '"$br"',
          te,
          '"$rr"',
        ].join(','));
      }
      final ok = await downloadCsv('my_orders_${DateTime.now().toIso8601String().substring(0,10)}.csv', buf.toString());
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV downloaded')));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('CSV export not supported on this platform')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            icon: const Icon(Icons.download_outlined),
            onPressed: _exportCsv,
          ),
          PopupMenuButton<OrderSort>(
            tooltip: 'Sort',
            initialValue: _sort,
            onSelected: (val) {
              setState(() => _sort = val);
              _savePrefs();
              _load(reset: true);
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
        onRefresh: () => _load(reset: true),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : (_error != null)
                ? ListView(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      const SizedBox(height: 40),
                      Text('Failed to load orders.\n$_error'),
                    ],
                  )
                : ListView.builder(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length + 2, // filters + items + loader
                    itemBuilder: (context, i) {
                      if (i == 0) return Column(children: [ _filters(), const SizedBox(height: 8) ]);
                      final idx = i - 1;
                      if (idx < _orders.length) {
                        final o = _orders[idx];
                        final isRejected = o.status.toLowerCase() == 'rejected';
                        final canCancel = o.status.toLowerCase() == 'submitted' || o.status.toLowerCase() == 'approved';
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
                            trailing: Wrap(
                              spacing: 4,
                              children: [
                                if (canCancel)
                                  IconButton(
                                    icon: const Icon(Icons.cancel_outlined),
                                    tooltip: 'Cancel',
                                    onPressed: () => _confirmCancel(o),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: 'Hide',
                                  onPressed: () => _confirmDelete(o),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      // loader row at end
                      if (_hasMore) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
      ),
    );
  }
}
DART

echo "==> Upgrade complete. Rebuild now."
