#!/usr/bin/env bash
set -Eeuo pipefail

# 1) Service: use 'cancelled' (UK) instead of 'canceled'
SERVICE="lib/core/services/trade_order_service.dart"
[[ -f "$SERVICE" ]] || { echo "Missing: $SERVICE" >&2; exit 1; }
cp -a "$SERVICE" "${SERVICE}.bak.$(date +%Y%m%d_%H%M%S)"
sed -i "s/'canceled'/'cancelled'/g" "$SERVICE"

# 2) My Orders filter list: add 'cancelled' so users can filter by it
SCREEN="lib/features/trade/presentation/my_orders_screen.dart"
[[ -f "$SCREEN" ]] || { echo "Missing: $SCREEN" >&2; exit 1; }
cp -a "$SCREEN" "${SCREEN}.bak.$(date +%Y%m%d_%H%M%S)"
# Insert cancelled in the _statuses list if it's missing
if ! grep -q "'cancelled'" "$SCREEN"; then
  python3 - << 'PY' "$SCREEN"
import io, re, sys
p = sys.argv[1]
s = io.open(p, 'r', encoding='utf-8').read()
pat = re.compile(r"static const List<String>\s+_statuses\s*=\s*\[\s*'submitted',\s*'approved',\s*'rejected',\s*'executed',\s*'settled',?\s*\];", re.S)
rep = """static const List<String> _statuses = [
    'submitted',
    'approved',
    'rejected',
    'executed',
    'settled',
    'cancelled',
  ];"""
ns, n = pat.subn(rep, s, count=1)
if n == 0:
    # Try a more generic insert after 'settled'
    ns = s.replace("'settled',", "'settled',\n    'cancelled',")
io.open(p, 'w', encoding='utf-8', newline='').write(ns)
print("Patched _statuses with 'cancelled'")
PY
fi

echo "Patched app to use 'cancelled'."
