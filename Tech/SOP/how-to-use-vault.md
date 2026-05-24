---
title: "How to Use This Vault — Daily Workflows + Agent Cheatsheet"
date: 2026-05-05
tags: [sop, "#tech/sop", "#usage-guide"]
status: active
owner: "Zayn (ice1@freewillsolutions.com)"
audience: "ทุกคนในทีม (SA Lead + SA Members)"
---

# How to Use This Vault

> Daily-use guide สำหรับทีม — workflows + agent cheatsheet + ตัวอย่าง prompts

## When to use this
อ่านหลังจาก setup เสร็จ (ตาม [[Tech/SOP/team-onboarding-claude-code]] หรือ [[Tech/SOP/team-onboarding-claude-desktop]]) — ใช้เป็น reference ระหว่างทำงาน

---

## 1. Vault ทำอะไรได้

ระบบช่วย SA ทำงาน 7 อย่าง — แต่ละอย่างมี agent เฉพาะ

| งาน | Agent หลัก | ตัวอย่าง use case |
|---|---|---|
| ออกแบบ UI / mockup | `spec-ui-designer` | "ออกแบบหน้า admin user management" |
| เขียน spec backend service | `spec-backend-service` | "spec service ดึงข้อมูล daily" |
| ออกแบบ REST API | `spec-api-designer` | "ออก API สำหรับ payment" |
| เขียน TFS report | `spec-report-designer` | "spec report Daily Confirmation" |
| ทำ test script | `spec-tester` | "test script SBCP004 convert" |
| Review code ที่ dev ส่งมา | `spec-reviewer` | "review code SBCP004" |
| ออก spec package ครบ (16 artifacts) | `gateway-thirdparty-api` | "spec ครบสำหรับ feature payment" |

**ไม่แน่ใจใช้ตัวไหน?** เริ่มที่ `spec-writer` (orchestrator) → มันเลือก specialist ให้

---

## 2. Quick Start (วันแรก)

### ถ้าคุณคือ **SA Lead** (Claude Code CLI)
```bash
cd ~/team-kb
git pull
claude
```
จากนั้น:
```
Use the session-logger agent: read at session start
```
→ AI สรุปว่าทีมคุยอะไรไปแล้ว, มี ADR อะไร, งานค้างอะไร

### ถ้าคุณคือ **SA Member** (Claude Desktop + MCP)
1. เปิด Claude Desktop App
2. New chat
3. พิมพ์:
```
อ่าน Memory/summary.md, Projects/_meta/architecture-decisions.md
และ .index/master-index.md ก่อน แล้วสรุปให้ฉันว่า vault นี้
มีอะไรบ้าง + งานค้าง
```
→ AI ผ่าน MCP filesystem จะเข้าถึงไฟล์ + ตอบ

---

## 3. Daily Workflows (3 patterns ที่ใช้บ่อยสุด)

### 🟦 Workflow A: ออก spec ใหม่

```
Step 1: เริ่มด้วย orchestrator
   ↓
   "Use the spec-writer agent: <งาน>"
   ↓
   spec-writer ระบุประเภท → ส่ง specialist ที่เหมาะ

Step 2: Specialist ถามข้อมูล (ทีละกลุ่ม)
   - ตอบให้ครบ ถ้าไม่รู้ → ตอบ "TBD" — agent จะ flag ให้

Step 3: Specialist generate draft
   - ดู draft → confirm save หรือขอแก้

Step 4: หลัง save
   - "Use the indexer agent to refresh index"
   - "Use the session-logger agent: log this session"
```

**ตัวอย่าง prompts จริง:**
```
Use the spec-writer agent: ออกแบบหน้า list ลูกค้าสำหรับ back-office

Use the spec-writer agent: ขอ spec ครบสำหรับ feature ส่ง notification (มีทั้ง UI + API + DB)

Use the spec-writer agent: review code SBCP005 ที่ dev ส่งมา (paste link/file)
```

### 🟩 Workflow B: ค้นข้อมูลใน vault

```
"Use the kb-assistant agent: <คำถาม>"
```

**ตัวอย่าง:**
```
Use the kb-assistant agent: GPP × SCB มี program reconcile กี่ตัว

Use the kb-assistant agent: ลูกค้า ACME เคยทำ project อะไรบ้าง

Use the kb-assistant agent: SOP onboarding มีขั้นตอนอะไรบ้าง

Use the kb-assistant agent: ใน export-eod-scb แก้ MerchantReferenceID ยังไง
```

### 🟨 Workflow C: บันทึก decision / จบงาน

