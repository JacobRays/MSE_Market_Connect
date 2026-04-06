import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mse_market_connect/shared/models/profile_model.dart';

class ProfileService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> createProfile({
    required String id,
    required String email,
    String? fullName,
    String? phone,
    String role = 'investor',
    String kycStatus = 'pending',
  }) async {
    await _client.from('profiles').insert({
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'role': role,
      'kyc_status': kycStatus,
    });
  }

  Future<ProfileModel?> getCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) return null;

    return ProfileModel.fromMap(response);
  }
}
