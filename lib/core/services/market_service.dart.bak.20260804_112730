import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mse_market_connect/shared/models/stock_model.dart';

class MarketService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<StockModel>> getStocks() async {
    final response = await _client
        .from('stocks')
        .select()
        .eq('is_active', true)
        .order('symbol', ascending: true);

    return (response as List)
        .map((item) => StockModel.fromMap(item as Map<String, dynamic>))
        .toList();
  }
}
