import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mse_market_connect/shared/models/broker_model.dart';

class BrokerService {
  final SupabaseClient _client = Supabase.instance.client;

  int _score(BrokerModel b) {
    int s = 0;
    if ((b.phone ?? '').trim().isNotEmpty) s += 2;
    if ((b.email ?? '').trim().isNotEmpty) s += 2;
    if ((b.website ?? '').trim().isNotEmpty) s += 2;
    if ((b.whatsapp ?? '').trim().isNotEmpty) s += 1;
    if ((b.address ?? '').trim().isNotEmpty) s += 2;
    if ((b.altPhone ?? '').trim().isNotEmpty) s += 1;
    if ((b.altEmail ?? '').trim().isNotEmpty) s += 1;
    return s;
  }

  Future<List<BrokerModel>> getActiveBrokers() async {
    final response = await _client
        .from('brokers')
        .select()
        .eq('is_active', true)
        .order('name', ascending: true);

    final list = (response as List)
        .map((e) => BrokerModel.fromMap(e as Map<String, dynamic>))
        .toList();

    // Deduplicate by name (case-insensitive), keep the most complete row
    final map = <String, BrokerModel>{};
    for (final b in list) {
      final key = b.name.trim().toLowerCase();
      final existing = map[key];
      if (existing == null || _score(b) > _score(existing)) {
        map[key] = b;
      }
    }

    final out = map.values.toList()..sort((a, b) => a.name.compareTo(b.name));
    return out;
  }
}
