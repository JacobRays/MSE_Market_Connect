import 'package:supabase_flutter/supabase_flutter.dart';

class BrokerUserService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Map<String, dynamic>?> getMyBrokerUserRow() async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('User not logged in');

    return await _client
        .from('broker_users')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();
  }
}
