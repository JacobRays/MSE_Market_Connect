#!/usr/bin/env bash
set -Eeuo pipefail

FILE="lib/core/services/trade_order_service.dart"
[[ -f "$FILE" ]] || { echo "File not found: $FILE" >&2; exit 1; }

ts="$(date +%Y%m%d_%H%M%S)"
cp -a "$FILE" "${FILE}.bak.${ts}"
echo "Backup: ${FILE}.bak.${ts}"

cat > "$FILE" << 'DART'
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

    // Use wildcard select to avoid unknown-column errors (reject_reason may not exist)
    final resp = await _client
        .from('trade_orders')
        .select('*')
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
        .select('*')
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

echo "Patched: $FILE"
