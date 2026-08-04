import 'dart:convert';
import 'dart:io';
import 'package:supabase/supabase.dart';

Future<void> main() async {
  final url = Platform.environment['SUPABASE_URL'] ?? '';
  final key = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'] ?? '';
  if (url.isEmpty || key.isEmpty) {
    stderr.writeln('ERROR: set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY');
    exit(1);
  }
  final client = SupabaseClient(url, key);

  final rows = await client
      .from('brokers')
      .select(
        'id,name,address,phone,alt_phone,email,alt_email,website,whatsapp,is_active,created_at',
      )
      .ilike('name', '%stockbrokers malawi%');

  print(const JsonEncoder.withIndent('  ').convert(rows));
}
