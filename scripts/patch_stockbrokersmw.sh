#!/usr/bin/env bash
set -Eeuo pipefail

cat > tool/patch_stockbrokersmw.dart << 'DART'
import 'dart:io';
import 'package:supabase/supabase.dart';

Future<void> main() async {
  final url = Platform.environment['SUPABASE_URL'] ?? '';
  final key = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'] ?? '';
  if (url.isEmpty || key.isEmpty) {
    stderr.writeln('ERROR: Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY before running.');
    exit(1);
  }

  final client = SupabaseClient(url, key);

  final namePat = '%stockbrokers malawi%';
  final rows = await client
      .from('brokers')
      .select('id,name,website,email,alt_email,phone,alt_phone,address')
      .ilike('name', namePat);

  final list = (rows as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  if (list.isEmpty) {
    print('SKIP: No broker matched name like "$namePat"');
    return;
  }

  final site = 'https://www.stockbrokersmw.com/';
  final primaryEmail = 'sml@smlmw.com';
  final altEmail = 'info@smlmw.com';
  final primaryPhone = '+265(0)111 836 213';
  final altPhone = '+265 (0) 111 822 803';
  final poBox = 'P.O Box 31180\nBlantyre 3\nMalawi';
  final street = 'NBM Towers 7 Henderson Street, Blantyre, Malawi';

  for (final r in list) {
    final id = r['id'];
    if (id == null) continue;

    final curAddr = (r['address'] ?? '').toString();
    final curPhone = (r['phone'] ?? '').toString();
    final curAltPhone = (r['alt_phone'] ?? '').toString();
    final curSite = (r['website'] ?? '').toString();
    final curEmail = (r['email'] ?? '').toString();
    final curAltEmail = (r['alt_email'] ?? '').toString();

    final patch = <String, dynamic>{};

    // website (fill only if empty)
    if (curSite.trim().isEmpty) {
      patch['website'] = site;
    }

    // primary email (fill only if empty)
    if (curEmail.trim().isEmpty) {
      patch['email'] = primaryEmail;
    }

    // alt email (append if not present)
    final altEmailLower = curAltEmail.toLowerCase();
    if (curAltEmail.trim().isEmpty) {
      patch['alt_email'] = altEmail;
    } else if (!altEmailLower.contains(altEmail.toLowerCase())) {
      patch['alt_email'] = '${curAltEmail.trim()} / $altEmail';
    }

    // primary phone (fill only if empty)
    if (curPhone.trim().isEmpty) {
      patch['phone'] = primaryPhone;
    }

    // alt phone (append if last-9 digits not already present)
    bool hasNumber(String field, String candidate) {
      String d(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');
      String last9(String s) {
        final ds = d(s);
        return ds.length >= 9 ? ds.substring(ds.length - 9) : ds;
      }
      final fieldDigits = d(field);
      final cand9 = last9(candidate);
      return cand9.isNotEmpty && fieldDigits.contains(cand9);
    }

    if (curAltPhone.trim().isEmpty) {
      patch['alt_phone'] = altPhone;
    } else if (!hasNumber(curAltPhone, altPhone)) {
      patch['alt_phone'] = '${curAltPhone.trim()} / $altPhone';
    }

    // address:
    // - if empty -> P.O Box + street
    // - else append street if not already present (case-insensitive)
    final addrLower = curAddr.toLowerCase();
    if (curAddr.trim().isEmpty) {
      patch['address'] = '$poBox\n\n$street';
    } else if (!addrLower.contains(street.toLowerCase())) {
      patch['address'] = '${curAddr.trim()}\n\n$street';
    }

    if (patch.isEmpty) {
      print('OK: ${r['name']} (id=$id) already has all fields; no changes.');
      continue;
    }

    await client.from('brokers').update(patch).eq('id', id);
    print('UPDATED: ${r['name']} (id=$id) -> $patch');
  }

  print('Done. Only missing/extra fields were added; nothing existing was removed.');
}
DART

# prompt for secrets safely
read -rp "SUPABASE_URL: " SUPABASE_URL
read -rsp "SUPABASE_SERVICE_ROLE_KEY (hidden): " SUPABASE_SERVICE_ROLE_KEY
echo

SUPABASE_URL="$SUPABASE_URL" SUPABASE_SERVICE_ROLE_KEY="$SUPABASE_SERVICE_ROLE_KEY" dart run tool/patch_stockbrokersmw.dart
unset SUPABASE_URL SUPABASE_SERVICE_ROLE_KEY
