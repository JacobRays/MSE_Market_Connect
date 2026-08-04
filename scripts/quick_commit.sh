#!/usr/bin/env bash
set -Eeuo pipefail

# 0) Ensure git identity exists (only asks if missing)
if ! git config user.name >/dev/null; then
  read -rp "Git user.name: " GNAME
  git config user.name "$GNAME"
fi
if ! git config user.email >/dev/null; then
  read -rp "Git user.email: " GEMAIL
  git config user.email "$GEMAIL"
fi

# 1) Format dart (best-effort)
echo ">> formatting Dart files"
dart format lib tool supabase/functions >/dev/null 2>&1 || true

# 2) Stage and commit
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)"
echo ">> staging changes on branch: $BRANCH"
git add -A

if git diff --cached --quiet; then
  echo "No changes to commit. Pushing existing branch…"
else
  COMMIT_MSG="$(cat << 'MSG'
feat(market): containerized gainers/losers + status chip + last-updated
fix(stock): robust change_percent parsing (+ fallback from open/price), explicit select in MarketService
feat(admin): enable web sync via Edge Function on web; keep native sync on mobile
fix(orders): use 'cancelled' status to satisfy DB constraint
refactor(trade): clean TradeOrderService (pagination, cancel, hide, detail)
ui: placeholders for empty movers, improved Market page layout
MSG
)"
  echo ">> committing"
  git commit -m "$COMMIT_MSG" || true
fi

# 3) Push
echo ">> pushing to origin/$BRANCH"
git push -u origin "$BRANCH"

# 4) Print handy PR link if not on main
if [ "$BRANCH" != "main" ] && [ "$BRANCH" != "master" ]; then
  ORIGIN_URL="$(git remote get-url origin 2>/dev/null || echo '')"
  if [[ "$ORIGIN_URL" == git@github.com:*/*.git ]]; then
    REPO_PATH="${ORIGIN_URL#git@github.com:}"; REPO_PATH="${REPO_PATH%.git}"
    echo "Open PR: https://github.com/${REPO_PATH}/compare/$BRANCH?expand=1"
  elif [[ "$ORIGIN_URL" == https://github.com/*/*.git ]]; then
    REPO_PATH="${ORIGIN_URL#https://github.com/}"; REPO_PATH="${REPO_PATH%.git}"
    echo "Open PR: https://github.com/${REPO_PATH}/compare/$BRANCH?expand=1"
  fi
fi

echo "Done. Branch $BRANCH is saved remotely."
