#!/usr/bin/env bash
set -Eeuo pipefail
PORT="${1:-8080}"
echo "Killing anything on TCP:${PORT}..."
if command -v lsof >/dev/null 2>&1; then
  PIDS="$(lsof -ti:${PORT} -sTCP:LISTEN || true)"
  [[ -n "$PIDS" ]] && kill -9 $PIDS || echo "No listener via lsof."
fi
if command -v fuser >/dev/null 2>&1; then
  fuser -k "${PORT}"/tcp 2>/dev/null || echo "No listener via fuser."
fi
if command -v ss >/dev/null 2>&1; then
  if ss -ltn | awk '{print $4}' | grep -qE "[:.]${PORT}$"; then
    echo "Warning: something still bound to :${PORT} (check container processes)."
  else
    echo "Port ${PORT} looks free."
  fi
fi
