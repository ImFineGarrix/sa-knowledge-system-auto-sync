# bootstrap.ps1 — one-command setup for a new sub-team vault
# Usage:  irm https://raw.githubusercontent.com/ZaynTRPW/sa-knowledge-system/main/bootstrap.ps1 | iex
#         or: .\bootstrap.ps1

$ErrorActionPreference = "Stop"

function Write-Step($msg) { Write-Host "`n→ $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "✓ $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "! $msg" -ForegroundColor Yellow }
function Write-Err($msg)  { Write-Host "✗ $msg" -ForegroundColor Red }

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "  SA Knowledge System · Bootstrap" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# ---------- Prerequisites ----------
Write-Step "Checking prerequisites"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Err "git is not installed. Get it from https://git-scm.com/download/win"
    exit 1
}
Write-Ok "git found"

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Err "Node.js 18+ is required. Get it from https://nodejs.org"
    exit 1
}
$nodeVer = (node --version).TrimStart('v').Split('.')[0]
if ([int]$nodeVer -lt 18) {
    Write-Err "Node.js 18+ required (you have v$nodeVer)"
    exit 1
}
Write-Ok "node v$nodeVer found"

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Warn "Claude Code not installed. Installing now..."
    npm install -g "@anthropic-ai/claude-code"
    Write-Ok "Claude Code installed"
} else {
    Write-Ok "Claude Code found"
}

# ---------- Collect inputs ----------
Write-Step "Vault configuration"

$teamName = Read-Host "Team name (e.g. ICE)"
$subName  = Read-Host "Sub-team name (e.g. Gold, Silver, Bronze)"
$owner    = Read-Host "Owner name + email (e.g. Zayn (zayn@company.com))"
$products = Read-Host "Products comma-separated (e.g. ProductA,ProductB) [optional, press Enter to skip]"

$vaultName = "$teamName-$subName"
$vaultPath = Join-Path (Get-Location) $vaultName

if (Test-Path $vaultPath) {
    Write-Err "Folder '$vaultName' already exists at $vaultPath"
    exit 1
}

# ---------- Clone ----------
Write-Step "Cloning template into $vaultName"
git clone --quiet https://github.com/ZaynTRPW/sa-knowledge-system.git $vaultName
Set-Location $vaultPath

# ---------- Strip template-only artifacts (presentation site) ----------
Write-Step "Cleaning template-only artifacts"
Remove-Item -Recurse -Force docs, overrides, mkdocs.yml, requirements-docs.txt, bootstrap.ps1, bootstrap.sh -ErrorAction SilentlyContinue
# Keep .github/workflows/sync-skills.yml — remove only the docs deploy workflow
Remove-Item -Force .github/workflows/deploy.yml -ErrorAction SilentlyContinue
Write-Ok "Removed presentation site (only relevant for upstream)"
Write-Ok "Kept .github/workflows/sync-skills.yml for auto-sync from upstream"

# ---------- Rewrite README + CLAUDE.md placeholders ----------
Write-Step "Personalising vault for $vaultName"

$readmeContent = @"
# $vaultName Knowledge Base

> SA knowledge base for **$subName** sub-team (under **$teamName** team).
> Forked from [sa-knowledge-system](https://github.com/ZaynTRPW/sa-knowledge-system).

Owner: $owner

## Quick start

``````bash
claude
> Use the session-logger agent: read at session start
``````

See ``Tech/SOP/how-to-use-vault.md`` for full daily workflows.

## Sync template updates

``````bash
git remote add upstream https://github.com/ZaynTRPW/sa-knowledge-system.git
git fetch upstream
git merge upstream/main
``````
"@
$readmeContent | Set-Content -Path README.md -Encoding UTF8

# ---------- Generate product placeholder folders ----------
if ($products) {
    Write-Step "Creating product placeholders"
    $products.Split(',') | ForEach-Object {
        $p = $_.Trim()
        if ($p) {
            New-Item -ItemType Directory -Path "Projects/$p" -Force | Out-Null
            "# $p`n`n> Placeholder for $p product. Replace with real overview." | Set-Content -Path "Projects/$p/overview.md" -Encoding UTF8
            Write-Ok "  Projects/$p/"
        }
    }
}

# ---------- Ensure required directories exist ----------
Write-Step "Creating required directories"
New-Item -ItemType Directory -Path "Memory" -Force | Out-Null
New-Item -ItemType Directory -Path "Memory/sessions" -Force | Out-Null
New-Item -ItemType Directory -Path "Projects/_meta" -Force | Out-Null
New-Item -ItemType Directory -Path ".index" -Force | Out-Null
New-Item -ItemType Directory -Path "reference_data/db_schema" -Force | Out-Null
New-Item -ItemType Directory -Path "reference_data/dev_wiki" -Force | Out-Null
New-Item -ItemType Directory -Path "reference_data/document_spec" -Force | Out-Null
New-Item -ItemType Directory -Path "reference_data/source_program" -Force | Out-Null
Write-Ok "Memory/, Projects/_meta/, .index/, reference_data/ ready"

# ---------- Seed Memory ----------
Write-Step "Seeding Memory"
"# Memory summary`n`n> Rolling context across sessions for $vaultName.`n`nNo sessions logged yet. Run ``Use session-logger: log this session`` after first work session." | Set-Content -Path Memory/summary.md -Encoding UTF8

# ---------- Seed ADR log ----------
"# Architecture Decisions Log — $vaultName`n`n> Owner: $owner`n`n## Quick Status`n`n_(no ADRs yet — first entry will be added here by ``decision-keeper``)_" | Set-Content -Path Projects/_meta/architecture-decisions.md -Encoding UTF8

# ---------- Init fresh git ----------
Write-Step "Resetting git history for your team"
Remove-Item -Recurse -Force .git
git init --quiet
git add -A
git -c user.email="$owner" -c user.name="$owner" commit --quiet -m "init: bootstrap $vaultName from sa-knowledge-system"
git branch -M main
git remote add upstream https://github.com/ZaynTRPW/sa-knowledge-system.git
Write-Ok "Fresh git repo initialised on branch main"
Write-Ok "upstream remote set (for skill auto-sync)"

# ---------- Done ----------
Write-Host "`n=========================================" -ForegroundColor Green
Write-Host "  ✓ $vaultName is ready" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
Write-Host "  cd $vaultName"
Write-Host "  claude"
Write-Host "  > Use the kb-assistant agent: what products does this vault track?"
Write-Host ""
Write-Host "Push to GitHub:" -ForegroundColor White
Write-Host "  gh repo create <org>/$vaultName --private --source=. --remote=origin --push"
Write-Host ""
Write-Host "Skill auto-sync (already wired):" -ForegroundColor White
Write-Host "  - GitHub Action runs daily at 07:30 ICT — pulls .claude/agents + skills from upstream"
Write-Host "  - Claude session-start hook auto-pulls origin (throttled to 6h)"
Write-Host "  - Manual sync anytime:  .\scripts\sync-skills.ps1"
Write-Host ""
