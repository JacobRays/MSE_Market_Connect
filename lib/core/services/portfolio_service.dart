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
          'stock_symbol, shares, avg_cost, stocks(price, company_name, change_percent, logo_url)',
        )
        .eq('user_id', user.id)
        .gt('shares', 0);

    return (response as List).map((e) {
      final stock = e['stocks'] as Map<String, dynamic>?;

      return HoldingModel(
        symbol: (e['stock_symbol'] ?? '').toString(),
        shares: (e['shares'] as num?)?.toInt() ?? 0,
        avgCost: (e['avg_cost'] as num?)?.toDouble() ?? 0.0,
        currentPrice: (stock?['price'] as num?)?.toDouble() ?? 0.0,
        changePercent: (stock?['change_percent'] as num?)?.toDouble() ?? 0.0,
        companyName: (stock?['company_name'] ?? '').toString(),
        logoUrl: stock?['logo_url'] as String?,
      );
    }).toList();
  }
}
