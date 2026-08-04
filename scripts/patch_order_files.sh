#!/usr/bin/env bash
set -Eeuo pipefail

PS="lib/features/portfolio/presentation/portfolio_screen.dart"
SERV="lib/core/services/trade_order_service.dart"
IMP_LINE="import 'package:mse_market_connect/shared/models/trade_order_model.dart';"

backup() {
  local f="$1"
  [[ -f "$f" ]] || { echo "File not found: $f" >&2; return 1; }
  local ts
  ts="$(date +%Y%m%d_%H%M%S)"
  cp -a "$f" "${f}.bak.${ts}"
  echo "Backup saved: ${f}.bak.${ts}"
}

echo "==> Patching $PS (add TradeOrderModel import if missing)"
if [[ -f "$PS" ]]; then
  if grep -qF "$IMP_LINE" "$PS"; then
    echo "   - Import already present."
  else
    backup "$PS"
    last_imp="$(grep -nE '^(import|part) ' "$PS" | tail -n1 | cut -d: -f1 || true)"
    if [[ -n "${last_imp:-}" ]]; then
      sed -i "${last_imp}a $IMP_LINE" "$PS"
      echo "   - Inserted import after line $last_imp."
    else
      sed -i "1i $IMP_LINE" "$PS"
      echo "   - Inserted import at top of file."
    fi
  fi
else
  echo "   - File not found: $PS"
fi

echo
echo "==> Patching $SERV (add getMyOrderById if missing)"
if [[ -f "$SERV" ]]; then
  if grep -qE "getMyOrderById\s*\(" "$SERV"; then
    echo "   - Method already present."
  else
    if ! grep -q "class TradeOrderService" "$SERV"; then
      echo "   - Could not find class TradeOrderService in $SERV. Aborting insert."
      exit 1
    fi

    backup "$SERV"
    tmp_method="$(mktemp)"
    cat > "$tmp_method" << 'METHOD'
// Restored for OrderDetailScreen
Future<TradeOrderModel?> getMyOrderById(String orderId) async {
  final user = _client.auth.currentUser;
  if (user == null) throw StateError('User not logged in');

  final row = await _client
      .from('trade_orders')
      .select(
        'id, stock_symbol, side, quantity, status, broker_id, total_estimate, created_at, updated_at',
      )
      .eq('id', orderId)
      .eq('user_id', user.id)
      .isFilter('deleted_at', null) // if this fails in your SDK, change to: .is_('deleted_at', null)
      .maybeSingle();

  if (row == null) return null;
  return TradeOrderModel.fromMap(Map<String, dynamic>.from(row));
}
METHOD

    # Insert before the last closing brace if the file ends with a lone "}"
    if tail -n1 "$SERV" | grep -q '^[[:space:]]*}[[:space:]]*$'; then
      { head -n -1 "$SERV"; cat "$tmp_method"; echo "}"; } > "${SERV}.new"
      mv "${SERV}.new" "$SERV"
      echo "   - Inserted getMyOrderById into $SERV."
    else
      echo "   - Could not reliably locate class closing brace. Printing method for manual paste:"
      echo "-----------------"
      cat "$tmp_method"
      echo "-----------------"
    fi
    rm -f "$tmp_method"
  fi
else
  echo "   - File not found: $SERV"
fi

echo
echo "==> Done. Verifying changes:"
grep -n "trade_order_model.dart" "$PS" || true
grep -n "getMyOrderById" "$SERV" || true
