# 05 — Quality Gate

Read this file before finalizing each artifact, and again before producing the final `11-dev-handoff-issue.md`.

## Pre-finalize Checklist

Before declaring an artifact complete, verify:

- Every API has request, response, error, auth, and status code.
- Every UI action maps to an API or documented local behavior.
- Every API data field maps to database, external service, or derived logic.
- Every important business rule appears in requirements, API behavior, and tests.
- Every external dependency appears in architecture, sequence, logging, and risks.
- Sensitive fields are masked in logs.
- Performance numbers include assumptions.
- Third-party packages contain no secrets or internal-only data.
- Existing project changes include current behavior, proposed behavior, impact, compatibility, regression tests, rollout, and rollback.
- The handoff issue links or lists every generated artifact.

## Final Dev Handoff Issue Checklist

The final `11-dev-handoff-issue.md` must additionally include:

- Title and short summary.
- Generated artifacts list (links/paths).
- Skipped / Not Applicable Artifacts with reason for each skip.
- Assumptions (including "no reference material" when applicable).
- Acceptance criteria.
- Open questions / decisions still pending.
- Dependencies (other teams, services, schedules).
- Risks and mitigations.
- Rollout / rollback approach (existing project) or release plan (new project).

If any of the above is missing, complete it or explicitly state why it is N/A before declaring the spec ready for handoff.
