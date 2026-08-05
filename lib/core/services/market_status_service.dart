import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mse_market_connect/shared/models/stock_model.dart';

class MarketStatusData {
  final String status; // 'open' | 'closed' | 'holiday' | 'unknown'
  final String source; // 'supabase' | 'heuristic'
  final DateTime checkedAt;
  final String? message;
  const MarketStatusData({
    required this.status,
    required this.source,
    required this.checkedAt,
    this.message,
  });
}

class MarketStatusService {
  final SupabaseClient _db = Supabase.instance.client;

  // Primary: try Supabase table 'market_status' (status, message, updated_at)
  // Fallback: infer from stocks' changePercent + Malawi time window
  Future<MarketStatusData> getStatus({List<StockModel>? snapshot}) async {
    try {
      final row = await _db
          .from('market_status')
          .select('status, message, updated_at')
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (row != null) {
        final st = (row['status'] ?? '').toString().toLowerCase();
        final norm = _normalize(st);
        final when =
            DateTime.tryParse((row['updated_at'] ?? '').toString()) ??
            DateTime.now().toUtc();
        return MarketStatusData(
          status: norm,
          source: 'supabase',
          checkedAt: when,
          message: (row['message'] ?? '').toString(),
        );
      }
    } catch (_) {
      // table may not exist yet; ignore
    }
    // Heuristic fallback
    return _inferFromStocks(snapshot);
  }

  MarketStatusData _inferFromStocks(List<StockModel>? stocks) {
    final nowUtc = DateTime.now().toUtc();
    // Malawi time is UTC+2 (CAT). No DST.
    final mw = nowUtc.add(const Duration(hours: 2));
    final isWeekday =
        mw.weekday >= DateTime.monday && mw.weekday <= DateTime.friday;
    final inWindow =
        (mw.hour > 9 && mw.hour < 16) ||
        (mw.hour == 9 && mw.minute >= 0) ||
        (mw.hour == 16 && mw.minute == 0);

    bool anyMovement = false;
    DateTime? latest;
    if (stocks != null && stocks.isNotEmpty) {
      anyMovement = stocks.any((s) => s.changePercent.abs() > 1e-6);
      for (final s in stocks) {
        final t = s.updatedAt;
        if (t != null && (latest == null || t.isAfter(latest))) latest = t;
      }
    }
    // If any stock moved today during window, call it open
    if (anyMovement && isWeekday && inWindow) {
      return MarketStatusData(
        status: 'open',
        source: 'heuristic',
        checkedAt: nowUtc,
        message: 'Movement detected',
      );
    }
    // Else, likely closed (or pre-open). Add a soft hint if within window.
    final msg = isWeekday && inWindow
        ? 'No movement yet'
        : 'Outside trading hours';
    return MarketStatusData(
      status: 'closed',
      source: 'heuristic',
      checkedAt: nowUtc,
      message: msg,
    );
  }

  String _normalize(String s) {
    switch (s) {
      case 'open':
      case 'opened':
        return 'open';
      case 'closed':
      case 'close':
        return 'closed';
      case 'holiday':
        return 'holiday';
      default:
        return 'unknown';
    }
  }
}