```
มี architectural decision:
   "Use the decision-keeper agent: บันทึก decision <topic>"

จบ work session:
   "Use the session-logger agent: log this session"
```

---

## 4. Agent Cheatsheet (12 agents)

### 🎯 Spec workflow (8)

| Agent | Trigger phrases | When to use |
|---|---|---|
| `spec-writer` | ไม่แน่ใจ / mixed type | **เริ่มจากตัวนี้เสมอ** ถ้าไม่ชัดว่าใช้ specialist ไหน |
| `spec-ui-designer` | "ออกแบบหน้า", "mockup", "wireframe", "admin panel" | งาน UI อย่างเดียว |
| `spec-backend-service` | "/spec_service", "TFS service", "Java backend" | งาน backend service spec |
| `spec-api-designer` | "ออกแบบ API", "REST", "endpoint", "OpenAPI" | งาน API contract |
| `spec-report-designer` | "/spec_report", "TFS report", "Daily Confirmation" | งาน report TFS |
| `spec-tester` | "/test_service", "test script" | สร้าง test สำหรับ backend service |
| `spec-reviewer` | "/review_service", "review code", "ตรวจ code" | review โค้ด vs spec |
| `gateway-thirdparty-api` | "spec ครบ", "complete handoff", "GitLab issue" | full package 16 artifacts |

### 🧠 Memory (2)

| Agent | Trigger | When to use |
|---|---|---|
| `decision-keeper` | "บันทึก decision", "log this decision" | มี architectural decision |
| `session-logger` | "log session", "บันทึก session" / "read at session start" | จบ session / เริ่ม session ใหม่ |

### 🛠️ Supporting (2)

| Agent | Trigger | When to use |
|---|---|---|
| `kb-assistant` | "ค้นใน vault", "เคยมี... มั้ย" | Q&A จาก vault |
| `indexer` | "refresh index" | หลังเพิ่ม/แก้ note |

---

## 5. Common Tasks (copy-paste ได้เลย)

### Task: SA Member ลำดับการเริ่มทำงานวันใหม่
```
1. git pull (ใน terminal)
2. เปิด Claude Desktop
3. "Use the session-logger agent: read at session start"
4. "Use the project-tracker (kb-assistant) agent: งานค้างอะไรบ้าง"
5. ทำงานปกติ
6. จบวัน: "Use the session-logger agent: log this session"
```

### Task: ออก spec API ใหม่
```
"Use the spec-api-designer agent:
ต้องการออก API สำหรับ <feature>
- consumer: <web/mobile/3rd party>
- auth: <required/public>
- รายละเอียด: <...>"
```

### Task: ทำ spec ครบสำหรับ feature ใหม่
```
"Use the gateway-thirdparty-api agent:
feature: <name>
มี UI: <yes/no>
มี API: <yes/no>
มี DB เปลี่ยนแปลง: <yes/no>
partner-facing: <yes/no>
context: <...>"
```

### Task: review code ที่ dev ส่งกลับ
```
"Use the spec-reviewer agent:
program: <SBCP004>
spec: <link/path ถึง spec>
code: <paste หรือ link>
test results: <ถ้ามี>"
```

### Task: ค้นข้อมูล GPP × SCB
```
"Use the kb-assistant agent:
<คำถามเฉพาะ>
context: GPP × SCB integration"
```

### Task: บันทึก architectural decision
```
"Use the decision-keeper agent: บันทึก decision
Title: <decision title>
Context: <ทำไมต้องตัดสินใจ>
Decision: <ตัดสินใจอะไร>
Rationale: <เหตุผล>
Alternatives: <ทางอื่นที่ปฏิเสธ>"
```

---

## 6. Troubleshooting

### "Agent ไม่ตอบตามที่คาด"
- ตรวจว่า agent อ่าน skill file แล้วมั้ย — บอกชื่อ skill ในคำถาม
- ลอง `Use the spec-writer agent: ...` แทน specialist โดยตรง — orchestrator จะ route ให้

### "ค้นใน vault ไม่เจอข้อมูลที่ควรมี"
- รัน `Use the indexer agent to refresh index` ก่อน
- ลอง search ด้วยคำอื่น (synonym)
- ดู [[.index/by-tag]] เพื่อ browse ตาม tag

### "หาไฟล์ที่เพิ่งสร้างไม่เจอ"
- ลืม refresh index หลัง save
- รัน indexer แล้วลองอีกครั้ง

### "Memory ของ AI ดูจะลืมเรื่องที่คุย"
- รัน `Use the session-logger agent: read at session start` ตอนเริ่ม session
- ตรวจว่า [[Memory/summary]] update ล่าสุดแล้ว

