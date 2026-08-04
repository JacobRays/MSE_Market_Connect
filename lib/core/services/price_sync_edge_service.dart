import 'package:supabase_flutter/supabase_flutter.dart';

class PriceSyncEdgeService {
  final _functions = Supabase.instance.client.functions;

  Future<int> syncNow() async {
    final res = await _functions.invoke(
      'sync-prices',
    ); // make sure your Edge Function is deployed with this name
    final data = res.data;
    if (data is Map && data['updated'] != null) {
      final n = data['updated'];
      if (n is num) return n.toInt();
      return int.tryParse(n.toString()) ?? 0;
    }
    // fall back to a generic parse if needed
    return 0;
  }
}
