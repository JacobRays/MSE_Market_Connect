import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mse_market_connect/shared/models/ad_model.dart';

class AdminAdService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<AdModel>> getAllAds() async {
    final response = await _client
        .from('ads')
        .select()
        .order('priority', ascending: false)
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => AdModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> upsertAd({
    int? id,
    required String title,
    String? subtitle,
    String? imageUrl,
    String? actionUrl,
    required bool isActive,
    required int priority,
  }) async {
    final payload = <String, dynamic>{
      'title': title,
      'subtitle': subtitle,
      'image_url': imageUrl,
      'action_url': actionUrl,
      'is_active': isActive,
      'priority': priority,
      if (id != null) 'id': id,
    };

    await _client.from('ads').upsert(payload, onConflict: 'id');
  }

  Future<void> deleteAd(int id) async {
    await _client.from('ads').delete().eq('id', id);
  }
}
