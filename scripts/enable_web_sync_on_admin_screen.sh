#!/usr/bin/env bash
set -Eeuo pipefail

EDGE_SVC="lib/core/services/price_sync_edge_service.dart"
ADMIN="lib/features/admin/presentation/admin_sync_prices_screen.dart"

# 1) Create a tiny edge sync service (calls your Supabase Edge Function 'sync-prices')
mkdir -p "$(dirname "$EDGE_SVC")"
cat > "$EDGE_SVC" << 'DART'
import 'package:supabase_flutter/supabase_flutter.dart';

class PriceSyncEdgeService {
  final _functions = Supabase.instance.client.functions;

  Future<int> syncNow() async {
    final res = await _functions.invoke('sync-prices'); // make sure your Edge Function is deployed with this name
    final data = res.data;
    if (data is Map && data['updated'] != null) {
      final n = data['updated'];
      if (n is num) return n.toInt();
      return int.tryParse(n.toString()) ?? 0;
    }
    // fall back to a generic parse if needed
    return 0;
  }
}
DART

# 2) Patch your AdminSyncPricesScreen to use edge function on web, mobile service on device
[[ -f "$ADMIN" ]] || { echo "Missing: $ADMIN"; exit 1; }
cp -a "$ADMIN" "${ADMIN}.bak.$(date +%Y%m%d_%H%M%S)"

python3 - << 'PY' "$ADMIN"
import io, re, sys
p = sys.argv[1]
s = io.open(p, 'r', encoding='utf-8').read()

# import edge service
if "price_sync_edge_service.dart" not in s:
    s = s.replace(
        "import 'package:mse_market_connect/core/services/mse_price_sync_service.dart';",
        "import 'package:mse_market_connect/core/services/mse_price_sync_service.dart';\nimport 'package:mse_market_connect/core/services/price_sync_edge_service.dart';"
    )

# add _edge field after _prices
s = s.replace(
    "final _prices = MsePriceSyncService();",
    "final _prices = MsePriceSyncService();\n  final _edge = PriceSyncEdgeService();"
)

# enable sync on web by removing hard disable and using edge function under kIsWeb
# 1) Replace the disabled banner
s = s.replace(
    "if (disabled)\n            Card(\n              color: Colors.amber.withValues(alpha: 0.18),\n              child: const Padding(\n                padding: EdgeInsets.all(16),\n                child: Text(\n                  'Sync is disabled on Web preview.\\n'\n                  'Install the Android APK and run Sync on your phone to fetch MSE prices.',\n                ),\n              ),\n            ),",
    "if (kIsWeb)\n            Card(\n              color: Colors.green.withValues(alpha: 0.12),\n              child: const Padding(\n                padding: EdgeInsets.all(16),\n                child: Text(\n                  'Web sync uses a Supabase Edge Function.\\n'\n                  'Click Sync to fetch prices now.',\n                ),\n              ),\n            ),"
)

# 2) Remove 'disabled' gating in onTap for prices/news
s = re.sub(r"final\s+disabled\s*=\s*kIsWeb\s*;", "final disabled = false;", s)

# 3) Switch _syncPrices to call edge on web, mobile service on device
s = re.sub(
    r"Future<void>\s+_syncPrices\(\)\s+async\s*\{[\s\S]*?\}",
    """Future<void> _syncPrices() async {
    setState(() => _syncingPrices = true);
    try {
      final int count;
      if (kIsWeb) {
        count = await _edge.syncNow(); // Edge Function path
      } else {
        count = await _prices.syncMainboardPrices(); // Mobile (Android/iOS)
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prices synced: $count stocks updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Price sync failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _syncingPrices = false);
    }
  }""",
    s,
    flags=re.S
)

# 4) Allow tapping on web (remove disabled from onTap)
s = s.replace(
    "onTap: (disabled || _syncingPrices) ? null : _syncPrices,",
    "onTap: _syncingPrices ? null : _syncPrices,"
)
s = s.replace(
    "onTap: (disabled || _syncingNews) ? null : _syncNews,",
    "onTap: _syncingNews ? null : _syncNews,"
)

io.open(p, 'w', encoding='utf-8', newline='').write(s)
print(f"Patched: {p}")
PY

echo "Done. Web admin can now sync via Edge Function; mobile keeps native scraper."
