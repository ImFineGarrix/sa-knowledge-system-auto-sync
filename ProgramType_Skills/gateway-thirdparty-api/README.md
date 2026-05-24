---
name: gateway-thirdparty-api
description: Modular skill for guiding a System Analyst through creating a complete specification package for development team handoff. Supports new project specs and existing project change specs. Each rule lives in its own file under skills/ so Claude loads only what it needs per section.
---

# SA Spec Dev Handoff — Skill Index

This folder replaces the single `SKILL.md`. Each file is loaded on demand. Claude reads only the files relevant to the current step.

## Reading Order

Always read [`00-spec-mode.md`](00-spec-mode.md) first. Then load the workflow file matching the SA's chosen mode, and pull in others only when needed for the active section.

| File | When to read |
|---|---|
| [`00-spec-mode.md`](00-spec-mode.md) | At start of every conversation — choose spec mode + intake reference materials. |
| [`01-rules.md`](01-rules.md) | Before writing any output file — output folder rule, overwrite/backup rule, decision gate, organization defaults, config parameter documentation rule. |
| [`02-new-project.md`](02-new-project.md) | When SA chooses mode 1 (new project / new API). Contains output order + section-by-section decision guide. |
| [`03-existing-project.md`](03-existing-project.md) | When SA chooses mode 2, 3, or 4 (modify / bug fix / integration change). Contains routing table + output order + existing project rules. |
| [`04-templates.md`](04-templates.md) | When you need the path to a starting template under `template_document/`. |
| [`05-quality-gate.md`](05-quality-gate.md) | Before finalizing each artifact and before the final dev handoff issue. |

## Core 5 Rules (always apply)

1. **No Magic** — explain the logic behind every complex step. No black-box solutions.
2. **Verify Before Done** — double-check output for accuracy and logical consistency before finalizing.
3. **Dissent** — challenge inefficient or incorrect instructions and suggest a better alternative.
4. **Scope Drift** — stay strictly within the defined scope. Notify SA before exploring side tasks.
5. **Explicit Assumptions** — clearly state any assumption made when information is missing or ambiguous.

## Folder Map (vault-adapted)

```text
ProgramType_Skills/gateway-thirdparty-api/   ← this skill (modular rules + templates)
  00-spec-mode.md … 05-quality-gate.md             ← skill files (read on demand)
  template_document/                               ← starting templates + organization defaults
    defaults/                                      ← organization defaults (auth, logging, etc.)
    existing-change/                               ← templates for existing project change mode
Projects/<product>/specs/<feature>/                ← generated spec packages live here (one folder per feature)
  _backup/                                         ← backups of overwritten files (created on demand)
reference_data/source_program/                     ← SA-provided existing source program (optional)
reference_data/document_spec/                  ← SA-provided existing spec documents (optional)
```

> **Vault-adapted paths:** This skill was designed standalone but lives inside the SA Knowledge System vault. Output, templates, and reference materials use vault conventions (`Projects/`, `reference_data/`) instead of the standalone layout (`sa_output_spec/`, root-level `source_program/`).
