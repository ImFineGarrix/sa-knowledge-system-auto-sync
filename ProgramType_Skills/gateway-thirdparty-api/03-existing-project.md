# 03 — Existing Project Workflow (modify / bug fix / integration change)

Read this file when the SA chose **mode 2, 3, or 4** in [`00-spec-mode.md`](00-spec-mode.md).

Apply all global rules in [`01-rules.md`](01-rules.md) (output folder, backup, decision gate, defaults, config parameter documentation) on every section below.

For mode 2/3/4 you must **not** force the SA to start from section 01. First inspect the user's requirement and recommend which step(s) should be handled first.

## Output Order

For mode 2, 3, or 4, create one output folder per change request inside `Projects/{product}/specs/{feature}/` and generate files in this order:

1. `00-existing-project-intake.md`
2. `01-current-state-summary.md`
3. `02-change-request.md`
4. `03-impact-analysis.md`
5. `04-api-change-spec.md` — when APIs are affected.
6. `05-db-migration-impact.md` — when database or stored data is affected.
7. `06-ui-change-spec.md` — when UI is affected.
8. `07-architecture-impact.md`
9. `08-logging-monitoring-impact.md`
10. `09-regression-test-script.md`
11. `10-rollout-rollback-plan.md`
12. `12-partner-api-guide.md` — when third-party API documentation must be updated.
13. `12-postman-collection.json` — when third-party / API tests must be updated.
14. `12-partner-api-guide.html` — when third-party API documentation must be updated.
15. `11-dev-handoff-issue.md` *(always last, uses the existing-change issue template)*.

For existing project work, every changed contract must include:

- Current behavior.
- Proposed behavior.
- Compatibility decision (preserve / breaking change).
- Impacted consumers.
- Migration or rollout notes.
- Regression tests.
- Rollback approach.

## Required Flow

1. Read the user requirement and identify impacted areas.
2. Recommend the first step to work on and explain why.
3. Ask the SA to confirm, customize, or choose another step.
4. For each selected step, present default options and allow proceed / customize / skip.
5. Document current behavior **before** proposed behavior.
6. Preserve compatibility unless the SA explicitly approves a breaking change.
7. Create or update only the artifacts needed for the change.
8. Always finish with `11-dev-handoff-issue.md` for GitLab handoff.

## Routing Table — recommended first step

Use this to recommend the starting section. The SA can override.

| User Requirement | Recommended First Step | Suggested Follow-on Steps |
|---|---|---|
| Change log format | `08-logging-monitoring-impact.md` | 09 → 10 → 11 |
| Add or change API field | `04-api-change-spec.md` | 03 → Postman / regression → partner if needed → 11 |
| Add DB column or migrate data | `05-db-migration-impact.md` | API/UI if affected → 09 → 10 → 11 |
| Change screen validation | `06-ui-change-spec.md` | API if data changes → 09 → 11 |
| Change deployment / config | `07-architecture-impact.md` or `10-rollout-rollback-plan.md` | → 11 |
| Fix production bug | `02-change-request.md` | `03-impact-analysis.md` → affected sections → 11 |

For a deeper routing reference, see `template_document/existing-change/decision-guide.md`.

## Compatibility Rule

Existing project work must preserve current contracts unless the SA explicitly approves a breaking change.

If a breaking change is approved:

- Capture it in `03-impact-analysis.md` with named impacted consumers and migration plan.
- Reflect it in `04-api-change-spec.md` / `05-db-migration-impact.md` / `06-ui-change-spec.md` as applicable.
- Add regression and rollback coverage in `09-regression-test-script.md` and `10-rollout-rollback-plan.md`.
- Surface it in the final `11-dev-handoff-issue.md` as a risk.

## Templates & Quality Gate

- Existing-change template paths → [`04-templates.md`](04-templates.md).
- Pre-finalize checklist → [`05-quality-gate.md`](05-quality-gate.md).
