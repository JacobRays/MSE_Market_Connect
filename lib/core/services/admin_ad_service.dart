import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mse_market_connect/shared/models/ad_model.dart';

class AdminAdService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<AdModel>> getAllAds() async {
    final res = await _client
        .from('ads')
        .select()
        .order('priority', ascending: false)
        .order('created_at', ascending: false);

    return (res as List)
        .map((e) => AdModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createAd({
    required String title,
    String? subtitle,
    String? imageUrl,
    String? actionUrl,
    required bool isActive,
    required int priority,
  }) async {
    await _client.from('ads').insert({
      'title': title,
      'subtitle': subtitle,
      'image_url': imageUrl,
      'action_url': actionUrl,
      'is_active': isActive,
      'priority': priority,
    });
  }

  Future<void> updateAd({
    required int id,
    required String title,
    String? subtitle,
    String? imageUrl,
    String? actionUrl,
    required bool isActive,
    required int priority,
  }) async {
    await _client
        .from('ads')
        .update({
          'title': title,
          'subtitle': subtitle,
          'image_url': imageUrl,
          'action_url': actionUrl,
          'is_active': isActive,
          'priority': priority,
        })
        .eq('id', id);
  }

  Future<void> setActive({required int id, required bool isActive}) async {
    await _client.from('ads').update({'is_active': isActive}).eq('id', id);
  }

  Future<void> deleteAd(int id) async {
    await _client.from('ads').delete().eq('id', id);
  }
}
