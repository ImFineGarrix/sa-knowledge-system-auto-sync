---
title: "SA Work With AI — Project Overview"
date: 2026-05-05
tags: ["#program-type-skills", "#sa", "#skills", "#ai-tooling"]
project: SA Work With AI
status: active
owner: "Zayn (ice1@freewillsolutions.com)"
---

# SA Work With AI — Project Overview

## What it is
ชุด **AI Skills** สำหรับ Systems Analyst (SA) ใช้ทำงานร่วมกับ AI (Claude) ครอบคลุมตั้งแต่การออกแบบ UI, เขียน spec backend service, ออกแบบ API, ไปจนถึงทำ Report TFS — แต่ละ skill มี trigger ในตัว AI จะเรียกใช้อัตโนมัติเมื่อ SA สั่งงาน

ไฟล์ทั้งหมดเป็น **AI-readable skills** (markdown + frontmatter `name:`/`description:`) ที่ใช้ตรงกับ Claude Code, Claude Desktop, หรือ Claude API

## Scope (4 Skill Packages)

### 1. Backend Services
**Folder:** [`Backend Services/`](./Backend%20Services/)

| Skill | Purpose |
|---|---|
| [`design-service-SKILL.md`](./Backend%20Services/design-service-SKILL.md) | `sa-designweb` — ออกแบบ responsive enterprise web mockup → handoff ให้ dev |
| [`spec-service-SKILL.md`](./Backend%20Services/spec-service-SKILL.md) | `spec-service` — เขียน Program Specification สำหรับ Java Backend Service (Post/Daemon/Import/Export) รองรับ Multi-DB |
| [`review-service-SKILL.md`](./Backend%20Services/review-service-SKILL.md) | Review service spec ก่อน handoff |
| [`test-service-SKILL.md`](./Backend%20Services/test-service-SKILL.md) | สร้าง test script สำหรับ service |

**Documentation:** [`Backend Services/document/`](./Backend%20Services/document/)
- `SA-Skill-Installation-Guide.md` — วิธีติดตั้ง skill set
- `SA-Skill-UserManual.md` — คู่มือใช้งาน
- `sa_skill_full_with_examples.svg` — diagram ภาพรวมพร้อมตัวอย่าง

### 2. Gateway / Backend API by TNH
**Folder:** [`gateway-thirdparty-api/`](./gateway-thirdparty-api/)

**Skill:** `gateway-thirdparty-api` — สร้าง **complete SA spec package** สำหรับ handoff ให้ dev

**Output flow** (1 folder ต่อ 1 project):
```
01-story.md
02-requirements.md
03-prototype.html              (ถ้ามี UI)
04-database-schema.md
05-api-spec.md
06-sequence.drawio
07-architecture.svg
08-logging-format.md
09-performance-spec.md
10-test-script.md
10-postman-collection.json     (ถ้ามี API)
11-dev-handoff-issue.md        (GitLab issue)
12-partner-api-guide.md        (ถ้าต้องแชร์ partner)
12-postman-collection.json
12-postman-environment.example.json
12-partner-api-guide.html      (optional)
```

**Skill files (modular, load on demand):**
- [`README.md`](./gateway-thirdparty-api/README.md) — skill index
- [`00-spec-mode.md`](./gateway-thirdparty-api/00-spec-mode.md) — เลือก mode + intake reference materials
- [`01-rules.md`](./gateway-thirdparty-api/01-rules.md) — global rules (output, backup, decision gate)
- [`02-new-project.md`](./gateway-thirdparty-api/02-new-project.md) — workflow mode 1 (new project)
- [`03-existing-project.md`](./gateway-thirdparty-api/03-existing-project.md) — workflow mode 2/3/4 (modify/bug fix/integration)
- [`04-templates.md`](./gateway-thirdparty-api/04-templates.md) — template path lookup
- [`05-quality-gate.md`](./gateway-thirdparty-api/05-quality-gate.md) — pre-finalize checklist

