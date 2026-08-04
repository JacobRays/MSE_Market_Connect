import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

class PriceSyncEdgeService {
  final _functions = Supabase.instance.client.functions;

  Future<int> syncNow() async {
    final res = await _functions.invoke('sync-prices'); // must be deployed
    final status = res.status ?? 0;
    final body = res.data;

    if (status >= 400) {
      throw 'Edge HTTP $status: ${_s(body)}';
    }
    if (body is Map && body['updated'] != null) {
      final n = body['updated'];
      if (n is num) return n.toInt();
      return int.tryParse(n.toString()) ?? 0;
    }
    throw 'Unexpected Edge response (status $status): ${_s(body)}';
  }

  String _s(Object? o) {
    try { return const JsonEncoder.withIndent('  ').convert(o); }
    catch (_) { return o.toString(); }
  }
}
