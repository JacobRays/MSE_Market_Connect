import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mse_market_connect/shared/models/holding_model.dart';

class PortfolioService {
  final _client = Supabase.instance.client;

  Future<List<HoldingModel>> getMyHoldings() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    // Join with stocks to get current price and company name
    final response = await _client
        .from('portfolio_holdings')
        .select('*, stocks(price, company_name)')
        .eq('user_id', user.id)
        .gt('shares', 0);

    return (response as List).map((e) {
      final stock = e['stocks'];
      return HoldingModel(
        symbol: e['stock_symbol'],
        shares: e['shares'],
        avgCost: (e['avg_cost'] as num).toDouble(),
        currentPrice: (stock['price'] as num).toDouble(),
        companyName: stock['company_name'] ?? '',
      );
    }).toList();
  }
}
