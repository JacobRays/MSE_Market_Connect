#!/usr/bin/env bash
set -Eeuo pipefail

# 1) Write the Dart tool (clean, idempotent)
cat > tool/fill_brokers_missing.dart << 'DART'
import 'dart:io';
import 'package:supabase/supabase.dart';

Future<void> main() async {
  final url = Platform.environment['SUPABASE_URL'] ?? '';
  final key = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'] ?? '';
  if (url.isEmpty || key.isEmpty) {
    stderr.writeln('ERROR: Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY env vars before running.');
    exit(1);
  }

  final client = SupabaseClient(url, key);

  final targets = <_BrokerInfo>[
    _BrokerInfo(
      name: 'Cedar Capital Limited',
      nameLike: 'cedar capital',
      domain: 'cedarcapital.mw',
      website: 'https://cedarcapital.mw/',
      email: 'info@cedarcapital.mw',
      phone: '+265(0)111 831 395',
      address: '4th Floor, Livingstone Towers\nP.O Box 3340, Blantyre\nMalawi',
    ),
    _BrokerInfo(
      name: 'Continental Capital Limited',
      nameLike: 'continental capital',
      domain: 'continentalcapital.mw',
      website: 'http://www.continentalcapital.mw',
      email: 'capital@continental.mw',
      phone: '+265 111 828 363',
      address: 'P.O Box 1444\nBlantyre\nMalawi',
    ),
    _BrokerInfo(
      name: 'Stockbrokers Malawi Limited',
      nameLike: 'stockbrokers malawi',
      domain: 'stockbrokersmw.com',
      website: 'https://www.stockbrokersmw.com/',
      email: 'sml@smlmw.com',
      phone: '+265(0)111 836 213',
      address: 'P.O Box 31180\nBlantyre 3\nMalawi',
    ),
  ];

  for (final b in targets) {
    await _patchOne(client, b);
  }

  print('Done. Only empty fields were filled; nothing existing was overwritten.');
}

Future<void> _patchOne(SupabaseClient client, _BrokerInfo info) async {
  final namePat = '%${info.nameLike.toLowerCase()}%';
  final domPat = '%${info.domain.toLowerCase()}%';
  final emailDomPat = '%@${info.domain.toLowerCase()}%';

  final data = await client
      .from('brokers')
      .select('id,name,email,website,phone,address')
      .or('name.ilike.$namePat,website.ilike.$domPat,email.ilike.$emailDomPat')
      .order('name')
      .limit(20);

  final list = (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  if (list.isEmpty) {
    final data2 = await client
        .from('brokers')
        .select('id,name,email,website,phone,address')
        .ilike('name', namePat)
        .order('name')
        .limit(20);
    final list2 = (data2 as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    if (list2.isEmpty) {
      print('SKIP: No broker matched for "${info.name}"');
      return;
    }
    await _applyPatch(client, list2, info);
  } else {
    await _applyPatch(client, list, info);
  }
}

Future<void> _applyPatch(
  SupabaseClient client,
  List<Map<String, dynamic>> candidates,
  _BrokerInfo info,
) async {
  Map<String, dynamic> best = candidates.first;

  // Prefer row with matching website domain
  for (final r in candidates) {
    final w = (r['website'] ?? '').toString().toLowerCase();
    if (w.contains(info.domain.toLowerCase())) {
      best = r;
      break;
    }
  }

  // If normalized name matches better, pick that
  final currentNorm = _normName(best['name']?.toString() ?? '');
  final want = info.nameLike.toLowerCase().trim();
  if (currentNorm != want) {
    for (final r in candidates) {
      final n = _normName(r['name']?.toString() ?? '');
      if (n == want) {
        best = r;
        break;
      }
    }
  }

  final id = best['id'];
  if (id == null) {
    print('SKIP: matched row missing id for "${info.name}"');
    return;
  }

  final current = {
    'address': (best['address'] ?? '').toString().trim(),
    'phone': (best['phone'] ?? '').toString().trim(),
    'website': (best['website'] ?? '').toString().trim(),
    'email': (best['email'] ?? '').toString().trim(),
  };

  final patch = <String, dynamic>{};
  void setIfMissing(String col, String newVal) {
    final cur = (current[col] ?? '').toString().trim();
    if (cur.isEmpty && newVal.trim().isNotEmpty) {
      patch[col] = newVal.trim();
    }
  }

  setIfMissing('address', info.address);
  setIfMissing('phone', info.phone);
  setIfMissing('website', info.website);
  setIfMissing('email', info.email);

  if (patch.isEmpty) {
    print('OK: "${info.name}" already filled (no changes).');
    return;
  }

  await client.from('brokers').update(patch).eq('id', id);
  print('UPDATED: "${info.name}" (id=$id) -> $patch');
}

String _normName(String s) {
  var n = s.trim().toLowerCase();
  n = n.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
  n = n.replaceAll(RegExp(r'\bltd\b'), 'limited');
  n = n.replaceAll(RegExp(r'\b(limited|plc|inc|corp|corporation|company|holdings?|group)\b'), '');
  n = n.replaceAll(RegExp(r'\s+'), ' ').trim();
  return n;
}

class _BrokerInfo {
  final String name;
  final String nameLike;
  final String domain;
  final String website;
  final String email;
  final String phone;
  final String address;
  const _BrokerInfo({
    required this.name,
    required this.nameLike,
    required this.domain,
    required this.website,
    required this.email,
    required this.phone,
    required this.address,
  });
}
DART

# 2) Prompt for secrets without echoing the key
read -rp "SUPABASE_URL: " SUPABASE_URL
read -rsp "SUPABASE_SERVICE_ROLE_KEY (hidden): " SUPABASE_SERVICE_ROLE_KEY
echo

# 3) Run the tool with these env vars only for this process
SUPABASE_URL="$SUPABASE_URL" SUPABASE_SERVICE_ROLE_KEY="$SUPABASE_SERVICE_ROLE_KEY" dart run tool/fill_brokers_missing.dart
unset SUPABASE_URL SUPABASE_SERVICE_ROLE_KEY
