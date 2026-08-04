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

  // Configure targets (canonical name -> match filters and preferred domain)
  final targets = <_Target>[
    _Target(
      label: 'Stockbrokers Malawi Limited',
      namePat: '%stockbrokers malawi%',
      preferDomain: 'stockbrokersmw.com',
      preferEmailDomain: 'smlmw.com',
    ),
    _Target(
      label: 'Continental Capital Limited',
      namePat: '%continental capital%',
      preferDomain: 'continentalcapital.mw',
      preferEmailDomain: 'continental.mw',
    ),
    _Target(
      label: 'Cedar Capital Limited',
      namePat: '%cedar capital%',
      preferDomain: 'cedarcapital.mw',
      preferEmailDomain: 'cedarcapital.mw',
    ),
  ];

  for (final t in targets) {
    await _mergeGroup(client, t);
  }
  print('Done.');
}

class _Target {
  final String label;
  final String namePat;
  final String preferDomain;
  final String preferEmailDomain;
  _Target({
    required this.label,
    required this.namePat,
    required this.preferDomain,
    required this.preferEmailDomain,
  });
}

int _completeness(Map<String, dynamic> r) {
  int score = 0;
  for (final k in [
    'website',
    'email',
    'alt_email',
    'phone',
    'alt_phone',
    'address',
    'whatsapp',
  ]) {
    final v = (r[k] ?? '').toString().trim();
    if (v.isNotEmpty) score++;
  }
  return score;
}

bool _hasDomain(String? s, String domain) =>
    (s ?? '').toLowerCase().contains(domain.toLowerCase());

String _normLine(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String _digits(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');
String _last9(String s) {
  final d = _digits(s);
  return d.length >= 9 ? d.substring(d.length - 9) : d;
}

bool _phoneInAny(String candidate, List<String> fields) {
  final c9 = _last9(candidate);
  if (c9.isEmpty) return false;
  return fields.any((f) => _digits(f).contains(c9));
}

Future<void> _mergeGroup(SupabaseClient client, _Target t) async {
  final rows = await client
      .from('brokers')
      .select(
        'id,name,address,phone,alt_phone,email,alt_email,website,whatsapp,is_active,created_at',
      )
      .ilike('name', t.namePat);

  final list = (rows as List)
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
  if (list.length <= 1) {
    print('${t.label}: ${list.length} row(s) — nothing to merge.');
    return;
  }

  // Pick keeper: prefer domain in website/email, else higher completeness, else newest
  list.sort((a, b) {
    int score(Map<String, dynamic> r) {
      int s = 0;
      if (_hasDomain(r['website'] as String?, t.preferDomain)) s += 3;
      if (_hasDomain(r['email'] as String?, t.preferEmailDomain)) s += 2;
      s += _completeness(r);
      return s;
    }

    final ds = score(b) - score(a);
    if (ds != 0) return ds;
    return (b['created_at'] ?? '').toString().compareTo(
      (a['created_at'] ?? '').toString(),
    );
  });

  final keeper = list.first;
  final losers = list.skip(1).toList();

  // Merge missing fields from losers -> keeper (only fill empty; append phones/emails/address lines uniquely)
  Map<String, dynamic> patch = {};

  String pick(String key) {
    final cur = (keeper[key] ?? '').toString().trim();
    if (cur.isNotEmpty) return cur;
    for (final r in losers) {
      final v = (r[key] ?? '').toString().trim();
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  // Simple fills for website/email/whatsapp
  for (final k in ['website', 'email', 'whatsapp']) {
    final cur = (keeper[k] ?? '').toString().trim();
    if (cur.isEmpty) {
      final v = pick(k);
      if (v.isNotEmpty) patch[k] = v;
    }
  }

  // Merge alt_email uniquely
  String altEmail = (keeper['alt_email'] ?? '').toString().trim();
  for (final r in losers) {
    for (final candidate in [
      (r['alt_email'] ?? '').toString().trim(),
      (r['email'] ?? '').toString().trim(),
    ]) {
      if (candidate.isEmpty) continue;
      final has =
          altEmail.toLowerCase().contains(candidate.toLowerCase()) ||
          (keeper['email'] ?? '').toString().toLowerCase().contains(
            candidate.toLowerCase(),
          );
      if (!has) {
        altEmail = altEmail.isEmpty ? candidate : '$altEmail / $candidate';
      }
    }
  }
  if (altEmail != (keeper['alt_email'] ?? '').toString().trim()) {
    patch['alt_email'] = altEmail;
  }

  // Merge phone/alt_phone with de-dup by last 9 digits
  String phone = (keeper['phone'] ?? '').toString().trim();
  String altPhone = (keeper['alt_phone'] ?? '').toString().trim();
  final phoneFields = <String>[phone, altPhone];
  for (final r in losers) {
    for (final candidate in [
      (r['phone'] ?? '').toString().trim(),
      (r['alt_phone'] ?? '').toString().trim(),
    ]) {
      if (candidate.isEmpty) continue;
      // Split by common separators to compare each phone
      final parts = candidate
          .split(RegExp(r'[/,]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty);
      for (final p in parts) {
        if (_phoneInAny(p, phoneFields)) continue;
        if (phone.isEmpty) {
          phone = p;
          phoneFields[0] = phone;
        } else if (altPhone.isEmpty) {
          altPhone = p;
          phoneFields[1] = altPhone;
        } else {
          altPhone = '$altPhone / $p';
          phoneFields[1] = altPhone;
        }
      }
    }
  }
  if (phone != (keeper['phone'] ?? '').toString().trim())
    patch['phone'] = phone;
  if (altPhone != (keeper['alt_phone'] ?? '').toString().trim())
    patch['alt_phone'] = altPhone;

  // Merge address lines (append missing lines only)
  String address = (keeper['address'] ?? '').toString();
  for (final r in losers) {
    final other = (r['address'] ?? '').toString();
    if (other.trim().isEmpty) continue;
    final lines = other
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final norm = _normLine(address);
    for (final line in lines) {
      if (!norm.contains(_normLine(line))) {
        address = address.trim().isEmpty ? line : '${address.trim()}\n$line';
      }
    }
  }
  if (address != (keeper['address'] ?? '').toString())
    patch['address'] = address;

  // Apply patch to keeper if anything changed
  if (patch.isNotEmpty) {
    await client.from('brokers').update(patch).eq('id', keeper['id']);
    print('${t.label}: merged into keeper id=${keeper['id']} -> $patch');
  } else {
    print('${t.label}: keeper id=${keeper['id']} already complete.');
  }

  // Deactivate losers so they disappear from the app immediately
  for (final r in losers) {
    await client.from('brokers').update({'is_active': false}).eq('id', r['id']);
    print('${t.label}: deactivated duplicate id=${r['id']}');
  }
}
