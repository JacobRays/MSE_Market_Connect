#!/usr/bin/env bash
set -Eeuo pipefail

PREFERRED_PORTS=(8080 8081 5173 3000 9000)

port_in_use() {
  local p="$1"
  if command -v ss >/dev/null 2>&1; then
    ss -ltn | awk '{print $4}' | grep -qE "[:.]${p}$"
  elif command -v lsof >/dev/null 2>&1; then
    lsof -iTCP -sTCP:LISTEN -P -n | grep -q ":${p} "
  else
    fuser -n tcp "${p}" >/dev/null 2>&1
  fi
}

# If something is already listening on a preferred port, assume it's your dev server
for p in "${PREFERRED_PORTS[@]}"; do
  if port_in_use "$p"; then
    echo "Flutter web server already running on http://localhost:${p}"
    echo "Tip: In Codespaces Ports panel, set it to Public and pin it."
    exit 0
  fi
done

# Check if --web-renderer is supported (older web-server builds may not have it)
RENDER_FLAG=""
if flutter run -d web-server -h 2>&1 | grep -q -- "--web-renderer"; then
  RENDER_FLAG="--web-renderer html"
fi

# Start on the first free port
for p in "${PREFERRED_PORTS[@]}"; do
  if ! port_in_use "$p"; then
    echo "Starting Flutter web dev server on http://localhost:${p}"
    exec flutter run -d web-server --web-hostname 0.0.0.0 --web-port "${p}" ${RENDER_FLAG}
  fi
done

echo "No free port found among: ${PREFERRED_PORTS[*]}"
exit 1
