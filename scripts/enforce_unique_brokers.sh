#!/usr/bin/env bash
set -Eeuo pipefail

# 1) Add an extension that provides getActiveBrokersUnique()
XFILE="lib/core/services/broker_service_x.dart"
mkdir -p "$(dirname "$XFILE")"

cat > "$XFILE" << 'DART'
import 'package:mse_market_connect/core/services/broker_service.dart';
import 'package:mse_market_connect/shared/models/broker_model.dart';

extension BrokerServiceX on BrokerService {
  // Returns brokers uniquely by id, and also collapses duplicates that share a normalized name.
  Future<List<BrokerModel>> getActiveBrokersUnique() async {
    final raw = await getActiveBrokers();

    // Primary: unique by id
    final byId = <String, BrokerModel>{};
    for (final b in raw) {
      final idKey = (b.id).toString().trim();
      if (idKey.isEmpty) continue;
      byId.putIfAbsent(idKey, () => b);
    }

    // Track normalized names already present (from unique ids)
    final seenNames = <String>{};
    for (final b in byId.values) {
      seenNames.add(_normName(b.name));
    }

    // Secondary: include any brokers with missing ids (or different ids) but new names
    final deduped = <BrokerModel>[...byId.values];
    for (final b in raw) {
      final nameKey = _normName(b.name);
      final idKey = (b.id).toString().trim();
      final alreadyById = idKey.isNotEmpty && byId.containsKey(idKey);
      if (!alreadyById && seenNames.add(nameKey)) {
        deduped.add(b);
      }
    }

    // Sort nicely by name
    deduped.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    // Debug log if duplicates were removed
    if (raw.length != deduped.length) {
      // ignore: avoid_print
      print('BrokerServiceX: removed ${raw.length - deduped.length} duplicate broker(s) (by id/name).');
    }

    return deduped;
  }

  String _normName(String s) {
    var n = s.trim().toLowerCase();
    // remove punctuation
    n = n.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    // normalize common suffix
    n = n.replaceAll(RegExp(r'\bltd\b'), 'limited');
    // collapse whitespace
    n = n.replaceAll(RegExp(r'\s+'), ' ');
    return n;
  }
}
DART

echo "Wrote: $XFILE"

# Helper: add import if missing
add_import_if_missing() {
  local file="$1"
  local import_line="import 'package:mse_market_connect/core/services/broker_service_x.dart';"
  if ! grep -qF "$import_line" "$file"; then
    local last_imp
    last_imp="$(grep -nE '^(import|part) ' "$file" | tail -n1 | cut -d: -f1 || true)"
    if [[ -n "$last_imp" ]]; then
      sed -i "${last_imp}a $import_line" "$file"
      echo " - Added import to $file"
    else
      sed -i "1i $import_line" "$file"
      echo " - Inserted import at top of $file"
    fi
  else
    echo " - Import already present in $file"
  fi
}

# 2) Patch screens to call getActiveBrokersUnique()
FILES=(
  "lib/features/brokers/presentation/broker_select_screen.dart"
  "lib/features/brokers/presentation/broker_list_screen.dart"
  "lib/features/brokers/presentation/broker_dashboard_screen.dart"
)

ts="$(date +%Y%m%d_%H%M%S)"

for f in "${FILES[@]}"; do
  if [[ -f "$f" ]]; then
    cp -a "$f" "${f}.bak.${ts}"
    echo "Backup saved: ${f}.bak.${ts}"

    # Ensure extension import is present
    add_import_if_missing "$f"

    # Replace calls to getActiveBrokers() with getActiveBrokersUnique()
    if grep -q "getActiveBrokersUnique\s*(" "$f"; then
      echo " - $f already uses getActiveBrokersUnique()"
    else
      sed -i 's/getActiveBrokers\s*(\s*)/getActiveBrokersUnique()/g' "$f"
      sed -i 's/getActiveBrokers\s*(\s*activeOnly\s*:\s*true\s*)/getActiveBrokersUnique()/g' "$f" || true
      echo " - Updated $f to use getActiveBrokersUnique()"
    fi
  else
    echo "Skip (not found): $f"
  fi
done

echo "All done. If you still see duplicates, they are likely distinct ids with near-identical names that normalize differently."
