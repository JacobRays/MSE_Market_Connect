#!/usr/bin/env bash
set -Eeuo pipefail
TOOL="${1:-}"
[[ -z "$TOOL" || ! -f "$TOOL" ]] && { echo "Usage: $0 tool.dart"; exit 1; }
read -rp "SUPABASE_URL: " SUPABASE_URL
read -rsp "SUPABASE_SERVICE_ROLE_KEY (hidden, paste + Enter): " SUPABASE_SERVICE_ROLE_KEY
echo
echo "Key length: ${#SUPABASE_SERVICE_ROLE_KEY}  fingerprint: ${SUPABASE_SERVICE_ROLE_KEY:0:4}****${SUPABASE_SERVICE_ROLE_KEY: -4}"
SUPABASE_URL="$SUPABASE_URL" SUPABASE_SERVICE_ROLE_KEY="$SUPABASE_SERVICE_ROLE_KEY" dart run "$TOOL"
unset SUPABASE_URL SUPABASE_SERVICE_ROLE_KEY
