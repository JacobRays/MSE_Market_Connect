#!/usr/bin/env bash
set -Eeuo pipefail

OUT="debug_snippets.txt"
: > "$OUT"

dump_file() {
  local f="$1"
  echo "==== $f ====" | tee -a "$OUT"
  if [[ -f "$f" ]]; then
    echo "-- imports --" | tee -a "$OUT"
    grep -nE "^(import|part) " "$f" | tee -a "$OUT" || true
    echo "-- content (with line numbers) --" | tee -a "$OUT"
    nl -ba "$f" | tee -a "$OUT"
  else
    echo "(missing)" | tee -a "$OUT"
  fi
  echo | tee -a "$OUT"
}

# Key files
dump_file lib/shared/models/trade_order_model.dart
dump_file lib/core/services/trade_order_service.dart
dump_file lib/features/trade/presentation/order_detail_screen.dart
dump_file lib/features/portfolio/presentation/portfolio_screen.dart

# Where is the model actually defined?
echo "==== where is TradeOrderModel defined? ====" | tee -a "$OUT"
grep -RInE "class[[:space:]]+TradeOrderModel" lib | tee -a "$OUT" || true
echo | tee -a "$OUT"

# Who calls which method name?
echo "==== references to getMyOrderById / getOrderById ====" | tee -a "$OUT"
grep -RInE "getMyOrderById|getOrderById" lib | tee -a "$OUT" || true
echo | tee -a "$OUT"

# Any imports pointing to the wrong path?
echo "==== references to trade_order_model import paths ====" | tee -a "$OUT"
grep -RIn "trade_order_model.dart" lib | tee -a "$OUT" || true
echo | tee -a "$OUT"

# Sanity: list the files we tried to read
echo "==== ls -l of target files ====" | tee -a "$OUT"
ls -l \
  lib/shared/models/trade_order_model.dart \
  lib/core/services/trade_order_service.dart \
  lib/features/trade/presentation/order_detail_screen.dart \
  lib/features/portfolio/presentation/portfolio_screen.dart 2>/dev/null | tee -a "$OUT" || true

echo "Done. Collected snippets saved to: $OUT" | tee -a "$OUT"
