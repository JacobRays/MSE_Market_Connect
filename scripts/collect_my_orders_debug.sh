#!/usr/bin/env bash
set -Eeuo pipefail

OUT="debug_my_orders.txt"
: > "$OUT"

dump_file() {
  local f="$1"
  echo "==== $f ====" | tee -a "$OUT"
  if [[ -f "$f" ]]; then
    echo "-- imports --" | tee -a "$OUT"
    grep -nE "^(import|part) " "$f" | tee -a "$OUT" || true
    echo "-- content (with line numbers) --" | tee -a "$OUT"
    nl -ba "$f" | sed -e 's/\t/    /g' | tee -a "$OUT"
  else
    echo "(missing)" | tee -a "$OUT"
  fi
  echo | tee -a "$OUT"
}

# Key files
dump_file lib/features/trade/presentation/my_orders_screen.dart
dump_file lib/core/services/trade_order_service.dart
dump_file lib/shared/models/trade_order_model.dart
dump_file lib/features/trade/presentation/order_detail_screen.dart

# Method references
echo "==== method references (service calls) ====" | tee -a "$OUT"
grep -RInE "getMyOrdersPage|getMyOrdersFiltered|getMyOrders\(|getMyOrderById|softDeleteMyOrder|cancelMyOrder" lib \
  | tee -a "$OUT" || true
echo | tee -a "$OUT"

# Quick signatures in service
echo "==== service signatures (first line only) ====" | tee -a "$OUT"
grep -nE "Future<.*>\s+(getMyOrdersPage|getMyOrdersFiltered|getMyOrders|getMyOrderById|softDeleteMyOrder|cancelMyOrder)\s*\(" \
  lib/core/services/trade_order_service.dart | tee -a "$OUT" || true
echo | tee -a "$OUT"

# Pubspec name/version (sanity)
echo "==== pubspec name/version ====" | tee -a "$OUT"
grep -nE "^(name|version):" pubspec.yaml | tee -a "$OUT" || true
echo | tee -a "$OUT"

# Optional: light analyzer on just these files
echo "==== dart analyze (subset) ====" | tee -a "$OUT"
dart analyze lib/core/services/trade_order_service.dart lib/features/trade/presentation/my_orders_screen.dart \
  2>&1 | tee -a "$OUT" || true
echo | tee -a "$OUT"

echo "Done. See $OUT"
