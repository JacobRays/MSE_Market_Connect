#!/usr/bin/env bash
set -Eeuo pipefail
echo ">> flutter clean"
flutter clean
echo ">> flutter pub get"
flutter pub get
echo ">> run web-server :8080"
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
