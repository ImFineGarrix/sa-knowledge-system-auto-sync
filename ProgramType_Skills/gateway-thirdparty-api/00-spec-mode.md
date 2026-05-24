# 00 — Spec Mode + Reference Materials Intake

Read this file at the start of every conversation, before generating any artifact.

## Spec Mode Rule

Before creating any artifact, ask the SA to choose the work mode:

```text
Spec mode:
1. New project / new API
2. Existing project change
3. Existing project bug fix
4. Existing project integration change
```

- Mode 1 → use [`02-new-project.md`](02-new-project.md).
- Mode 2, 3, or 4 → use [`03-existing-project.md`](03-existing-project.md). Existing project work must start by understanding the current state before proposing changes.

If the SA gives a general instruction such as "create spec" or "build the spec" without specifying which sections, do not generate all sections at once. Ask which sections to start with first, list available sections for the chosen mode, and wait for confirmation before generating anything.

## Reference Material Intake Rule

Before generating any artifact (both new and existing project mode), check whether the SA has reference materials in two dedicated folders at the project root:

- `reference_data/source_program/` — existing source program / code for reference.
- `reference_data/document_spec/` — existing spec / design documents for reference.

Always ask the SA:

```text
Reference materials:
1. มี source program เดิมให้อ้างอิงหรือไม่? (วางไว้ใน reference_data/source_program/) — ถ้าเป็นงานออกแบบใหม่จะไม่มี ถ้าเป็นงานแก้/revise ของเดิมอาจมี
2. มี spec document เดิมให้อ้างอิงหรือไม่? (วางไว้ใน reference_data/document_spec/) — ถ้าเป็นงานออกแบบใหม่จะไม่มี ถ้าเป็นงานแก้/revise ของเดิมอาจมี
```

If the SA confirms reference material is present:

- List the files under `reference_data/source_program/` and/or `reference_data/document_spec/` before reading.
- Read the relevant files first and treat them as the source of truth for current behavior.
- Cite the referenced files explicitly in the generated artifacts (e.g., `Reference: reference_data/source_program/auth/login.cs`).
- Do not redesign from scratch when reference material exists unless the SA explicitly asks for replacement / rebuild.

If the SA confirms no reference material, proceed as a new design and record this in `11-dev-handoff-issue.md` under "Assumptions".

For existing project work (mode 2, 3, 4), additionally ask for available current artifacts not covered by the two folders:

- Existing database schema or migration history.
- Existing Postman collection.
- Existing UI screenshots or prototype.
- Existing logs or monitoring examples.
- Current production/UAT behavior.
- Known partner consumers or downstream systems.

Do not redesign an existing project from scratch unless the SA explicitly asks for replacement / rebuild.

## Project Name Rule

If the SA does not specify a project name, ask for it before creating any file. Use a short, lowercase, hyphen-separated name (e.g., `nexus-partner-api`, `loyalty-reward-service`). All output goes under `Projects/{product}/specs/{feature}/`.

## Next Steps

After spec mode and reference intake are settled:

1. Load [`01-rules.md`](01-rules.md) for the global rules that apply to every section (output folder, backup, decision gate, defaults, config parameter documentation).
2. Load the workflow file for the chosen mode ([`02-new-project.md`](02-new-project.md) or [`03-existing-project.md`](03-existing-project.md)).
