import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class MseSyncService {
  final _db = Supabase.instance.client;

  // Helper for fetching HTML (Direct on Mobile, Proxy on Web)
  Future<String> _fetchHtml(String rawUrl) async {
    final url = kIsWeb 
      ? Uri.parse('https://corsproxy.io/?${Uri.encodeComponent(rawUrl)}')
      : Uri.parse(rawUrl);
    
    final response = await http.get(url).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) throw 'Error ${response.statusCode}';
    return response.body;
  }

  // 1. SYNC PRICES (From MSE - Best triggered manually by Admin)
  Future<int> syncPrices() async {
    final htmlBody = await _fetchHtml('https://mse.co.mw/market/mainboard');
    final document = parser.parse(htmlBody);
    final table = document.querySelector('table');
    if (table == null) throw 'MSE Stock table not found';

    List<Map<String, dynamic>> stocks = [];
    final rows = table.querySelectorAll('tr');

    for (var i = 1; i < rows.length; i++) {
      final cols = rows[i].querySelectorAll('td');
      if (cols.length < 5) continue;

      stocks.add({
        'symbol': cols[0].text.trim().toUpperCase(),
        'price': double.tryParse(cols[2].text.replaceAll(',', '').trim()) ?? 0.0,
        'change_percent': double.tryParse(cols[3].text.replaceAll('%', '').trim()) ?? 0.0,
        'volume': int.tryParse(cols[4].text.replaceAll(',', '').trim()) ?? 0,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    }

    if (stocks.isNotEmpty) {
      await _db.from('stocks').upsert(stocks, onConflict: 'symbol');
    }
    return stocks.length;
  }

  // 2. SYNC NEWS (From Nyasa Times Business - High Success Rate)
  Future<int> syncNews() async {
    final htmlBody = await _fetchHtml('https://www.nyasatimes.com/category/business/');
    final document = parser.parse(htmlBody);
    
    List<Map<String, dynamic>> newsItems = [];
    // Nyasa Times uses 'card-title' or 'h3' for news headers
    final articles = document.querySelectorAll('h3.entry-title a');

    for (var a in articles) {
      final title = a.text.trim();
      final link = a.attributes['href'] ?? '';
      
      if (title.length > 10 && link.isNotEmpty) {
        newsItems.add({
          'title': title,
          'excerpt': 'Malawi Business News Update',
          'category': 'Business',
          'published_at': DateTime.now().toUtc().toIso8601String(),
          'source_url': link,
        });
      }
    }

    if (newsItems.isNotEmpty) {
      await _db.from('news').upsert(newsItems, onConflict: 'source_url');
    }
    return newsItems.length;
  }
}
