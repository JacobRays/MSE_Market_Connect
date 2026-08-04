#!/usr/bin/env bash
set -Eeuo pipefail

FILE="lib/features/brokers/presentation/broker_dashboard_screen.dart"
LATEST_BAK="$(ls -t ${FILE}.bak.* 2>/dev/null | head -1 || true)"

if [[ -z "$LATEST_BAK" ]]; then
  echo "No backup found for $FILE"
  exit 1
fi

echo "Restoring: $LATEST_BAK -> $FILE"
cp -f "$LATEST_BAK" "$FILE"
echo "Restored."
