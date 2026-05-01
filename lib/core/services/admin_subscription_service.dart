import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mse_market_connect/shared/models/profile_model.dart';
import 'package:mse_market_connect/shared/models/subscription_model.dart';

class AdminUserSubscription {
  final ProfileModel profile;
  final SubscriptionModel? subscription;

  const AdminUserSubscription({
    required this.profile,
    required this.subscription,
  });

  String get plan => subscription?.plan ?? 'free';
  bool get isPremium => subscription?.isPremium ?? false;
}

class AdminSubscriptionService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<ProfileModel>> getAllProfiles() async {
    final response = await _client
        .from('profiles')
        .select('id,email,full_name,phone,role,kyc_status,created_at')
        .order('email', ascending: true);

    return (response as List)
        .map((e) => ProfileModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, SubscriptionModel>> getSubscriptionsByUserIds(
      List<String> userIds) async {
    if (userIds.isEmpty) return {};

    final response = await _client
        .from('subscriptions')
        .select()
        .inFilter('user_id', userIds);

    final list = (response as List).cast<Map<String, dynamic>>();

    return {
      for (final row in list)
        row['user_id'] as String: SubscriptionModel.fromMap(row),
    };
  }

  Future<void> setPremium({
    required String userId,
    int days = 30,
  }) async {
    final expires = DateTime.now().add(Duration(days: days)).toIso8601String();

    await _client.from('subscriptions').upsert(
      {
        'user_id': userId,
        'plan': 'premium',
        'status': 'active',
        'current_period_end': expires,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id',
    );
  }

  Future<void> setFree({required String userId}) async {
    await _client.from('subscriptions').upsert(
      {
        'user_id': userId,
        'plan': 'free',
        'status': 'active',
        'current_period_end': null,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id',
    );
  }
}
