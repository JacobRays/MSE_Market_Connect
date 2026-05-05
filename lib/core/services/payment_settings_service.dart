import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentSettingsService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String> getPremiumInstructions() async {
    final rows = await _client
        .from('payment_settings')
        .select('key,value');

    final list = (rows as List).cast<Map<String, dynamic>>();

    final match = list.firstWhere(
      (r) => r['key'] == 'premium_instructions',
      orElse: () => {},
    );

    final value = match['value'] as String?;
    if (value == null || value.trim().isEmpty) {
      return 'Premium is MWK 50,000/month.\n\nPayment instructions are not set yet.';
    }

    return value;
  }
}