### "ทำ spec ผิดประเภท / ผิด skill"
- หยุดก่อนแล้วถาม `spec-writer`: "ฉันควรใช้ specialist ไหนสำหรับ <งาน>"
- ดู [[ProgramType_Skills/overview]] เปรียบเทียบ skills

### "MCP filesystem ไม่ทำงาน (Claude Desktop)"
- เช็ค path ใน config: `claude_desktop_config.json`
- Quit Claude Desktop ทั้งหมด → เปิดใหม่
- ดู [[Tech/SOP/team-onboarding-claude-desktop]] step 3-4

### "Push ไม่ได้ — permission denied"
- คุณคือ SA Member (Read role) — push ไม่ได้
- ส่ง draft ให้ SA Lead ผ่าน Slack หรือ fork + PR

---

## 7. Where to find things (navigation cheatsheet)

| ต้องการดู | ไปที่ |
|---|---|
| Vault rules / overall structure | [[CLAUDE]] |
| ตัดสินใจที่ทีมทำไปแล้ว | [[Projects/_meta/architecture-decisions]] |
| สรุป session ก่อน | [[Memory/summary]] |
| Session แต่ละวัน | `Memory/sessions/YYYY-MM-DD.md` |
| ทุก notes ใน vault | [[.index/master-index]] |
| Notes ตาม tag | [[.index/by-tag]] |
| Notes ตามประเภท | [[.index/by-type]] |
| Skills SA ทั้งหมด | [[ProgramType_Skills/overview]] |
| Real project ตัวอย่าง | [[Projects/gpp/overview]] |
| Setup สำหรับ SA Lead | [[Tech/SOP/team-onboarding-claude-code]] |
| Setup สำหรับ SA Members | [[Tech/SOP/team-onboarding-claude-desktop]] |
| **คู่มือนี้** | [[Tech/SOP/how-to-use-vault]] |

---

## 8. Tips & Best Practices

### ✅ DO
- **เริ่มทุก session** ด้วย `session-logger: read at session start`
- **จบทุก session ใหญ่** ด้วย `session-logger: log this session`
- **มี decision** → `decision-keeper: บันทึก decision`
- **ใช้ orchestrator** (`spec-writer`) ถ้าไม่ชัดว่าใช้ตัวไหน
- **Refresh index** หลังเพิ่ม/แก้ note (`indexer`)
- **Cite filenames** ในคำถาม (เช่น "ใน [[Projects/gpp/overview]] บอกว่า...")
- **แนบรูป** ตอนออก spec UI — drag & drop ใน Claude Desktop

### ❌ DON'T
- **อย่าใช้ specialist โดยตรง** ถ้าไม่ชัด — ให้ orchestrator route ให้ก่อน
- **อย่า paste secrets/credentials** — vault มี audit log
- **อย่าแก้ `.index/` ด้วยมือ** — ใช้ `indexer` agent
- **อย่าแก้ ADR เก่า** — ใช้ "Superseded by ADR-XXX" pattern
- **อย่า push direct ถ้าเป็น Member** — ส่ง draft ให้ Lead

### 🎯 Pro tips
- **Pin chat สำคัญ** ใน Claude Desktop sidebar
- **Star session log** ที่อ้างอิงบ่อย
- **ตั้ง Project Instructions** ใน Claude.ai Project = paste vault rules ครั้งเดียว
- **ใช้ subagent ซ้อน** ได้ — `gateway-thirdparty-api` เรียก specialists อื่นเอง
- **Search memory** — `kb-assistant` ค้นใน `Memory/sessions/` ได้

---

## 9. Need help?

**ถามคำถาม "ใช้งานยังไง" ได้ที่:**
```
Use the kb-assistant agent: <คำถามเรื่อง usage>
```

ตัวอย่าง:
- "ฉันจะออก spec API พร้อม partner guide ยังไง"
- "Memory กับ ADR ต่างกันยังไง ใช้ตัวไหนเมื่อไหร่"
- "ถ้าผมเป็น SA Member จะ contribute ใน vault ยังไง"

→ kb-assistant จะอ่าน [[Tech/SOP/how-to-use-vault]] (ไฟล์นี้) + ที่เกี่ยวข้อง → ตอบให้

## Related
- [[CLAUDE]] — vault rules
- [[Tech/SOP/team-onboarding-claude-code]] — setup SA Lead
- [[Tech/SOP/team-onboarding-claude-desktop]] — setup SA Members
- [[Memory/README]] — explains memory system
- [[Projects/_meta/architecture-decisions]] — ADRs
- [[ProgramType_Skills/overview]] — skills index
