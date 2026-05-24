# 02 — New Project Workflow

Read this file when the SA chose **mode 1 — new project / new API** in [`00-spec-mode.md`](00-spec-mode.md).

Apply all global rules in [`01-rules.md`](01-rules.md) (output folder, backup, decision gate, defaults, config parameter documentation) on every section below.

## Output Order

Generate files in this order inside `Projects/{product}/specs/{feature}/`:

1. `01-story.md`
2. `02-requirements.md`
3. `03-prototype.html` — when the system has UI.
4. `04-database-schema.md`
5. `05-api-spec.md`
6. `06-sequence.drawio`
7. `07-architecture.svg`
8. `08-logging-format.md`
9. `09-performance-spec.md`
10. `10-test-script.md`
11. `10-postman-collection.json` — when APIs exist.
12. `12-partner-api-guide.md` — when APIs must be shared with a third party.
13. `12-postman-collection.json` — when APIs must be shared with a third party.
14. `12-postman-environment.example.json` — when APIs must be shared with a third party.
15. `12-partner-api-guide.html` — when APIs must be shared with a third party.
16. `11-dev-handoff-issue.md` *(always last)*.

## High-Level Workflow

Work step by step from 1 to 12. Before each section, offer the default template/options and let the SA proceed, customize, skip, or specify another approach (see decision gate in [`01-rules.md`](01-rules.md)).

1. Start with business context and stakeholders.
2. Convert the story into functional scope, rules, assumptions, and out-of-scope items.
3. If UI exists, draft the screen flow and simple clickable prototype.
4. Define database entities, fields, relationships, and data dictionary.
5. Define API contracts based on UI actions and data model.
6. Create sequence diagrams for key use cases and integration/error flows.
7. Propose architecture after the main functional and data contracts are visible.
8. Define logging after API, sequence, and architecture are known.
9. Define throughput and performance targets from usage assumptions.
10. Prepare test scripts and Postman collection from the finished contracts.
11. If the API will be consumed by a third party, prepare the partner API package.
12. Create the GitLab-ready dev handoff issue last.

## Section Decision Guide

For each section, offer the default and a small set of common variants. Always allow Customize / Skip / Specify another approach.

### 01 Story / Business Context

Default: create project story, background, stakeholders, scope, assumptions, success criteria.

Ask whether the SA wants:

- Standard business story format.
- More formal BRD-style format.
- Short executive summary format.

### 02 Functional Scope & Requirement Summary

Default: feature list, use cases, business rules, permission rules, validation rules, integration requirements, open questions.

Ask whether the SA wants:

- Standard functional requirement format.
- User story + acceptance criteria format.
- Use-case heavy format.

### 03 Screen UI + Prototype

Default: simple HTML + JavaScript prototype.

Ask whether the system has UI. If there is no UI, skip this section.

Ask whether the SA wants:

- Simple wireframe prototype.
- Form and table prototype.
- Dashboard / workflow prototype.
- Skip because this is API / backend / batch only.

### 04 Database Schema

Default: database schema, data dictionary, indexes, relationships, ER diagram.

Ask whether the system owns a database or persistent data store. If there is no database, skip this section and record the reason.

Ask whether the SA wants:

- Relational database schema.
- NoSQL document structure.
- Existing database mapping only.
- External-system data mapping only.

### 05 API Specification

Default: REST API spec with bearer token authentication unless the SA chooses another method.

Ask whether APIs exist. If not, skip.

Ask the SA to choose authentication style:

- Bearer token / JWT.
- X-API-Key.
- OAuth2.
- Session cookie.
- Mutual TLS.
- Internal network only.
- Custom.

Ask whether the SA wants:

- REST API.
- GraphQL.
- Webhook.
- File-based interface.
- Message queue / event contract.

**Every API endpoint must include one complete end-to-end example showing:**

- Full HTTP request: method, URL with path/query parameters, all headers (auth, correlation, timestamp), and request body with realistic sample values.
- Full HTTP response: HTTP status code, response headers, response body with realistic sample values.

Do not use placeholder values such as `"string"` or `<value>`. Use realistic but non-sensitive sample data.

API spec writing style: concise and complete. Write the minimum a developer needs to implement without follow-up questions. Avoid restatements and obvious comments. Every field must have a name, type, required/optional flag, and a short description. Do not pad with filler prose.

### 06 Sequence Diagram

Default: draw.io XML sequence diagram for key success, alternative, and error flows.

Ask whether the SA wants sequence diagrams for:

- Main happy path only.
- Happy path + error paths.
- Integration-heavy flows.
- Authentication / authorization flow.

### 07 Architecture Diagram

Default: proposed system architecture for dev review, not final locked architecture.

Ask architecture depth:

- Level 1: system context only.
- Level 2: container / component architecture.
- Level 3: deployment architecture.
- Level 4: source-code blueprint including package/module boundaries.

If the SA chooses Level 4, include suggested source code folders, module responsibilities, interface boundaries, config structure, and dependency direction. Mark it as proposed blueprint for dev review.

### 08 Logging Format

Default: structured JSON logging with request id, user id, event name, level, service, environment, masked sensitive data.

Ask whether logs are needed for:

- Troubleshooting only.
- Audit trail.
- Security monitoring.
- Regulatory / compliance.

### 09 Throughput & Performance Spec

Default: throughput and latency assumptions using TPS, concurrent users, response time, timeout, SLA/SLO, test scope.

Ask whether the SA has real usage numbers. If not, create assumptions and mark them as assumptions.

Ask whether performance should cover:

- API response time.
- Batch processing time.
- UI page load.
- Report generation.
- Integration throughput.

### 10 Test Script & Postman Collection

Default: functional test script and Postman collection when APIs exist.

Ask whether the SA wants:

- Basic smoke test only.
- Functional test script.
- API test script with Postman.
- Permission / security test cases.
- Integration test cases.

If no APIs exist, skip Postman collection.

### 12 Third-Party API Package

Default: lightweight partner package without OpenAPI.

Ask whether this API must be shared with a third party. If not, skip this section.

Default output:

- `12-partner-api-guide.md`
- `12-postman-collection.json`
- `12-postman-environment.example.json`

Optional output:

- `12-partner-api-guide.html`

Ask whether the SA wants:

- Default partner package only.
- Add optional HTML guide.
- Customize authentication / integration instructions.
- Skip because the API is internal only.

The partner guide must include:

- API overview.
- Environment / base URL.
- Authentication method.
- Required headers.
- Endpoint list.
- Request / response examples.
- Error code table.
- Rate limit or usage constraints.
- Retry and timeout guidance.
- Webhook / callback behavior, if any.
- UAT checklist.
- Support / contact channel.
- Changelog / version.

The Postman collection must be safe to share externally. Do not include real secrets, production tokens, private credentials, internal-only URLs, or sensitive sample personal data.

### 11 Final Dev Handoff Issue

Default: `11-dev-handoff-issue.md` as the final GitLab-ready issue summarizing all generated artifacts, skipped artifacts, acceptance criteria, open questions, dependencies, risks.

Ask whether the issue should be:

- One main issue.
- Epic + sub-issues.
- Frontend / backend split.
- API / database / integration split.

Create this **after** the third-party API package decision, so partner artifacts and skipped reasons are included.

## Templates & Quality Gate

- Template paths for each section → [`04-templates.md`](04-templates.md).
- Pre-finalize checklist → [`05-quality-gate.md`](05-quality-gate.md).
