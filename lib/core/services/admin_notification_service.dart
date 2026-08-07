import 'package:supabase_flutter/supabase_flutter.dart';

class AdminNotificationService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Send a notification to all users
  Future<void> sendToAll(String title, String body) async {
    await _client.from('notifications').insert({
      'title': title,
      'body': body,
      'sent_to': 'all',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Fetch KYC submissions (profiles with a submitted kyc_status = 'pending')
  Future<List<Map<String, dynamic>>> getPendingKyc() async {
    final res = await _client
        .from('profiles')
        .select('id, full_name, email, kyc_status, kyc_details')
        .eq('kyc_status', 'pending')
        .order('created_at', ascending: false);

    return (res as List<dynamic>).cast<Map<String, dynamic>>();
  }

  /// Approve KYC
  Future<void> approveKyc(String userId) async {
    await _client.from('profiles').update({'kyc_status': 'approved'}).eq('id', userId);
  }

  /// Reject KYC
  Future<void> rejectKyc(String userId) async {
    await _client.from('profiles').update({'kyc_status': 'rejected'}).eq('id', userId);
  }
}
