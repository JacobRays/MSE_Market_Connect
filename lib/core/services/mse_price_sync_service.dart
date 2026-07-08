import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class MsePriceSyncService {
  final SupabaseClient _db = Supabase.instance.client;

  double _num(String s) {
    final m = RegExp(r'-?\d+(\.\d+)?').firstMatch(s.replaceAll(',', ''));
    if (m == null) return 0.0;
    return double.tryParse(m.group(0)!) ?? 0.0;
  }

  int _int(String s) {
    final m = RegExp(r'\d+').firstMatch(s.replaceAll(',', ''));
    if (m == null) return 0;
    return int.tryParse(m.group(0)!) ?? 0;
  }

  Future<void> _insertHistory(
    List<Map<String, dynamic>> updates,
    String recordedAt,
  ) async {
    // Write one history point per symbol per sync.
    // Best-effort: if history table/policy is missing, do not fail the whole sync.
    try {
      final historyRows = updates.map((u) {
        return <String, dynamic>{
          'symbol': u['symbol'],
          'price': u['price'],
          'change_percent': u['change_percent'],
          'volume': u['volume'],
          'recorded_at': recordedAt,
        };
      }).toList();

      await _db.from('stock_price_history').insert(historyRows);
      debugPrint('Inserted ${historyRows.length} price history rows');
    } catch (e, st) {
      debugPrint('History insert skipped/failed: $e');
      debugPrint('$st');
    }
  }

  Future<int> syncMainboardPrices() async {
    if (kIsWeb) {
      throw UnsupportedError(
        'Price sync is only supported on the mobile build (Android/iOS).',
      );
    }

    // Update only symbols that exist (prevents missing required cols like company_name)
    final existing = await _db.from('stocks').select('symbol');
    final existingSymbols = (existing as List)
        .map((r) => (r['symbol'] ?? '').toString().toUpperCase().trim())
        .where((s) => s.isNotEmpty)
        .toSet();

    final uri = Uri.parse('https://mse.co.mw/market/mainboard');
    final resp = await http
        .get(
          uri,
          headers: const {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36',
            'Accept': 'text/html',
          },
        )
        .timeout(const Duration(seconds: 30));

    if (resp.statusCode != 200) {
      throw 'MSE returned HTTP ${resp.statusCode}';
    }

    final doc = html_parser.parse(resp.body);
    final tables = doc.querySelectorAll('table');
    if (tables.isEmpty) throw 'No table found on MSE page';

    dynamic table;
    for (final t in tables) {
      final thText = t
          .querySelectorAll('th')
          .map((e) => e.text.toLowerCase())
          .join(' ');
      if (thText.contains('symbol') &&
          thText.contains('open') &&
          thText.contains('close')) {
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
      if (cols.length < 5) continue;

      final symbol = cols[0].text.trim().toUpperCase();
      if (symbol.isEmpty) continue;
      if (!existingSymbols.contains(symbol)) continue;

      final openPrice = _num(cols[1].text);
      final closePrice = _num(cols[2].text);
      final changePercent = _num(cols[3].text);
      final volume = _int(cols[4].text);
      final turnover = cols.length >= 6 ? _num(cols[5].text) : 0.0;

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

    // Write history points (best-effort)
    await _insertHistory(updates, now);

    return updates.length;
  }
}
