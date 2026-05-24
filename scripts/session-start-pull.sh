#!/usr/bin/env bash
# session-start-pull.sh — auto git pull on Claude session start
# Wired via .claude/settings.json (SessionStart hook).
#
# Behavior:
#   - Throttled: only runs once every 6 hours (state in .index/last-pull)
#   - Non-blocking: any failure is logged and ignored — never breaks Claude
#   - Quiet by default: prints one line on success, silent on no-op
#   - Skips if working tree has uncommitted changes (avoid conflicts)

set -uo pipefail

THROTTLE_SECONDS=21600   # 6 hours
STATE_FILE=".index/last-pull"
LOG_FILE=".index/last-pull.log"

# Must be inside a git repo with origin
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
git remote get-url origin >/dev/null 2>&1 || exit 0

mkdir -p .index 2>/dev/null || true

# Throttle check
NOW=$(date +%s)
LAST=$(cat "$STATE_FILE" 2>/dev/null || echo 0)
if [ $((NOW - LAST)) -lt $THROTTLE_SECONDS ]; then
  exit 0
fi

# Don't pull if working tree is dirty (let the user commit/stash first)
if ! git diff --quiet || ! git diff --staged --quiet; then
  echo "[skill-sync] working tree has uncommitted changes — skipping auto-pull" >> "$LOG_FILE"
  exit 0
fi

# Pull quietly
BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")
if OUT=$(git pull --quiet --ff-only origin "$BRANCH" 2>&1); then
  echo "$NOW" > "$STATE_FILE"
  # Count agents/skills changes if any
  CHANGED=$(git log -1 --name-only --pretty=format: | grep -c "^\.claude/\(agents\|skills\)/" 2>/dev/null || echo 0)
  if [ "$CHANGED" -gt 0 ]; then
    echo "✓ pulled $CHANGED new/updated agent(s)/skill(s) from origin"
  fi
  exit 0
else
  # Non-fast-forward or network error — log + ignore
  echo "[skill-sync] $(date -Iseconds) pull failed: $OUT" >> "$LOG_FILE"
  exit 0
fi
