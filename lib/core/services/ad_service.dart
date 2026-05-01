import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mse_market_connect/shared/models/ad_model.dart';

class AdService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<AdModel>> getActiveAds({int limit = 5}) async {
    final response = await _client
        .from('ads')
        .select()
        .eq('is_active', true)
        .order('priority', ascending: false)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((e) => AdModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
