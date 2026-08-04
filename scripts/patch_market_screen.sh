#!/usr/bin/env bash
set -Eeuo pipefail

MS="lib/features/market/presentation/market_screen.dart"
IMP_LINE="import 'package:mse_market_connect/core/theme/app_theme.dart';"

backup() {
  local f="$1"
  [[ -f "$f" ]] || { echo "File not found: $f" >&2; exit 1; }
  local ts
  ts="$(date +%Y%m%d_%H%M%S)"
  cp -a "$f" "${f}.bak.${ts}"
  echo "Backup saved: ${f}.bak.${ts}"
}

echo "==> Patching $MS"
backup "$MS"

# 1) Ensure AppTheme import is present
if grep -qF "$IMP_LINE" "$MS"; then
  echo "   - AppTheme import already present."
else
  last_imp_line="$(grep -nE '^(import|part) ' "$MS" | tail -n1 | cut -d: -f1 || true)"
  if [[ -n "$last_imp_line" ]]; then
    sed -i "${last_imp_line}a $IMP_LINE" "$MS"
    echo "   - Inserted AppTheme import after line $last_imp_line."
  else
    sed -i "1i $IMP_LINE" "$MS"
    echo "   - Inserted AppTheme import at top of file."
  fi
fi

# 2) Make the error-state Icon non-const ONLY if it uses AppTheme.*
python3 - << 'PY' "$MS"
import re, sys, io
path = sys.argv[1]
with io.open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

changed = False
i = 0
while i < len(lines):
    if re.match(r'^\s*const\s+Icon\s*\(', lines[i]):
        window = ''.join(lines[i:i+12])  # look ahead a bit
        if 'AppTheme.' in window:
            lines[i] = re.sub(r'\bconst\s+Icon', 'Icon', lines[i])
            changed = True
            # no need to skip; continue scanning
    i += 1

if changed:
    with io.open(path, 'w', encoding='utf-8', newline='') as f:
        f.write(''.join(lines))
    print("   - Updated const Icon(...) -> Icon(...) where AppTheme.* is used.")
else:
    print("   - No const Icon with AppTheme.* found to change (already good).")
PY

echo
echo "==> Verification:"
grep -n "app_theme.dart" "$MS" || true
grep -nE "const\s+Icon\s*\(" "$MS" || echo "   - No remaining const Icon(…) lines."
echo "==> Done."
