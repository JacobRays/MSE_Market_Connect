#!/usr/bin/env bash
set -Eeuo pipefail

F="lib/features/trade/presentation/my_orders_screen.dart"
[[ -f "$F" ]] || { echo "Missing: $F" >&2; exit 1; }

ts="$(date +%Y%m%d_%H%M%S)"
cp -a "$F" "${F}.bak.${ts}"
echo "Backup: ${F}.bak.${ts}"

python3 - << 'PY' "$F"
import io, re, sys
p = sys.argv[1]
s = io.open(p, 'r', encoding='utf-8').read()

# 1) Ensure the statuses list includes received and cancelled
pat = re.compile(r"static const List<String>\s+_statuses\s*=\s*\[[^\]]*\];", re.S)
rep = """static const List<String> _statuses = [
    'submitted',
    'received',
    'approved',
    'rejected',
    'executed',
    'settled',
    'cancelled',
  ];"""
s, n = pat.subn(rep, s, count=1)
if n == 0:
  # Fallback: try to insert a fresh block after enum/fields
  ins_at = s.find("class _MyOrdersScreenState")
  if ins_at == -1: ins_at = 0
  brace = s.find("{", ins_at)
  if brace == -1: brace = ins_at
  s = s[:brace+1] + "\n  " + rep + "\n" + s[brace+1:]

# 2) Add a central cancel policy constant if missing
if "_cancelableStatuses" not in s:
  # Insert right after _statuses block we just wrote
  anchor = s.find("static const List<String> _statuses")
  if anchor != -1:
    line_end = s.find("];", anchor)
    if line_end != -1:
      line_end += 2
      policy = """

  // Cancel policy: allowed statuses for cancel action (default: submitted, approved).
  // If you decide to allow cancelling 'received' as well, add it here.
  static const List<String> _cancelableStatuses = ['submitted','approved'];
"""
      s = s[:line_end] + policy + s[line_end:]

# 3) Replace inline canCancel check with the constant
s = re.sub(
  r"final\s+canCancel\s*=\s*o\.status\.toLowerCase\(\)\s*==\s*'submitted'\s*\|\|\s*o\.status\.toLowerCase\(\)\s*==\s*'approved'\s*;",
  "final canCancel = _cancelableStatuses.contains(o.status.toLowerCase());",
  s
)

io.open(p, 'w', encoding='utf-8', newline='').write(s)
print("Patched status filters and cancel policy in", p)
PY
