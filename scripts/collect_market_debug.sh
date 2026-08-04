#!/usr/bin/env bash
set -Eeuo pipefail

OUT="debug_market.txt"
: > "$OUT"

dump() {
  local f="$1"
  echo "==== $f ====" | tee -a "$OUT"
  if [[ -f "$f" ]]; then
    echo "-- imports --" | tee -a "$OUT"
    grep -nE "^(import|part) " "$f" | tee -a "$OUT" || true
    echo "-- content (with line numbers) --" | tee -a "$OUT"
    nl -ba "$f" | sed 's/\t/    /g' | tee -a "$OUT"
  else
    echo "(missing)" | tee -a "$OUT"
  fi
  echo | tee -a "$OUT"
}

# Key files
dump lib/features/market/presentation/market_screen.dart
dump lib/core/services/market_service.dart
dump lib/shared/models/stock_model.dart

# If you have sync services that populate stocks/change_percent
dump lib/core/services/mse_price_sync_service.dart
dump lib/core/services/mse_sync_service.dart

# Where is change_percent referenced?
echo "==== grep: change_percent / changePercent ====" | tee -a "$OUT"
grep -RIn "change_percent\|changePercent" lib | tee -a "$OUT" || true
echo | tee -a "$OUT"

# Quick sanity: any SELECT missing change_percent?
echo "==== grep: SELECT lines in market_service ====" | tee -a "$OUT"
grep -nE "select\(|\.select\(" lib/core/services/market_service.dart | tee -a "$OUT" || true
echo | tee -a "$OUT"

echo "Done. See $OUT"
