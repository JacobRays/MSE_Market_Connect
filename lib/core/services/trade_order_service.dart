import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mse_market_connect/shared/models/broker_model.dart';
import 'package:mse_market_connect/shared/models/stock_model.dart';

class TradeOrderService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String> createBuyOrder({
    required StockModel stock,
    required BrokerModel broker,
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

    final inserted = await _client.from('trade_orders').insert({
      'user_id': user.id,
      'broker_id': broker.id,
      'stock_symbol': stock.symbol,
      'side': 'buy',
      'quantity': quantity,
      'price_at_submission': priceAtSubmission,
      'fee_rate': feeRate,
      'fee_amount': feeAmount,
      'total_estimate': totalEstimate,
      'status': 'submitted',
      'investor_note': investorNote,
    }).select('id').single();

    return inserted['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getMyOrders() async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('User not logged in');

    final response = await _client
        .from('trade_orders')
        .select('id, stock_symbol, side, quantity, status, created_at, total_estimate')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (response as List).cast<Map<String, dynamic>>();
  }
}
