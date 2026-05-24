# Existing Project Decision Guide

Use this guide for existing project change, bug fix, or integration change mode.

## 00 Existing Project Intake

Default: Capture project name, repository/spec references, environments, owners, current version, and reason for change.

Ask whether the SA has source code, current spec, API spec, Postman collection, DB schema, UI screenshots, logs/monitoring examples, or known incidents.

## 01 Current State Summary

Default: Summarize current behavior, architecture, APIs, DB, UI, integrations, and constraints.

Ask whether the summary should be high-level, technical by component, or contract-focused for API/partner impact.

## 02 Change Request

Default: Define requested change, business reason, target users, scope, non-goals, assumptions, acceptance criteria, and priority.

Ask whether this is enhancement, bug fix, integration change, performance/security change, or refactor with no functional change.

## 03 Impact Analysis

Default: Analyze impact across API, UI, DB, architecture, logging, security, performance, tests, deployment, partner systems, and operations.

Ask whether the SA wants a standard impact matrix, deep technical impact by module, or release/operation focused impact.

## 04 API Change Spec

Default: Document before/after API behavior, compatibility, versioning, request/response changes, error changes, auth/header changes, and Postman changes.

Ask whether APIs are affected. If no, skip. If yes, ask whether the change is backward compatible, breaking/versioned, partner-only, or internal-only.

## 05 DB Migration Impact

Default: Document current schema, proposed schema, migration notes, data backfill, rollback, data risk, and retention impact.

Ask whether database or persistent data is affected. If no, skip. If yes, ask whether the change is new table/field, type/length change, index/performance change, data migration/backfill, or data deletion/retention change.

## 06 UI Change Spec

Default: Document current screen behavior, proposed behavior, fields/actions/states, validation changes, and screenshot/prototype references.

Ask whether UI is affected. If no, skip. If yes, ask whether the SA wants text-only spec, updated HTML prototype, or screen-by-screen before/after table.

## 07 Architecture Impact

Default: Document component impact, integration impact, deployment impact, config/env impact, dependency changes, and source module/package impact.

Ask whether the architecture impact depth is component only, container/deployment, or source module/package.

## 08 Logging / Monitoring Impact

Default: Document changed log events, new/removed fields, trace/correlation behavior, alert/monitoring changes, and sensitive data logging risk.

Ask whether logging or monitoring is affected. If no, skip.

## 09 Regression Test Script

Default: Create regression tests for unchanged behavior plus tests for new/changed behavior.

Ask whether to include smoke regression, API regression with Postman, UI regression, DB migration verification, or partner integration regression.

## 10 Rollout / Rollback Plan

Default: Create deployment steps, feature flag decision, migration order, validation steps, rollback trigger, rollback steps, and communication plan.

Ask whether rollout needs standard deployment, blue/green or canary, feature flag, data migration window, or partner coordination.

## 11 Dev Change Handoff Issue

Default: Create GitLab-ready change issue summarizing current state, requested change, impact, artifacts, compatibility decisions, rollout/rollback, tests, and open questions.

Ask whether the issue should be one change issue, epic plus sub-issues, or split by frontend/backend/database/integration/infra.

