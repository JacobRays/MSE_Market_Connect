import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mse_market_connect/shared/models/premium_request_model.dart';

class PremiumUpgradeService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String> uploadReceipt({
    required Uint8List bytes,
    required String fileName,
    String? contentType,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('User not logged in');

    final safeName = fileName.replaceAll(' ', '_');
    final path =
        '${user.id}/premium/${DateTime.now().millisecondsSinceEpoch}_$safeName';

    await _client.storage
        .from('premium-receipts')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: false,
            contentType: contentType ?? 'application/octet-stream',
          ),
        );

    return path;
  }

  Future<void> createRequest({
    required double amount,
    required String receiptPath,
    String currency = 'MWK',
    String? paymentMethod,
    String? payerReference,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('User not logged in');

    await _client.from('premium_upgrade_requests').insert({
      'user_id': user.id,
      'amount': amount,
      'currency': currency,
      'payment_method': paymentMethod,
      'payer_reference': payerReference,
      'receipt_path': receiptPath,
      'status': 'pending',
    });
  }

  Future<List<PremiumRequestModel>> getMyRequests() async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('User not logged in');

    final response = await _client
        .from('premium_upgrade_requests')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(20);

    return (response as List)
        .map((e) => PremiumRequestModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
