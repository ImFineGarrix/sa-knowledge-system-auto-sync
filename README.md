# SA Knowledge System

> A clone-and-use Obsidian knowledge base for SA teams.
> 15 AI agents · 13 skills · Context7 MCP · Memory system · per-sub-team forking.

Built for Solution Architects who want a second brain that survives team turnover, ships specs faster, and never forgets context.

[![Live demo](https://img.shields.io/badge/Live_demo-zayntrpw.github.io%2Fsa--knowledge--system-d4a24a?style=for-the-badge)](https://zayntrpw.github.io/sa-knowledge-system/)

---

## Bootstrap a new sub-team vault in one command

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/ZaynTRPW/sa-knowledge-system/main/bootstrap.ps1 | iex
```

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/ZaynTRPW/sa-knowledge-system/main/bootstrap.sh | bash
```

The script will:

1. Check prerequisites (git, Node 18+, Claude Code — installs Claude Code if missing)
2. Ask for your team / sub-team / owner / products
3. Clone this template, strip presentation-site artifacts
4. Generate a fresh `<TEAM>-<SUB>` folder
5. Seed `Memory/`, ADR log, product placeholders
6. Reset git history so it's truly yours
7. Print next steps

Time from prompt to working vault: about 60 seconds.

---

## What you get

| Layer | What | Where |
|---|---|---|
| Agents | 15 specialised AI workers | `.claude/agents/` |
| Skills | 13 production skills (PDF, DOCX, XLSX, design, Obsidian-native) | `.claude/skills/` |
| MCP | Context7 wired in (no hallucinated APIs) | `.mcp.json` |
| Memory | ADR log + session logs + rolling summary | `Memory/`, `Projects/_meta/` |
| SA skills | UI / Backend / API / Report skill sources | `ProgramType_Skills/` |
| SOPs | Onboarding, daily workflow, sync | `Tech/SOP/` |
| Templates | ADR, SOP, product overview, session log, spec | `Templates/` |

---

## The 15 agents

```text
Spec workflow (8)        Memory (2)             Supporting (3)         Meta (2)
─────────────────        ──────────             ──────────────         ────────
spec-writer (router)     decision-keeper        kb-assistant           skill-to-agent
spec-ui-designer         session-logger         indexer                doc-to-vault
spec-backend-service                            db-schema-documenter
spec-api-designer
spec-report-designer
spec-tester
spec-reviewer
gateway-thirdparty-api
```

Full descriptions + sample prompts: [live site](https://zayntrpw.github.io/sa-knowledge-system/agents/) or `Tech/SOP/how-to-use-vault.md`

---

## Why each sub-team needs its own vault

This template is meant to be forked per sub-team, never shared between sub-teams.

```text
Organization
└─ Team (e.g. ICE)
   ├─ Sub-team Gold   → vault: ICE-Gold
   ├─ Sub-team Alpha → vault: NXT-Alpha
   └─ Sub-team Bronze → vault: ICE-Bronze
```

Reasons:

- Scope — each sub-team has different products
- Memory — session logs and ADRs are sub-team specific
- Ownership — GitHub permissions track the vault
- Sync independence — Gold can move faster than Silver without blocking
- Bloat control — a vault grows to thousands of notes; mixing sub-teams compounds this

---

## Manual setup (if you don't want the bootstrap script)

```bash
git clone https://github.com/ZaynTRPW/sa-knowledge-system.git <TEAM>-<SUB>
cd <TEAM>-<SUB>
rm -rf docs overrides mkdocs.yml requirements-docs.txt .github
rm -rf .git
git init
git add -A
git commit -m "init: bootstrap"
git remote add upstream https://github.com/ZaynTRPW/sa-knowledge-system.git
claude
```

Then in Claude Code:

```text
> Use the session-logger agent: read at session start
```

---

## Sync template updates into your sub-team vault

```bash
cd <TEAM>-<SUB>
git fetch upstream
git merge upstream/main
git push origin main
```

Conflicts are rare — template only touches `.claude/`, `Tech/SOP/`, `Templates/`

Details in `Tech/SOP/sync-from-template.md`

---

## Extend with your own agents

Every SA has personal prompts/checklists they use daily. Convert them into proper team agents:

```text
> Use the skill-to-agent agent: convert ~/my-prompts/release-notes.md
```

The `skill-to-agent` agent will:

1. Read your source
2. Ask back (in one batch) for any missing fields — name, trigger, inputs, output, guardrails
3. Show a preview
4. Write the agent to `.claude/agents/<name>.md` only after you confirm

---

## Folder structure

```text
.
├── CLAUDE.md                       ← vault rules (read by every agent)
├── README.md                       ← this file
├── bootstrap.ps1 / bootstrap.sh    ← one-command setup for new sub-teams
├── .claude/agents/                 ← 15 agents
├── .claude/skills/                 ← 13 skills
├── .mcp.json                       ← Context7 MCP
├── Memory/                         ← session log + rolling summary
├── Projects/
│   ├── _meta/                      ← ADR log
│   └── <PRODUCT>/                  ← your real specs go here
├── ProgramType_Skills/             ← SA skill source-of-truth (auto-synced from upstream)
├── reference_data/                 ← team reference data
│   ├── db_schema/
│   ├── dev_wiki/
│   ├── document_spec/
│   └── source_program/
├── Tech/SOP/                       ← daily workflow + onboarding
├── Templates/                      ← note templates
├── MOC/                            ← human-curated maps of content
│
└── (upstream only — strip when forking)
    ├── docs/                       ← presentation site source
    ├── overrides/                  ← MkDocs theme
    ├── mkdocs.yml
    ├── requirements-docs.txt
    └── .github/                    ← Pages deploy workflow
```

---

## The presentation site

The live site at https://zayntrpw.github.io/sa-knowledge-system/ is for introducing the system to new teams — not a daily reference. Daily work happens inside your forked vault with Claude Code.

The site is intentionally separated from vault content so:

- Sub-team forks don't have to carry the presentation
- Marketing/copy can iterate without touching shared core
- Other teams can preview the system before adopting

---

## Contribute

Found a workflow we should automate? Open an issue or PR — it'll be logged as a candidate ADR.

---

## License

Internal organisational use.
