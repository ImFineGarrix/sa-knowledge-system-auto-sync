#!/usr/bin/env bash
# bootstrap.sh — one-command setup for a new sub-team vault
# Usage:  curl -fsSL https://raw.githubusercontent.com/ZaynTRPW/sa-knowledge-system/main/bootstrap.sh | bash
#         or: ./bootstrap.sh

set -euo pipefail

cyan='\033[0;36m'; green='\033[0;32m'; yellow='\033[1;33m'; red='\033[0;31m'; nc='\033[0m'
step() { echo -e "\n${cyan}→ $1${nc}"; }
ok()   { echo -e "${green}✓ $1${nc}"; }
warn() { echo -e "${yellow}! $1${nc}"; }
err()  { echo -e "${red}✗ $1${nc}"; }

echo -e "${cyan}=========================================${nc}"
echo -e "${cyan}  SA Knowledge System · Bootstrap${nc}"
echo -e "${cyan}=========================================${nc}"

# ---------- Prerequisites ----------
step "Checking prerequisites"
command -v git >/dev/null  || { err "git not installed"; exit 1; }
ok "git found"
command -v node >/dev/null || { err "Node.js 18+ required"; exit 1; }
NODE_VER=$(node --version | sed 's/v//' | cut -d. -f1)
[ "$NODE_VER" -ge 18 ] || { err "Node.js 18+ required (you have v$NODE_VER)"; exit 1; }
ok "node v$NODE_VER found"

if ! command -v claude >/dev/null; then
    warn "Claude Code not installed. Installing now..."
    npm install -g @anthropic-ai/claude-code
    ok "Claude Code installed"
else
    ok "Claude Code found"
fi

# ---------- Inputs ----------
step "Vault configuration"
read -p "Team name (e.g. ICE): "                        TEAM
read -p "Sub-team name (e.g. Gold, Silver, Bronze): "    SUB
read -p "Owner name + email (e.g. Zayn (zayn@co.com)): " OWNER
read -p "Products comma-separated [optional]: "          PRODUCTS

VAULT="${TEAM}-${SUB}"
[ -d "$VAULT" ] && { err "Folder '$VAULT' already exists"; exit 1; }

# ---------- Clone ----------
step "Cloning template into $VAULT"
git clone --quiet https://github.com/ZaynTRPW/sa-knowledge-system.git "$VAULT"
cd "$VAULT"

# ---------- Strip template-only artifacts ----------
step "Cleaning template-only artifacts"
rm -rf docs overrides mkdocs.yml requirements-docs.txt bootstrap.sh bootstrap.ps1
# Keep .github/workflows/sync-skills.yml — remove only the docs deploy workflow
rm -f .github/workflows/deploy.yml
ok "Removed presentation site (only relevant for upstream)"
ok "Kept .github/workflows/sync-skills.yml for auto-sync from upstream"

# ---------- Make scripts executable ----------
chmod +x scripts/sync-skills.sh scripts/session-start-pull.sh 2>/dev/null || true

# ---------- Personalise ----------
step "Personalising vault for $VAULT"
cat > README.md <<EOF
# $VAULT Knowledge Base

> SA knowledge base for **$SUB** sub-team (under **$TEAM** team).
> Forked from [sa-knowledge-system](https://github.com/ZaynTRPW/sa-knowledge-system).

Owner: $OWNER

## Quick start

\`\`\`bash
claude
> Use the session-logger agent: read at session start
\`\`\`

See \`Tech/SOP/how-to-use-vault.md\` for full daily workflows.

## Sync template updates

\`\`\`bash
git remote add upstream https://github.com/ZaynTRPW/sa-knowledge-system.git
git fetch upstream
git merge upstream/main
\`\`\`
EOF

# ---------- Product placeholders ----------
if [ -n "$PRODUCTS" ]; then
    step "Creating product placeholders"
    IFS=',' read -ra ARR <<< "$PRODUCTS"
    for p in "${ARR[@]}"; do
        p=$(echo "$p" | xargs)
        [ -z "$p" ] && continue
        mkdir -p "Projects/$p"
        cat > "Projects/$p/overview.md" <<EOF
# $p

> Placeholder for $p product. Replace with real overview.
EOF
        ok "  Projects/$p/"
    done
fi

# ---------- Ensure required directories exist ----------
step "Creating required directories"
mkdir -p Memory Memory/sessions Projects/_meta .index
mkdir -p reference_data/db_schema reference_data/dev_wiki reference_data/document_spec reference_data/source_program
ok "Memory/, Projects/_meta/, .index/, reference_data/ ready"

# ---------- Seed Memory + ADR ----------
step "Seeding Memory + ADR log"
cat > Memory/summary.md <<EOF
# Memory summary

> Rolling context across sessions for $VAULT.

No sessions logged yet. Run \`Use session-logger: log this session\` after first work session.
EOF

cat > Projects/_meta/architecture-decisions.md <<EOF
# Architecture Decisions Log — $VAULT

> Owner: $OWNER

## Quick Status

_(no ADRs yet — first entry will be added here by \`decision-keeper\`)_
EOF

# ---------- Fresh git ----------
step "Resetting git history"
rm -rf .git
git init --quiet
git add -A
git -c user.email="$OWNER" -c user.name="$OWNER" commit --quiet -m "init: bootstrap $VAULT from sa-knowledge-system"
git branch -M main
git remote add upstream https://github.com/ZaynTRPW/sa-knowledge-system.git
ok "Fresh git repo initialised on branch main"
ok "upstream remote set (for skill auto-sync)"

# ---------- Done ----------
echo -e "\n${green}=========================================${nc}"
echo -e "${green}  ✓ $VAULT is ready${nc}"
echo -e "${green}=========================================${nc}\n"
echo "Next steps:"
echo "  cd $VAULT"
echo "  claude"
echo "  > Use the kb-assistant agent: what products does this vault track?"
echo ""
echo "Push to GitHub:"
echo "  gh repo create <org>/$VAULT --private --source=. --remote=origin --push"
echo ""
echo "Skill auto-sync (already wired):"
echo "  · GitHub Action runs daily at 07:30 ICT — pulls .claude/agents + skills from upstream"
echo "  · Claude session-start hook auto-pulls origin (throttled to 6h)"
echo "  · Manual sync anytime:  ./scripts/sync-skills.sh"
echo ""
