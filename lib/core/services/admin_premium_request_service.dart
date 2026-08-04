import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mse_market_connect/core/services/admin_subscription_service.dart';
import 'package:mse_market_connect/shared/models/premium_request_model.dart';
import 'package:mse_market_connect/shared/models/profile_model.dart';

class AdminPremiumRequestView {
  final PremiumRequestModel request;
  final ProfileModel? profile;

  const AdminPremiumRequestView({required this.request, required this.profile});
}

class AdminPremiumRequestService {
  final SupabaseClient _client = Supabase.instance.client;
  final AdminSubscriptionService _subs = AdminSubscriptionService();

  Future<List<AdminPremiumRequestView>> getRequestsByStatus(
    String status,
  ) async {
    final resp = await _client
        .from('premium_upgrade_requests')
        .select()
        .eq('status', status)
        .order('created_at', ascending: false);

    final requests = (resp as List)
        .map((e) => PremiumRequestModel.fromMap(e as Map<String, dynamic>))
        .toList();

    if (requests.isEmpty) return [];

    final userIds = requests.map((r) => r.userId).toSet().toList();

    final profResp = await _client
        .from('profiles')
        .select('id,email,full_name,phone,role,kyc_status,created_at')
        .inFilter('id', userIds);

    final profiles = (profResp as List)
        .map((e) => ProfileModel.fromMap(e as Map<String, dynamic>))
        .toList();

    final byId = {for (final p in profiles) p.id: p};

    return requests
        .map(
          (r) => AdminPremiumRequestView(request: r, profile: byId[r.userId]),
        )
        .toList();
  }

  Future<String> getSignedReceiptUrl(String receiptPath) async {
    return await _client.storage
        .from('premium-receipts')
        .createSignedUrl(receiptPath, 60 * 10);
  }

  Future<void> approveRequest({
    required String requestId,
    required String userId,
    String? adminNote,
    int premiumDays = 30,
  }) async {
    await _client
        .from('premium_upgrade_requests')
        .update({'status': 'approved', 'admin_note': adminNote})
        .eq('id', requestId);

    await _subs.setPremium(userId: userId, days: premiumDays);
  }

  Future<void> rejectRequest({
    required String requestId,
    String? adminNote,
  }) async {
    await _client
        .from('premium_upgrade_requests')
        .update({'status': 'rejected', 'admin_note': adminNote})
        .eq('id', requestId);
  }
}
