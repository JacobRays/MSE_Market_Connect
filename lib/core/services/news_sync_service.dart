import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class NewsSyncService {
  final SupabaseClient _db = Supabase.instance.client;

  Future<int> syncBusinessNews() async {
    if (kIsWeb) {
      throw UnsupportedError('News sync is intended for mobile builds.');
    }

    final queries = ['Malawi Stock Exchange', 'MSE Malawi', 'Malawi business'];

    final now = DateTime.now().toUtc().toIso8601String();
    final rows = <Map<String, dynamic>>[];

    for (final q in queries) {
      final uri = Uri.parse('https://api.gdeltproject.org/api/v2/doc/doc')
          .replace(
            queryParameters: {
              'query': q,
              'mode': 'ArtList',
              'format': 'json',
              'maxrecords': '30',
              'sort': 'datedesc',
            },
          );

      final resp = await http.get(uri).timeout(const Duration(seconds: 25));
      if (resp.statusCode != 200) continue;

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final articles = (data['articles'] as List?) ?? const [];

      for (final a in articles) {
        final m = a as Map<String, dynamic>;
        final title = (m['title'] ?? '').toString().trim();
        final url = (m['url'] ?? '').toString().trim();
        if (title.isEmpty || url.isEmpty) continue;

        rows.add({
          'title': title,
          'excerpt': 'Business News',
          'category': 'Business',
          'published_at': now,
          'source_url': url,
          'image_url': null,
        });
      }
    }

    // de-dupe by url
    final seen = <String>{};
    final deduped = <Map<String, dynamic>>[];
    for (final r in rows) {
      final u = (r['source_url'] ?? '').toString();
      if (u.isEmpty || seen.contains(u)) continue;
      seen.add(u);
      deduped.add(r);
    }

    if (deduped.isEmpty) return 0;

    await _db.from('news').upsert(deduped, onConflict: 'source_url');
    return deduped.length;
  }
}
