---
title: "Spec Update Workflow (canonical)"
date: 2026-05-06
tags: [workflow, spec, "#tech/sop"]
status: active
owner: "Zayn (ice1@freewillsolutions.com)"
audience: "All spec-* specialist agents"
---

# Spec Update Workflow (canonical)

> Canonical workflow ที่ทุก spec-* specialist agent ใช้เมื่อ SA request **แก้ไข** spec ที่มีอยู่
> (ไม่ใช่สร้างใหม่)
> Specialist agents reference doc นี้ + embed summary ใน prompt ตัวเอง

## When this applies

ใช้ workflow นี้เมื่อ:
- Spec ของ issue ที่อ้างถึง **มีอยู่แล้ว** ใน vault (Glob เจอ `<id>-<slug>/spec.md`)
- SA ใช้คำว่า: *"แก้"*, *"เพิ่ม"*, *"เปลี่ยน"*, *"update"*, *"change"*, *"modify"* + อ้างถึง issue id ที่ exist
- หรือ SA บอก *"issue #X มี change request: ..."*

ถ้า ambiguous → **ถาม SA ชัดเจน** ก่อน:
> "อันนี้ update spec ที่มีอยู่ (issue #X) หรือเขียน spec ใหม่?"

---

## 8-Step Workflow

### Step 1 — Identify target spec
- Extract issue ID / spec path จาก request
- Glob: `**/specs/<id>-*/spec.md` หรือ `**/specs/<id>-<slug>/spec.md`
- ถ้าไม่เจอ:
  - Glob loose: `**/<id>-*` หาทั้งหมด
  - ถ้ายังไม่เจอ → **ถาม SA แทนการเดา**: "หา spec #<id> ไม่เจอ — path ที่ถูกคืออะไร?"

### Step 2 — Read full context (ห้ามข้าม)
- `Read` ไฟล์ `spec.md` **ทั้งไฟล์**
- อ่าน frontmatter:
  - `status` — ถ้า `Production`/`UAT` แล้ว → flag breaking change
  - `last_updated` — เพื่อ update
  - `related_issues` — issues ที่อาจกระทบ
- อ่าน **Change log section** ทั้งหมด → เห็นประวัติการแก้ก่อนหน้า
- ถ้ามี artifact อื่นใน folder เดียวกัน (`test-plan.md`, `api-spec.md`, `ui-mockup.md`, `sequence-diagram.md`) → Glob + Read ด้วย
- ถ้า spec link ไป combined doc (Stub state) → Read combined doc ส่วนที่เกี่ยว

### Step 3 — Plan the change
ระบุชัดเจน **ก่อน** จะแก้:

| ระบุ | ตัวอย่าง |
|---|---|
| What changes | OrderType: varchar(1) → varchar(2) + เพิ่ม NewFee field |
| Affected sections | "Field mapping", "DDL reference", "Test cases TC-005" |
| Affected related artifacts | test-plan.md (TC-005, TC-007), api-spec.md (response schema) |
| Cross-issue impact | #297 ใช้ field เดียวกัน → ต้อง check |
| Backward compatible | ❌ Breaking — old clients ส่ง 1-char จะ fail |
| Production impact | ✅ Coded + Production → ต้อง coordinate deploy |

### Step 4 — Show diff before/after (ห้ามแก้ทันที)
แสดงให้ SA เห็น proposal **เสมอ**:

````markdown
## Proposed changes for #<id>

### File: spec.md

#### Section: <name>

**Before:**
```sql
OrderType varchar(1) NOT NULL
```

**After:**
```sql
OrderType varchar(2) NOT NULL  -- changed per #<id>-cr1
```

#### Section: Field mapping (D-Row)
**Adding row after `amount`:**
| Pos | Field | Type | Source |
|---|---|---|---|
| 19 | NewFee | decimal(22,2) | `redeem.new_fee_amount` |

### Affected files
- spec.md — 2 sections changed
- test-plan.md — TC-005, TC-007 ต้องเพิ่ม validation rules

