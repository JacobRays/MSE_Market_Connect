#!/usr/bin/env bash
set -Eeuo pipefail

MODEL="lib/shared/models/stock_model.dart"
SERVICE="lib/core/services/market_service.dart"

[[ -f "$MODEL" ]] || { echo "Missing: $MODEL" >&2; exit 1; }
[[ -f "$SERVICE" ]] || { echo "Missing: $SERVICE" >&2; exit 1; }

ts="$(date +%Y%m%d_%H%M%S)"
cp -a "$MODEL" "${MODEL}.bak.${ts}"
cp -a "$SERVICE" "${SERVICE}.bak.${ts}"
echo "Backup: ${MODEL}.bak.${ts}"
echo "Backup: ${SERVICE}.bak.${ts}"

# 1) Robust StockModel parsing + computed fallback
cat > "$MODEL" << 'DART'
class StockModel {
  final int id;
  final String symbol;
  final String companyName;
  final double price;
  final double changePercent;
  final int volume;
  final bool isActive;
  final DateTime? updatedAt;

  final String? logoUrl;

  const StockModel({
    required this.id,
    required this.symbol,
    required this.companyName,
    required this.price,
    required this.changePercent,
    required this.volume,
    required this.isActive,
    this.updatedAt,
    this.logoUrl,
  });

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    final s = v.toString().replaceAll('%', '').replaceAll(',', '').trim();
    return double.tryParse(s) ?? 0.0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    final s = v.toString().replaceAll(',', '').trim();
    return int.tryParse(s) ?? 0;
  }

  factory StockModel.fromMap(Map<String, dynamic> map) {
    final price = _toDouble(map['price']);
    final open = _toDouble(map['open_price']); // may be absent
    var changePct = _toDouble(map['change_percent']);

    // If parsed change is effectively zero but open vs price shows movement, compute it.
    if (changePct.abs() < 1e-9 && open > 0 && price > 0 && (price - open).abs() > 1e-9) {
      changePct = ((price - open) / open) * 100.0;
    }

    return StockModel(
      id: (map['id'] as num).toInt(),
      symbol: (map['symbol'] ?? '').toString(),
      companyName: (map['company_name'] ?? '').toString(),
      price: price,
      changePercent: changePct,
      volume: _toInt(map['volume']),
      isActive: map['is_active'] as bool? ?? true,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
      logoUrl: map['logo_url'] as String?,
    );
  }
}
DART

# 2) Explicitly select columns including open_price
python3 - << 'PY' "$SERVICE"
import io, re, sys
p = sys.argv[1]
s = io.open(p, 'r', encoding='utf-8').read()

# Replace a plain .select() with an explicit projection
s = re.sub(
    r"\.select\(\s*\)",
    ".select('id, symbol, company_name, price, change_percent, volume, is_active, updated_at, logo_url, open_price')",
    s,
    count=1
)

io.open(p, 'w', encoding='utf-8', newline='').write(s)
print("Updated MarketService.getStocks() to select explicit columns.")
PY

echo "Patched StockModel + MarketService."

