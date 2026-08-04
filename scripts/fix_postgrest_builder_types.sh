#!/usr/bin/env bash
set -Eeuo pipefail

FILE="lib/core/services/trade_order_service.dart"
[[ -f "$FILE" ]] || { echo "File not found: $FILE" >&2; exit 1; }

ts="$(date +%Y%m%d_%H%M%S)"
cp -a "$FILE" "${FILE}.bak.${ts}"
echo "Backup: ${FILE}.bak.${ts}"

# Rewrite only the getMyOrdersPage method to avoid builder type mismatches
python3 - << 'PY' "$FILE"
import io, re, sys
p = sys.argv[1]
s = io.open(p, 'r', encoding='utf-8').read()

pat = re.compile(r"""
  Future<OrdersPage>\s+getMyOrdersPage\s*\(
  [\s\S]*?
  \)\s+async\s*\{
  [\s\S]*?
  \}
""", re.X)

new_block = r"""
  Future<OrdersPage> getMyOrdersPage({
    String? status,
    bool ascending = false,
    int limit = 30,
    int offset = 0,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('User not logged in');

    final base = _client
        .from('trade_orders_app') // view with unified reject_reason
        .select('*')
        .eq('user_id', user.id)
        .isFilter('deleted_at', null);

    final ordered = (status != null && status.trim().isNotEmpty)
        ? base.eq('status', status).order('created_at', ascending: ascending)
        : base.order('created_at', ascending: ascending);

    // inclusive range end -> ask for limit+1 to detect hasMore
    final rows = await ordered.range(offset, offset + limit);

    var list = (rows as List).cast<Map<String, dynamic>>();
    final hasMore = list.length > limit;
    if (hasMore) list = list.sublist(0, limit);

    final models = list.map((e) => TradeOrderModel.fromMap(e)).toList();
    if (models.isEmpty) return OrdersPage(items: const [], hasMore: false, nextOffset: offset);

    final brokerIds = models.map((o) => o.brokerId).toSet().toList();
    final brokersResp = await _client
        .from('brokers')
        .select('id,name')
        .inFilter('id', brokerIds);

    final brokers = (brokersResp as List).cast<Map<String, dynamic>>();
    final nameById = {for (final b in brokers) b['id'] as String: b['name'] as String};

    final enriched = models.map((o) => o.copyWith(brokerName: nameById[o.brokerId])).toList();
    return OrdersPage(items: enriched, hasMore: hasMore, nextOffset: offset + enriched.length);
  }
"""

s2, n = pat.subn(new_block, s, count=1)
if n == 0:
    print("Could not locate getMyOrdersPage(...) to patch. Aborting.", file=sys.stderr)
    sys.exit(1)
io.open(p, 'w', encoding='utf-8', newline='').write(s2)
print("Patched getMyOrdersPage.")
PY

echo "Done."
