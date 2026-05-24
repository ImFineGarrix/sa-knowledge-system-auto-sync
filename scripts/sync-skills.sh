#!/usr/bin/env bash
# sync-skills.sh — manually pull latest agents + skills from upstream
# Usage:  ./scripts/sync-skills.sh [--quiet]
#
# Safe: only touches .claude/agents/, .claude/skills/, and ProgramType_Skills/.
# Your Memory/, Projects/, reference_data/, Tech/, MOC/, Templates/ are NEVER modified.

set -euo pipefail

UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/ZaynTRPW/sa-knowledge-system.git}"
UPSTREAM_BRANCH="${UPSTREAM_BRANCH:-main}"
SYNC_PATHS=(".claude/agents" ".claude/skills" "ProgramType_Skills")
QUIET=0
[ "${1:-}" = "--quiet" ] && QUIET=1

log() { [ "$QUIET" = "1" ] || echo "$@"; }

# Ensure we're inside a git repo
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "✗ not a git repository" >&2; exit 1;
}

# Ensure upstream remote exists
if ! git remote get-url upstream >/dev/null 2>&1; then
  log "→ adding upstream remote"
  git remote add upstream "$UPSTREAM_URL"
fi

log "→ fetching upstream/$UPSTREAM_BRANCH"
git fetch --quiet upstream "$UPSTREAM_BRANCH"

CHANGED_FILES=0
for p in "${SYNC_PATHS[@]}"; do
  if git cat-file -e "upstream/$UPSTREAM_BRANCH:$p" 2>/dev/null; then
    BEFORE=$(git ls-files "$p" 2>/dev/null | wc -l | tr -d ' ')
    git checkout --quiet "upstream/$UPSTREAM_BRANCH" -- "$p" 2>/dev/null || true
    AFTER=$(git ls-files "$p" 2>/dev/null | wc -l | tr -d ' ')
    log "  ✓ $p ($AFTER files)"
  else
    log "  · $p (not in upstream, skipped)"
  fi
done

# Show what changed
if git diff --staged --quiet && git diff --quiet; then
  log "✓ already up to date"
  exit 0
fi

CHANGED_FILES=$(git status --porcelain .claude/ | wc -l | tr -d ' ')
log "✓ synced $CHANGED_FILES file(s) — review with: git diff --staged .claude/"
log "  commit when ready:  git commit -m 'sync: update agents/skills from upstream'"
