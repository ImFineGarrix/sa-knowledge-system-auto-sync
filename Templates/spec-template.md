---
title: ""
date: 2026-05-06
tags: [spec, "#projects/<product>"]
status: draft           # draft | review | approved | dev-handed-off | done
owner: ""
agent_used: ""          # spec-writer | spec-backend-service | spec-ui-designer | etc.
product: ""             # GOLDPORTPLUS | SBA | IFIS | ...
ticket: ""              # GitLab/Jira ID e.g. #296
---

# {{Spec Title}}

## Story
> เป็น **<role>** ฉันต้องการ **<feature>** เพื่อ **<benefit>**

## Context
- ทำไมต้องทำ — pain / opportunity
- เกี่ยวข้องกับระบบ/feature ใดบ้าง
- Related specs: [[link]]

## Scope

### In scope
- สิ่งที่ทำใน spec นี้

### Out of scope
- สิ่งที่ไม่ทำ (ระบุชัดเพื่อกัน scope creep)

## Requirements

### Functional
1. ...
2. ...

### Non-functional
- Performance: ...
- Security: ...
- Logging: ...

## Design

### UI / UX
ลิงก์ mockup จาก `spec-ui-designer` agent

### Backend service
ลิงก์ Program Spec จาก `spec-backend-service` agent

### API contract
ลิงก์ API Spec จาก `spec-api-designer` agent

### Database schema
ตาราง/field ที่ต้อง add/modify

### Sequence diagram
```mermaid
sequenceDiagram
  ...
```

## Test cases
ลิงก์ Test Script จาก `spec-tester` agent

## Dev handoff
- GitLab issue: ...
- Postman collection: ...
- ลิงก์ dev handoff package จาก `gateway-thirdparty-api` agent

## Open questions
- [ ] ...

## Decisions log
| Date | Decision | Rationale |
|---|---|---|
| YYYY-MM-DD | ... | ... |

## Related
- [[Projects/<product>/overview]]
- [[Projects/_meta/architecture-decisions]]
