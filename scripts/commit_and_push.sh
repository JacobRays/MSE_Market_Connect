#!/usr/bin/env bash
set -Eeuo pipefail

# 0) Ensure git identity exists (only sets if missing)
if ! git config user.name >/dev/null; then
  read -rp "Git user.name (e.g. Your Name): " GNAME
  git config user.name "$GNAME"
fi
if ! git config user.email >/dev/null; then
  read -rp "Git user.email (e.g. you@example.com): " GEMAIL
  git config user.email "$GEMAIL"
fi

# 1) Format Dart code (ignore errors so we still commit)
echo ">> dart format"
dart format lib tool || true

# 2) Choose branch
CUR_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)"
NEW_BRANCH="feat/orders-broker-fixes-$(date +%Y%m%d_%H%M)"
if [[ "$CUR_BRANCH" == "main" || "$CUR_BRANCH" == "master" ]]; then
  echo ">> creating branch: $NEW_BRANCH"
  git checkout -b "$NEW_BRANCH"
  CUR_BRANCH="$NEW_BRANCH"
else
  echo ">> using current branch: $CUR_BRANCH"
fi

# 3) Stage and commit
echo ">> git add -A"
git add -A

if git diff --cached --quiet; then
  echo "No staged changes. Nothing to commit."
  exit 0
fi

COMMIT_MSG="$(cat << 'MSG'
feat(trade): enhance My Orders (filters, pagination, cancel, CSV, realtime)

- Add status filters + saved sort
- Infinite scroll with server-side pagination via trade_orders_app view
- Cancel order for submitted/approved
- Soft delete (hide) preserved
- CSV export (web download)
- Realtime updates on order status changes

fix(brokers): remove true duplicates by merge and hard-delete; fill missing contact info

refactor(service): clean TradeOrderService using view + proper Postgrest builders

docs(sql): add trade_orders_app view (unified reject_reason via JSON)
MSG
)"

echo ">> git commit"
git commit -m "$COMMIT_MSG"

# 4) Push
echo ">> git push -u origin $CUR_BRANCH"
git push -u origin "$CUR_BRANCH"

# 5) Offer to open PR if gh is available
if command -v gh >/dev/null 2>&1; then
  echo ">> You can create a PR now:"
  echo "   gh pr create --fill --base main --head $CUR_BRANCH"
else
  echo ">> Open a PR here (replace owner/repo if needed):"
  ORIGIN_URL="$(git remote get-url origin 2>/dev/null || echo '')"
  if [[ "$ORIGIN_URL" == git@github.com:*/*.git ]]; then
    REPO_PATH="${ORIGIN_URL#git@github.com:}"
    REPO_PATH="${REPO_PATH%.git}"
    echo "   https://github.com/${REPO_PATH}/compare/$CUR_BRANCH?expand=1"
  elif [[ "$ORIGIN_URL" == https://github.com/*/*.git ]]; then
    REPO_PATH="${ORIGIN_URL#https://github.com/}"
    REPO_PATH="${REPO_PATH%.git}"
    echo "   https://github.com/${REPO_PATH}/compare/$CUR_BRANCH?expand=1"
  else
    echo "   Go to your repo on GitHub → Compare & pull request → select branch $CUR_BRANCH"
  fi
fi

echo "Done."
