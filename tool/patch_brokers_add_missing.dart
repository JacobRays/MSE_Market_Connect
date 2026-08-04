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

  await _patchContinental(client);
  await _patchStockbrokersMw(client);

  print('Done. Added only missing info; nothing existing was removed.');
}

/* ========== Helpers ========== */

String _digitsOnly(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');
String _last9(String s) {
  final d = _digitsOnly(s);
  return d.length >= 9 ? d.substring(d.length - 9) : d;
}

bool _hasNumberInFields(String candidate, List<String> fields) {
  final cand9 = _last9(candidate);
  if (cand9.isEmpty) return false;
  for (final f in fields) {
    if (_digitsOnly(f).contains(cand9)) return true;
  }
  return false;
}

String _normLine(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

bool _addrContainsLine(String addr, String line) {
  if (addr.trim().isEmpty) return false;
  final a = _normLine(addr);
  final l = _normLine(line);
  return a.contains(l);
}

String? _appendAddressLinesIfMissing(String current, List<String> lines) {
  final toAdd = <String>[];
  for (final line in lines) {
    if (line.trim().isEmpty) continue;
    if (!_addrContainsLine(current, line)) toAdd.add(line);
  }
  if (current.trim().isEmpty) {
    if (toAdd.isEmpty) return null;
    return toAdd.join('\n');
  }
  if (toAdd.isEmpty) return null;
  return '${current.trim()}\n${toAdd.join('\n')}';
}

String? _appendDelimitedIfMissing({
  required String current,
  required String candidate,
  required bool Function(String current, String candidate) alreadyHas,
  String delimiter = ' / ',
}) {
  if (candidate.trim().isEmpty) return null;
  if (current.trim().isEmpty) return candidate.trim();
  if (alreadyHas(current, candidate)) return null;
  return '${current.trim()}$delimiter${candidate.trim()}';
}

/* ========== Continental Capital Limited ========== */

Future<void> _patchContinental(SupabaseClient client) async {
  const namePat = '%continental capital%';
  const domain = 'continentalcapital.mw';
  const primaryPhone = '+265 111 828 363';
  const extraPhone1 = '887 376 469';
  const extraPhone2 = '999 971 579';
  const website = 'http://www.continentalcapital.mw';
  const email = 'capital@continental.mw';
  const addrLines = <String>[
    'Ground Floor, Ulimi House',
    'P.O. Box 1444',
    'Glyn Jones Road',
    'Blantyre',
    'Malawi',
  ];

  final data = await client
      .from('brokers')
      .select('id,name,address,phone,alt_phone,email,alt_email,website')
      .or(
        'name.ilike.$namePat,website.ilike.%$domain%,email.ilike.%@continental.mw%',
      )
      .order('name')
      .limit(50);

  final rows = (data as List)
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
  if (rows.isEmpty) {
    print('Continental: no matching rows (name/domain).');
    return;
  }

  for (final r in rows) {
    final id = r['id'];
    if (id == null) continue;

    final currentAddr = (r['address'] ?? '').toString();
    final currentPhone = (r['phone'] ?? '').toString();
    final currentAltPhone = (r['alt_phone'] ?? '').toString();
    final currentEmail = (r['email'] ?? '').toString();
    final currentAltEmail = (r['alt_email'] ?? '').toString();
    final currentSite = (r['website'] ?? '').toString();

    final patch = <String, dynamic>{};

    // website (fill only if empty)
    if (currentSite.trim().isEmpty) patch['website'] = website;

    // primary email (fill only if empty)
    if (currentEmail.trim().isEmpty) patch['email'] = email;

    // no special alt_email to add for Continental (keep existing)

    // primary phone (fill only if empty)
    if (currentPhone.trim().isEmpty) patch['phone'] = primaryPhone;

    // alt_phone: add extra phones if their last-9 digits aren’t present in phone or alt_phone
    final phoneFields = [
      currentPhone,
      currentAltPhone,
      patch['phone']?.toString() ?? '',
    ];

    final newAlt1 = _appendDelimitedIfMissing(
      current: currentAltPhone,
      candidate: extraPhone1,
      alreadyHas: (cur, cand) =>
          _hasNumberInFields(cand, [cur, ...phoneFields]),
    );
    var newAltCombined = newAlt1 ?? currentAltPhone;

    final newAlt2 = _appendDelimitedIfMissing(
      current: newAltCombined,
      candidate: extraPhone2,
      alreadyHas: (cur, cand) =>
          _hasNumberInFields(cand, [cur, ...phoneFields]),
    );
    if (newAlt2 != null && newAlt2 != currentAltPhone) {
      patch['alt_phone'] = newAlt2;
    } else if (newAlt1 != null && newAlt1 != currentAltPhone) {
      patch['alt_phone'] = newAlt1;
    }

    // address: append any missing lines (or set all if empty)
    final addrPatched = _appendAddressLinesIfMissing(currentAddr, addrLines);
    if (addrPatched != null && addrPatched != currentAddr) {
      patch['address'] = addrPatched;
    }

    if (patch.isEmpty) {
      print(
        'Continental: ${r['name']} (id=$id) already has details; no changes.',
      );
      continue;
    }
    await client.from('brokers').update(patch).eq('id', id);
    print('Continental: UPDATED id=$id -> $patch');
  }
}

/* ========== Stockbrokers Malawi Limited ========== */

Future<void> _patchStockbrokersMw(SupabaseClient client) async {
  const namePat = '%stockbrokers malawi%';
  const domain = 'stockbrokersmw.com';
  const primaryPhone = '+265(0)111 836 213';
  const altPhone = '+265 (0) 111 822 803';
  const website = 'https://www.stockbrokersmw.com/';
  const primaryEmail = 'sml@smlmw.com';
  const altEmail = 'info@smlmw.com';
  const addrLinesPrimary = <String>['P.O Box 31180', 'Blantyre 3', 'Malawi'];
  const addrNBMLine = 'NBM Towers 7 Henderson Street, Blantyre, Malawi';

  final data = await client
      .from('brokers')
      .select('id,name,address,phone,alt_phone,email,alt_email,website')
      .or(
        'name.ilike.$namePat,website.ilike.%$domain%,email.ilike.%@smlmw.com%',
      )
      .order('name')
      .limit(50);

  final rows = (data as List)
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
  if (rows.isEmpty) {
    print('StockbrokersMW: no matching rows (name/domain).');
    return;
  }

  for (final r in rows) {
    final id = r['id'];
    if (id == null) continue;

    final currentAddr = (r['address'] ?? '').toString();
    final currentPhone = (r['phone'] ?? '').toString();
    final currentAltPhone = (r['alt_phone'] ?? '').toString();
    final currentEmail = (r['email'] ?? '').toString();
    final currentAltEmail = (r['alt_email'] ?? '').toString();
    final currentSite = (r['website'] ?? '').toString();

    final patch = <String, dynamic>{};

    // website (fill only if empty)
    if (currentSite.trim().isEmpty) patch['website'] = website;

    // primary email (fill only if empty)
    if (currentEmail.trim().isEmpty) patch['email'] = primaryEmail;

    // alt email (append if not present)
    final altEmailLower = currentAltEmail.toLowerCase();
    if (currentAltEmail.trim().isEmpty) {
      patch['alt_email'] = altEmail;
    } else if (!altEmailLower.contains(altEmail.toLowerCase())) {
      patch['alt_email'] = '${currentAltEmail.trim()} / $altEmail';
    }

    // primary phone (fill only if empty)
    if (currentPhone.trim().isEmpty) patch['phone'] = primaryPhone;

    // alt phone (append if not present by last-9 digits across phone+alt_phone)
    final phoneFields = [
      currentPhone,
      currentAltPhone,
      patch['phone']?.toString() ?? '',
    ];
    final newAlt = _appendDelimitedIfMissing(
      current: currentAltPhone,
      candidate: altPhone,
      alreadyHas: (cur, cand) =>
          _hasNumberInFields(cand, [cur, ...phoneFields]),
    );
    if (newAlt != null && newAlt != currentAltPhone) {
      patch['alt_phone'] = newAlt;
    }

    // address: ensure primary lines exist, then ensure NBM line exists (append as extra paragraph)
    var afterPrimary =
        _appendAddressLinesIfMissing(currentAddr, addrLinesPrimary) ??
        currentAddr;
    if (!_addrContainsLine(afterPrimary, addrNBMLine)) {
      afterPrimary = afterPrimary.trim().isEmpty
          ? addrNBMLine
          : '$afterPrimary\n\n$addrNBMLine';
    }
    if (afterPrimary != currentAddr) {
      patch['address'] = afterPrimary;
    }

    if (patch.isEmpty) {
      print(
        'StockbrokersMW: ${r['name']} (id=$id) already has details; no changes.',
      );
      continue;
    }
    await client.from('brokers').update(patch).eq('id', id);
    print('StockbrokersMW: UPDATED id=$id -> $patch');
  }
}
