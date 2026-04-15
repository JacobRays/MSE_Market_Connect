import 'package:supabase_flutter/supabase_flutter.dart';

class WatchlistService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Set<String>> getMyWatchlistSymbols() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User not logged in');
    }

    final response = await _client
        .from('watchlist_items')
        .select('stock_symbol')
        .eq('user_id', user.id);

    final list = (response as List)
        .map((e) => (e as Map<String, dynamic>)['stock_symbol'] as String)
        .toSet();

    return list;
  }

  Future<void> addToWatchlist(String symbol) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User not logged in');
    }

    await _client.from('watchlist_items').insert({
      'user_id': user.id,
      'stock_symbol': symbol,
    });
  }

  Future<void> removeFromWatchlist(String symbol) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User not logged in');
    }

    await _client
        .from('watchlist_items')
        .delete()
        .eq('user_id', user.id)
        .eq('stock_symbol', symbol);
  }
}