### Change log entry (will append to spec.md)
| 2026-05-06 | <agent-name> | OrderType varchar(1)→(2) + add NewFee field (#<id>-cr1) |

### Impact analysis
- ⚠️ **Breaking change** — clients ที่ใช้ OrderType 1-char ต้อง migrate
- ⚠️ **Production impact** — ต้อง coordinate กับ deploy plan
- 🔗 **Cross-issue** — #297 ใช้ schema เดียวกัน อาจต้อง update
````

### Step 5 — Wait for explicit confirmation
ถาม SA ชัด ๆ:
> "ยืนยันให้แก้ตามนี้มั้ย? (yes / no / modify-as-follows)"

**ห้ามแก้** ก่อน confirmation ที่ชัดเจน (yes / approved / proceed)

ถ้า SA ขอ modify → ปรับ proposal → กลับ Step 4

### Step 6 — Apply via Edit tool (NOT Write)
**ใช้ `Edit` ทุกครั้ง** ไม่ใช่ Write:
- Edit แต่ละ section ทีละ change (surgical)
- **อย่า rewrite whole file** — git diff ดูยาก + เสี่ยงเสีย formatting อื่น
- แก้ frontmatter:
  ```yaml
  last_updated: <today>
  ```
- **Append** change log row (ห้ามลบ row เก่า — append-only):
  ```markdown
  | 2026-05-06 | <agent-name> | <description> |
  ```

### Step 7 — Update related artifacts in same folder
ถ้า change กระทบ artifact อื่น:
- Edit `test-plan.md` (เพิ่ม/แก้ TC ที่เกี่ยว)
- Edit `api-spec.md` (ถ้า contract เปลี่ยน)
- Edit `sequence-diagram.md` (ถ้า flow เปลี่ยน)
- ทุก artifact ที่เปลี่ยน — **append change log** + **bump last_updated**

### Step 8 — Suggest follow-ups
หลังแก้เสร็จ remind SA:

| ถ้า... | Suggest |
|---|---|
| Test cases กระทบ | `Use spec-tester agent: refresh test-plan based on updated spec` |
| Coded แล้ว / Production | `Use spec-reviewer agent: gap analysis with current code` |
| Index อาจ stale | `Use indexer agent: refresh index` |
| Major change | `Use decision-keeper agent: บันทึก decision เรื่อง <topic>` |
| Session ใกล้จบ | `Use session-logger agent: log this update session` |
| Cross-issue impact (related_issues) | "ตรวจสอบ spec ของ #<other-id> ว่ากระทบมั้ย" |

---

## Edge cases

### Spec ยังเป็น Stub (เนื้อหาอยู่ใน combined doc)
ถ้า `status: Stub` ใน frontmatter:
1. Migrate ก่อน (split content จาก combined → fill stub) — ดู [[Projects/.../specs/README#Migration]]
2. แล้วค่อย apply change request
3. ทำในขั้นเดียวกันได้ (1 commit)

### Production status spec
ถ้า `status: Production`:
- **Flag เด่น ๆ** ใน proposal: "⚠️ Production — change ต้อง coordinate deploy"
- Suggest ADR: "ต้อง decision-keeper บันทึกก่อนแก้มั้ย?"
- Test plan ต้องอัปเดตก่อนแก้ spec (ป้องกัน production regression)

### Multi-issue change
ถ้า change กระทบหลาย issues (เช่น #296 + #297 ใช้ schema เดียวกัน):
1. List specs ที่กระทบทั้งหมด
2. Show proposal สำหรับแต่ละ spec
3. SA confirm batch หรือทีละตัว
4. Apply ทีละไฟล์ — change log ทุกไฟล์ใช้เหตุผลเดียวกัน

### Breaking change
ถ้า change เป็น breaking:
1. Add `breaking_change: true` ใน frontmatter
2. Add `breaking_change_notice` section ใน spec.md
3. Coordinate กับ migration plan
4. Suggest ADR

---

## Anti-patterns (ห้าม)

| ❌ Don't | ✅ Do |
|---|---|
| `Write` overwrite ทั้งไฟล์ | `Edit` surgical เฉพาะ section |
| Apply ก่อน confirmation | Show diff → wait yes → apply |
| ลบ change log row เก่า | Append-only history |
| ข้าม Step 2 (read context) | อ่านครบทุก artifact ก่อนแก้ |
| เดา path | ถาม SA ถ้าไม่เจอไฟล์ |
| แก้ status ตามใจ (เช่น Stub→Production ในชอตเดียว) | Status lifecycle ตามลำดับ |
| ไม่ bump last_updated | Always update |

---

## Reference
- [[.claude/agents/spec-writer]] — orchestrator (detects create vs update)
- Specialist agents that follow this workflow:
  - [[.claude/agents/spec-backend-service]]
  - [[.claude/agents/spec-api-designer]]
  - [[.claude/agents/spec-ui-designer]]
  - [[.claude/agents/spec-report-designer]]
  - [[.claude/agents/spec-tester]]
  - [[.claude/agents/spec-reviewer]]
  - [[.claude/agents/gateway-thirdparty-api]]
