import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class MsePriceSyncService {
  final SupabaseClient _db = Supabase.instance.client;

  double _d(String s) {
    final cleaned = s.replaceAll(',', '').replaceAll('%', '').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

  int _i(String s) {
    final cleaned = s.replaceAll(',', '').trim();
    return int.tryParse(cleaned) ?? 0;
  }

  Future<int> syncMainboardPrices() async {
    // Web preview will fail due to CORS/proxy/blocks. Use Android/iOS build.
    if (kIsWeb) {
      throw UnsupportedError('Price sync is only supported on the mobile build (Android/iOS).');
    }

    // Load existing symbols so we only UPDATE known rows (prevents inserts without company_name)
    final existing = await _db.from('stocks').select('symbol');
    final existingSymbols = (existing as List)
        .map((r) => (r['symbol'] ?? '').toString().toUpperCase().trim())
        .where((s) => s.isNotEmpty)
        .toSet();

    final uri = Uri.parse('https://mse.co.mw/market/mainboard');
    final resp = await http.get(uri, headers: const {
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36',
      'Accept': 'text/html',
    }).timeout(const Duration(seconds: 30));

    if (resp.statusCode != 200) {
      throw 'MSE returned HTTP ${resp.statusCode}';
    }

    final doc = html_parser.parse(resp.body);

    // Find the first table that looks like the mainboard table
    final tables = doc.querySelectorAll('table');
    if (tables.isEmpty) throw 'No table found on MSE page';

    // Choose table that contains "Symbol" header
    dynamic table;
    for (final t in tables) {
      final thText = t.querySelectorAll('th').map((e) => e.text.toLowerCase()).join(' ');
      if (thText.contains('symbol') && thText.contains('open') && thText.contains('close')) {
        table = t;
        break;
      }
    }
    table ??= tables.first;

    final rows = table.querySelectorAll('tr');
    if (rows.length < 2) throw 'No data rows found in MSE table';

    final now = DateTime.now().toUtc().toIso8601String();

    final updates = <Map<String, dynamic>>[];

    for (final tr in rows.skip(1)) {
      final cols = tr.querySelectorAll('td');
      // Expected: Symbol, Open, Close, %Change, Volume, Turnover (some tables vary)
      if (cols.length < 5) continue;

      final symbol = cols[0].text.trim().toUpperCase();
      if (symbol.isEmpty) continue;

      // Only update stocks you already have in your DB
      if (!existingSymbols.contains(symbol)) continue;

      final openPrice = _d(cols[1].text);
      final closePrice = _d(cols[2].text);
      final changePercent = _d(cols[3].text);
      final volume = _i(cols[4].text);
      final turnover = cols.length >= 6 ? _d(cols[5].text) : 0.0;

      updates.add({
        'symbol': symbol,
        'open_price': openPrice,
        'price': closePrice,
        'change_percent': changePercent,
        'volume': volume,
        'turnover_mwk': turnover,
        'updated_at': now,
      });
    }

    if (updates.isEmpty) {
      throw 'No matching symbols updated. (DB symbols may not match MSE page symbols)';
    }

    await _db.from('stocks').upsert(updates, onConflict: 'symbol');
    return updates.length;
  }
}
