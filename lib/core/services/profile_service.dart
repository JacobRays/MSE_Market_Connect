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
  Future<void> updateProfile({String? fullName, String? phone}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception("Not logged in");
    final updates = <String, dynamic>{};
    if (fullName != null) updates["full_name"] = fullName;
    if (phone != null) updates["phone"] = phone;
    if (updates.isEmpty) return;
    await _client.from("profiles").update(updates).eq("id", user.id);
  }
}
