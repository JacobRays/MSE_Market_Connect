import 'dart:convert';
import 'dart:io';
import 'package:supabase/supabase.dart';

// Prints rows for both brokers with key columns so we can compare.

Future<void> main() async {
  final url = Platform.environment['SUPABASE_URL'] ?? '';
  final key = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'] ?? '';
  if (url.isEmpty || key.isEmpty) {
    stderr.writeln('ERROR: set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY');
    exit(1);
  }
  final c = SupabaseClient(url, key);

  Future<void> show(String label, String like) async {
    final rows = await c
        .from('brokers')
        .select(
          'id,name,is_active,website,email,alt_email,phone,alt_phone,address,created_at',
        )
        .ilike('name', like)
        .order('is_active', ascending: false)
        .order('created_at', ascending: false);
    print('=== $label ===');
    print(const JsonEncoder.withIndent('  ').convert(rows));
    print('');
  }

  await show('Continental Capital', '%continental capital%');
  await show('Stockbrokers Malawi', '%stockbrokers malawi%');
}
