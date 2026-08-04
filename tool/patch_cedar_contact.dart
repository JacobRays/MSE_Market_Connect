import 'dart:io';
import 'package:supabase/supabase.dart';

Future<void> main() async {
  final url = Platform.environment['SUPABASE_URL'] ?? '';
  final key = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'] ?? '';
  if (url.isEmpty || key.isEmpty) {
    stderr.writeln(
      'ERROR: Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY before running.',
    );
    exit(1);
  }

  final client = SupabaseClient(url, key);

  // Target broker: Cedar Capital Limited
  final namePat = '%cedar capital%';
  final rows = await client
      .from('brokers')
      .select('id,name,address,phone,alt_phone,email,alt_email,website')
      .ilike('name', namePat);

  final list = (rows as List)
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
  if (list.isEmpty) {
    print('SKIP: No broker matched name like "$namePat"');
    return;
  }

  // New contact info to add if missing
  const line1 = '4th Floor';
  const line2 = 'Livingstone Towers';
  const line3 = 'Glyn Jones Road Blantyre 3 Malawi';
  const altEmail = 'kamphonia@cedarcapital.mw';
  const altPhone = '+265 1 832 307';

  bool containsIgnoreCase(String hay, String needle) =>
      hay.toLowerCase().contains(needle.toLowerCase());

  // Helper to detect if a phone number (by digits or last 9) already exists in a field
  bool hasNumber(String field, String candidate) {
    String d(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');
    String last9(String s) {
      final ds = d(s);
      return ds.length >= 9 ? ds.substring(ds.length - 9) : ds;
    }

    final fieldDigits = d(field);
    final cand9 = last9(candidate);
    if (cand9.isEmpty) return false;
    return fieldDigits.contains(cand9);
  }

  for (final r in list) {
    final id = r['id'];
    if (id == null) continue;

    final curAddr = (r['address'] ?? '').toString();
    final curAltEmail = (r['alt_email'] ?? '').toString();
    final curAltPhone = (r['alt_phone'] ?? '').toString();

    final patch = <String, dynamic>{};

    // Address rules:
    // - If empty: set to all three lines.
    // - Else: append any missing lines (don’t duplicate).
    if (curAddr.trim().isEmpty) {
      patch['address'] = '$line1\n$line2\n$line3';
    } else {
      final lower = curAddr.toLowerCase();
      final pieces = <String>[];
      if (!containsIgnoreCase(lower, line1)) pieces.add(line1);
      if (!containsIgnoreCase(lower, line2)) pieces.add(line2);
      if (!containsIgnoreCase(lower, 'glyn jones road')) pieces.add(line3);
      if (pieces.isNotEmpty) {
        patch['address'] = '${curAddr.trim()}\n${pieces.join('\n')}';
      }
    }

    // alt_email: append if not already present (case-insensitive)
    if (curAltEmail.trim().isEmpty) {
      patch['alt_email'] = altEmail;
    } else if (!containsIgnoreCase(curAltEmail, altEmail)) {
      patch['alt_email'] = '${curAltEmail.trim()} / $altEmail';
    }

    // alt_phone: append if digits not already present
    if (curAltPhone.trim().isEmpty) {
      patch['alt_phone'] = altPhone;
    } else if (!hasNumber(curAltPhone, altPhone)) {
      patch['alt_phone'] = '${curAltPhone.trim()} / $altPhone';
    }

    if (patch.isEmpty) {
      print(
        'OK: ${r['name']} (id=$id) already has these Cedar contact details.',
      );
      continue;
    }

    await client.from('brokers').update(patch).eq('id', id);
    print('UPDATED: ${r['name']} (id=$id) -> $patch');
  }

  print(
    'Done. Added only missing Cedar Capital contact info; nothing existing was removed.',
  );
}
