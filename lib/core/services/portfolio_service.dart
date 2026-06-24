import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mse_market_connect/shared/models/holding_model.dart';

class PortfolioService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<HoldingModel>> getMyHoldings() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('portfolio_holdings')
        .select(
          'stock_symbol, shares, avg_cost, stocks(price, company_name, change_percent)',
        )
        .eq('user_id', user.id)
        .gt('shares', 0);

    return (response as List).map((e) {
      final stock = e['stocks'] as Map<String, dynamic>?;

      final symbol = (e['stock_symbol'] ?? '').toString().toUpperCase();
      final shares = (e['shares'] as num?)?.toInt() ?? 0;
      final avgCost = (e['avg_cost'] as num?)?.toDouble() ?? 0.0;

      final price = (stock?['price'] as num?)?.toDouble() ?? 0.0;
      final companyName = (stock?['company_name'] ?? '').toString();
      final changePercent =
          (stock?['change_percent'] as num?)?.toDouble() ?? 0.0;

      return HoldingModel(
        symbol: symbol,
        shares: shares,
        avgCost: avgCost,
        currentPrice: price,
        companyName: companyName,
        changePercent: changePercent,
      );
    }).toList();
  }
}
