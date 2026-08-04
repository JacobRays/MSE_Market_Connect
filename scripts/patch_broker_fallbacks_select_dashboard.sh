#!/usr/bin/env bash
set -Eeuo pipefail

patch_file() {
  local f="$1"
  [[ -f "$f" ]] || { echo "Skip (not found): $f"; return; }
  local ts
  ts="$(date +%Y%m%d_%H%M%S)"
  cp -a "$f" "${f}.bak.${ts}"
  echo "Backup: ${f}.bak.${ts}"

  python3 - << 'PY' "$f"
import io, re, sys
p = sys.argv[1]
with io.open(p, 'r', encoding='utf-8') as f:
    s = f.read()

# Try to find the ListTile subtitle/lines area and replace with fallbacks
# We look for a lines list like in list screen or a subtitle build.
changed = False

# 1) Replace a simple 'subtitle: Text(...)' with composed lines using fallbacks
subtitle_pat = re.compile(r"subtitle:\s*Text\((?P<body>[^)]+)\),", re.S)
if subtitle_pat.search(s):
    repl = """subtitle: Text([
  // Email fallback
  (() {
    final primaryEmail = (b.email ?? '').trim();
    final altEmail = (b.altEmail ?? '').trim();
    final emailLine = primaryEmail.isNotEmpty ? primaryEmail : altEmail;
    return emailLine;
  })(),
  // Phone fallback (merge unique by last-9)
  (() {
    String digitsOnly(String x) => x.replaceAll(RegExp(r'[^0-9]'), '');
    String last9(String x) { final d = digitsOnly(x); return d.length >= 9 ? d.substring(d.length - 9) : d; }
    bool hasNum(List<String> bag, String cand) => bag.any((v) => digitsOnly(v).contains(last9(cand)));
    final raw = <String>[(b.phone ?? '').trim(), (b.altPhone ?? '').trim()];
    final uniq = <String>[];
    for (final p in raw) {
      if (p.isEmpty) continue;
      if (!hasNum(uniq, p)) uniq.add(p);
    }
    return uniq.join(' / ');
  })(),
].where((e) => e != null && e.trim().isNotEmpty).join('\\n')),"""
    s, n = subtitle_pat.subn(repl, s, count=1)
    if n: changed = True

# 2) Replace lines array if present
lines_pat = re.compile(r"final\s+lines\s*=\s*<String>\s*\[\s*.*?\];", re.S)
if lines_pat.search(s):
    repl = """final primaryEmail = (b.email ?? '').trim();
final altEmail = (b.altEmail ?? '').trim();
final emailLine = primaryEmail.isNotEmpty ? primaryEmail : altEmail;

String digitsOnly(String x) => x.replaceAll(RegExp(r'[^0-9]'), '');
String last9(String x) { final d = digitsOnly(x); return d.length >= 9 ? d.substring(d.length - 9) : d; }
bool hasNum(String bag, String cand) => digitsOnly(bag).contains(last9(cand));

final phonesRaw = <String>[
  (b.phone ?? '').trim(),
  (b.altPhone ?? '').trim(),
];
final phones = <String>[];
for (final p in phonesRaw) {
  if (p.isEmpty) continue;
  final exists = phones.any((x) => hasNum(x, p));
  if (!exists) phones.add(p);
}
final phoneLine = phones.join(' / ');

final lines = <String>[
  'Fee: ${(b.feeRate * 100).toStringAsFixed(1)}%',
  if (emailLine.isNotEmpty) emailLine,
  if (phoneLine.isNotEmpty) phoneLine,
];"""
    s, n = lines_pat.subn(repl, s, count=1)
    if n: changed = True

if not changed:
    print(f"No fallback patch applied to {p} (patterns not found).")
    sys.exit(0)

with io.open(p, 'w', encoding='utf-8', newline='') as f:
    f.write(s)
print(f"Patched fallbacks in {p}")
PY
}

patch_file lib/features/brokers/presentation/broker_select_screen.dart
patch_file lib/features/brokers/presentation/broker_dashboard_screen.dart

echo "Done. Rebuild your app."
