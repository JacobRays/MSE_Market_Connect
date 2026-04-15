import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mse_market_connect/shared/models/broker_model.dart';

class BrokerService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<BrokerModel>> getActiveBrokers() async {
    final response = await _client
        .from('brokers')
        .select()
        .eq('is_active', true)
        .order('name', ascending: true);

    return (response as List)
        .map((e) => BrokerModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
