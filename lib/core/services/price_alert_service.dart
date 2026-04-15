import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mse_market_connect/shared/models/price_alert_model.dart';

class PriceAlertService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<PriceAlertModel>> getMyAlerts({bool activeOnly = false}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('User not logged in');

    // 1) Get alerts
    final builder = _client
        .from('price_alerts')
        .select()
        .eq('user_id', user.id);

    final response = await (activeOnly
        ? builder.eq('is_active', true)
        : builder).order('created_at', ascending: false);

    final alertsRaw = (response as List).cast<Map<String, dynamic>>();

    if (alertsRaw.isEmpty) return [];

    // 2) Get related stock info for display (company name, current price, % change)
    final symbols = alertsRaw
        .map((e) => e['stock_symbol'] as String?)
        .whereType<String>()
        .toSet()
        .toList();

    final stocksResp = await _client
        .from('stocks')
        .select('symbol, company_name, price, change_percent')
        .inFilter('symbol', symbols);

    final stocksList = (stocksResp as List).cast<Map<String, dynamic>>();
    final bySymbol = <String, Map<String, dynamic>>{
      for (final s in stocksList) (s['symbol'] as String): s,
    };

    // 3) Merge stock map into each alert record under the key "stocks"
    final merged = alertsRaw.map((a) {
      final sym = a['stock_symbol'] as String?;
      if (sym != null && bySymbol.containsKey(sym)) {
        return {
          ...a,
          'stocks': bySymbol[sym],
        };
      }
      return a;
    }).toList();

    return merged.map(PriceAlertModel.fromMap).toList();
  }

  Future<int> getMyActiveAlertsCount() async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('User not logged in');

    final response = await _client
        .from('price_alerts')
        .select('id')
        .eq('user_id', user.id)
        .eq('is_active', true);

    return (response as List).length;
  }

  Future<void> createAlert({
    required String stockSymbol,
    required String alertType, // buy|sell
    required String condition, // gte|lte
    required double targetPrice,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('User not logged in');

    await _client.from('price_alerts').insert({
      'user_id': user.id,
      'stock_symbol': stockSymbol,
      'alert_type': alertType,
      'condition': condition,
      'target_price': targetPrice,
      'is_active': true,
    });
  }

  Future<void> updateAlert({
    required int id,
    required String alertType,
    required String condition,
    required double targetPrice,
    required bool isActive,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('User not logged in');

    await _client
        .from('price_alerts')
        .update({
          'alert_type': alertType,
          'condition': condition,
          'target_price': targetPrice,
          'is_active': isActive,
        })
        .eq('id', id)
        .eq('user_id', user.id);
  }

  Future<void> deleteAlert(int id) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('User not logged in');

    await _client
        .from('price_alerts')
        .delete()
        .eq('id', id)
        .eq('user_id', user.id);
  }
}
