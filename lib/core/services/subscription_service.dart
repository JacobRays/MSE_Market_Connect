import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mse_market_connect/shared/models/subscription_model.dart';

class SubscriptionService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<SubscriptionModel> getOrCreateMySubscription() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User not logged in');
    }

    final existing = await _client
        .from('subscriptions')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (existing != null) {
      return SubscriptionModel.fromMap(existing);
    }

    // Create a default free subscription row (allowed by RLS policy)
    await _client.from('subscriptions').insert({
      'user_id': user.id,
      'plan': 'free',
      'status': 'active',
    });

    final created = await _client
        .from('subscriptions')
        .select()
        .eq('user_id', user.id)
        .single();

    return SubscriptionModel.fromMap(created);
  }
}
