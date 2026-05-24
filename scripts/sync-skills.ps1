# sync-skills.ps1 — manually pull latest agents + skills from upstream
# Usage:  .\scripts\sync-skills.ps1 [-Quiet]
#
# Safe: only touches .claude/agents/, .claude/skills/, and ProgramType_Skills/.
# Your Memory/, Projects/, reference_data/, Tech/, MOC/, Templates/ are NEVER modified.

[CmdletBinding()]
param([switch]$Quiet)

$ErrorActionPreference = "Stop"

$UpstreamUrl    = if ($env:UPSTREAM_URL)    { $env:UPSTREAM_URL }    else { "https://github.com/ZaynTRPW/sa-knowledge-system.git" }
$UpstreamBranch = if ($env:UPSTREAM_BRANCH) { $env:UPSTREAM_BRANCH } else { "main" }
$SyncPaths      = @(".claude/agents", ".claude/skills", "ProgramType_Skills")

function Log($msg) { if (-not $Quiet) { Write-Host $msg } }

# Ensure we're inside a git repo
$null = git rev-parse --is-inside-work-tree 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Error "not a git repository"
    exit 1
}

# Ensure upstream remote exists
$null = git remote get-url upstream 2>$null
if ($LASTEXITCODE -ne 0) {
    Log "→ adding upstream remote"
    git remote add upstream $UpstreamUrl | Out-Null
}

Log "→ fetching upstream/$UpstreamBranch"
git fetch --quiet upstream $UpstreamBranch

foreach ($p in $SyncPaths) {
    $null = git cat-file -e "upstream/$UpstreamBranch`:$p" 2>$null
    if ($LASTEXITCODE -eq 0) {
        git checkout --quiet "upstream/$UpstreamBranch" -- $p 2>$null
        $count = (git ls-files $p 2>$null | Measure-Object).Count
        Log "  ✓ $p ($count files)"
    } else {
        Log "  · $p (not in upstream, skipped)"
    }
}

# Check for changes
$staged   = git diff --staged --name-only
$unstaged = git diff --name-only
if (-not $staged -and -not $unstaged) {
    Log "✓ already up to date"
    exit 0
}

$changed = (git status --porcelain .claude/ | Measure-Object).Count
Log "✓ synced $changed file(s) — review with: git diff --staged .claude/"
Log "  commit when ready:  git commit -m 'sync: update agents/skills from upstream'"