**Templates:** [`template_document/`](./gateway-thirdparty-api/template_document/) — 14 templates หลัก + 11 templates สำหรับ existing-change

**Defaults:** [`template_document/defaults/`](./gateway-thirdparty-api/template_document/defaults/) — ค่า default สำหรับ auth, architecture, logging, postman, security, technology

**Existing project changes:** [`template_document/existing-change/`](./gateway-thirdparty-api/template_document/existing-change/) — workflow + templates สำหรับแก้ระบบเดิม + decision-guide

**Reference materials (วาง vault root):**
- `reference_data/source_program/` — source code เดิมของระบบที่จะแก้ (optional)
- `reference_data/document_spec/` — spec document เดิม + spec templates (optional)

### 3. Report
**Folder:** [`Report/`](./Report/)

| File | Purpose |
|---|---|
| [`spec_report/SKILL.md`](./Report/spec_report/SKILL.md) | `spec_report` — สร้าง TFS (Technical Functional Specification) สำหรับ Report Program — ครอบคลุม xdocReport, Broker/Trading reports |
| [`spec_report/spec_report.skill`](./Report/spec_report/spec_report.skill) | Skill metadata file |
| [`tfs_report_checklist.html`](./Report/tfs_report_checklist.html) | Checklist HTML interactive |
| [`Example_TFS/TFS_RPT-TRADE-001_Daily_Trade_Report.md`](./Report/Example_TFS/TFS_RPT-TRADE-001_Daily_Trade_Report.md) | ตัวอย่าง TFS — Daily Trade Report |

### 4. SA API
**Folder:** [`SA API/`](./SA%20API/)

**Skill:** `sa-api-design` — ออกแบบ/รีวิว REST API (endpoint, schema, status code, error format, versioning, pagination, auth)

| File | Purpose |
|---|---|
| [`SKILL.md`](./SA%20API/SKILL.md) | Main skill definition |
| [`rest-guidelines.md`](./SA%20API/rest-guidelines.md) | REST best practices |
| [`request-response-patterns.md`](./SA%20API/request-response-patterns.md) | Common patterns |
| [`security-checklist.md`](./SA%20API/security-checklist.md) | Security checklist |
| [`review-checklist.md`](./SA%20API/review-checklist.md) | API review checklist |

---

## How to use these skills

### Option A — Claude Desktop / Claude.ai
1. Upload skill `.md` files to a Project in Claude.ai
2. Reference them in conversation when needed

### Option B — Claude Code
1. Copy skill `.md` files to `.claude/skills/` folder ของ project
2. Skill จะ auto-trigger ตาม description

### Option C — Reference เป็น context
- ใช้ตรงๆ เป็น reference document ใน Q&A
- Copy/paste workflow ออกมาแล้วทำตาม

## Trigger Examples (Thai/English)

| Skill | Trigger Phrases |
|---|---|
| `sa-designweb` | "ออกแบบหน้าจอ", "ทำ mockup", "wireframe", "design a screen", "admin panel" |
| `spec-service` | "เขียน spec", "ออกแบบ backend service", "TFS Spec", "/spec_service" |
| `gateway-thirdparty-api` | "SA spec", "dev handoff", "GitLab issue", "complete spec package" |
| `spec_report` | "ออก spec report", "TFS report", "/spec_report", "Daily Confirmation" |
| `sa-api-design` | "ออกแบบ API", "REST endpoint", "API spec", "review API" |

## Status & Origin
- ไฟล์ทั้งหมดเป็น **skills ที่ใช้งานจริงในทีม** (ไม่ใช่ template เปล่า)
- Imported จาก `Skill.zip` (2026-05-05)
- ใช้คู่กับงาน SA ในทีม Gold + ทีมอื่นๆ

## Related
- [[Tech/SOP/team-onboarding-claude-code]] — ทีมใหม่ดู SOP นี้ตามลำดับ
- [[Projects/gpp/scb-integration/overview]] — ตัวอย่าง project ที่ SA work ออก spec จริง
