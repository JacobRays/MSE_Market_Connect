#!/usr/bin/env bash
set -Eeuo pipefail
PORT="${1:-8081}"
echo "Starting Flutter web (profile) on http://localhost:${PORT}"
exec flutter run -d web-server --profile --web-hostname 0.0.0.0 --web-port "${PORT}"
