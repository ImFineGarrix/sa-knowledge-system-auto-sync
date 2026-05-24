# คู่มือการใช้งาน SA Skill
## สำหรับ System Analyst
### BackOffice Automation System — Java Backend Service

---

## Skill ที่มีอยู่

| Skill | คำสั่ง | ใช้เพื่อ |
|-------|--------|---------|
| **spec-service** | `/spec_service` | สร้าง Program Specification + DDL ส่ง Dev |
| **test-service** | `/test_service` | สร้าง Test Script + Test Data |
| **review-service** | `/review_service` | ตรวจโปรแกรมที่ Dev ส่งกลับ + Bug Report |

---

## ภาพรวม Workflow

```
SA รับ Requirement
        ↓
1. /spec_service → Spec .md + DDL .sql (ถ้ามี Table ใหม่)
        ↓
2. /test_service → Test Script + Test Data
        ↓
3. SA review Spec + Test Script → พิมพ์ /release
   (แนบทั้ง Spec และ Test Script พร้อมกัน)
   → AI update Spec เป็น v1.0 ✅
   → AI update Spec Version อ้างอิงใน Test Script ให้ตรงกัน
        ↓
4. ส่งไฟล์ทั้งหมดให้ Dev + เปิด Git Issue
        ↓
Dev ใช้ AI ช่วย Code + Test
        ↓
5. Dev ส่ง Java code กลับมา
        ↓
6. /review_service → Review Report + Bug Report
        ↓
ถ้าผ่าน → Sign-off
ถ้าไม่ผ่าน → ส่ง Bug Report กลับ Dev → เปิด Git Issue
```

---

## ส่วนที่ 1: `/spec_service` — สร้าง Spec

### รูปแบบคำสั่ง

```
/spec_service [ชื่อโปรแกรม] [scenario] [service type]
```

**Scenario:**
- `new` — ยังไม่มี Spec เลย เริ่มจากศูนย์
- `modify` — มี Spec อยู่แล้ว ต้องการแก้ไขหรือเพิ่มเติม เช่น:
  - แก้ bug หลัง deploy
  - เพิ่ม requirement ที่ตกหล่นหลัง release (แม้ Dev ยังไม่ได้ code)
  - SA นึกอะไรออกหลังส่ง Spec ไปแล้ว
- `convert` — ใช้ใน 2 กรณี:
  - **แปลง 4GL เป็น Java** — แนบ `.4gl` ให้ AI อ่านแล้ว gen Spec สำหรับ Java
  - **สร้าง Spec จากโปรแกรมที่มีอยู่แล้วแต่ไม่เคยมี Spec** — แนบ Source Code ที่มี (.java หรือ .4gl) ให้ AI อ่านแล้ว gen Spec .md มาตรฐาน เพื่อใช้ AI ช่วยงานในระยะยาว

> **กฎสำคัญ:** ถ้ามี Spec อยู่แล้วไม่ว่าจะ version ไหน → ใช้ `modify` เสมอ ไม่ใช่ `new`

**Service Type:**
- `Post` — ประมวลผลจาก Database
- `Daemon` — Realtime ผ่าน Openfire/IM
- `Import` — นำเข้าข้อมูลจากไฟล์
- `Export` — ส่งออกข้อมูลเป็นไฟล์

**ตัวอย่าง:**
```
/spec_service SBCP005 new Post
/spec_service SBCP004 modify Post
/spec_service SBCP004 convert Post
```

---

### เตรียมก่อนเรียก

| Scenario | ไฟล์ที่ควรแนบ |
|----------|-------------|
| `new` | Requirement document (.docx, .pdf, หรือข้อความ) |
| `modify` (Java) | Spec เดิม (.md) + Source Code เดิม (.java) + issue ที่ต้องแก้ |
| `modify` (4GL) | Spec เดิม (.md) + Source Code เดิม (.4gl) + issue ที่ต้องแก้ |
| `convert` | Source Code ทุกไฟล์ (.java หรือ .4gl) + DDL (ถ้ามี) |

> **AI detect technology จากนามสกุลไฟล์อัตโนมัติ:**
> - แนบ `.4gl` → AI รู้ว่าเป็น 4GL → ออก Spec แนวทางแก้ 4GL ไม่มี Java Class Template
> - แนบ `.java` → AI รู้ว่าเป็น Java → ออก Spec + Java Class Template ปกติ
> - ไม่แนบ + `new` → default เป็น Java
> - ไม่แน่ใจ → AI จะถามก่อน

> **โปรแกรมที่มีโครงสร้าง folder ซับซ้อน (เช่น Daemon ที่มี func/, bean/, util/ ฯลฯ):**
> Claude.ai แนบ folder ไม่ได้ ต้องแนบทีละไฟล์ — แนะนำให้แนบเฉพาะไฟล์ที่มี business logic หลัก เช่น daemon/, func/ และข้าม util/, bean/ ที่เป็น helper ทั่วไป
> หรือใช้ **Cowork** แทน ซึ่งอ่านไฟล์จาก folder ได้โดยตรงโดยไม่ต้องแนบทีละไฟล์

---

### ขั้นตอนหลังพิมพ์คำสั่ง

**ขั้นที่ 1 — AI ถาม Core Questions**
- New SBA Phase (0/1)
- Database (Informix/MySQL/MSSQL)
- Table ที่ READ/WRITE
- Business Logic หลัก
- Volume (กี่ record ต่อครั้ง)

**ขั้นที่ 2 — AI ถาม Business Edge Cases (new/modify)**

> **ถ้าตอบไม่ได้** — พิมพ์ "TBD" AI จะระบุในSpec ว่าต้องสอบถาม BA เพิ่ม

| หัวข้อ | ตัวอย่างคำถาม |
|--------|-------------|
| Boundary Cases | ถ้าข้อมูลเป็น null หรือ 0 ทำอะไร? |
| Error Scenario | fail กลางคัน — rollback ทั้งหมดหรือ partial? |
| Lookup null | ถ้าหาข้อมูลจาก Library ไม่เจอ — skip/error/default? |
| Data Dependency | ต้องรันโปรแกรมอะไรก่อน? |
| Reverse/Undo | ถ้าต้องยกเลิก business มี process ไหม? |
| Non-happy Path | ถ้า external system timeout ทำอะไร? |

**ขั้นที่ 3 — AI แสดง Draft Summary**

AI สรุปสิ่งที่เข้าใจให้ตรวจก่อนเสมอ — ถ้าไม่ถูกบอก AI ว่าแก้ตรงไหน

**ขั้นที่ 4 — พิมพ์ "Confirm"**

AI สร้างไฟล์ Spec และ DDL (ถ้ามี Table ใหม่)

**ขั้นที่ 5 — AI Readiness Assessment**

AI แจ้งว่า Spec นี้ถ้าให้ AI ช่วย code ได้ประมาณกี่ % และยังขาดอะไร

---

### ไฟล์ที่ได้จาก `/spec_service`

| ไฟล์ | เมื่อไหร่ |
|------|---------|
| `[ชื่อ]-TFS-Spec.md` | ทุกครั้ง |
| `[ชื่อ]-DDL-informix.sql` | ถ้ามี Table ใหม่หรือแก้ Schema |
| `[ชื่อ]-DDL-mysql.sql` | ถ้ารองรับ MySQL |
| `[ชื่อ]-DDL-mssql.sql` | ถ้ารองรับ MSSQL |

---

### Version Control — Draft และ Release

**Spec มี 2 สถานะ:**
- **Draft (d1, d2, ...)** — ระหว่างแก้ไขกับ AI ยังไม่ส่ง Dev
- **Released (v1.0, v1.1, ...)** — SA review ครบแล้ว พร้อมส่ง Dev

**Flow:**
```
สร้าง Spec → d1
แก้ไข      → d2, d3, d4 ...
SA review   → พิมพ์ /release → v1.0 ✅ พร้อมส่ง Dev
แก้อีกรอบ  → d5, d6 ...
SA review   → พิมพ์ /release → v1.1 ✅ + Change Summary
```

> ⚠️ `/release` **ไม่ใช่ Skill แยก** — เป็นคำสั่งที่พิมพ์ใน **conversation เดียวกัน** กับที่กำลังทำ Spec อยู่
> AI ของ spec-service รู้จักคำสั่งนี้อัตโนมัติ ไม่ต้องเปิด conversation ใหม่

**เมื่อพิมพ์ `/release` ใน conversation เดิม:**
- AI ตรวจว่ายังมีช่อง TBD ไหม → แจ้งเตือนก่อน
- Promote draft เป็น version ล่าสุด
- ถ้าเป็น release ครั้งที่ 2+ → สร้าง **Change Summary** และ **Git Issue Template** ให้อัตโนมัติ

**ตัวอย่าง Git Issue Template ที่ได้:**
```
Title: [SBCP004] Spec v1.1 — แก้ไข Error Handling

Body:
อ้างอิง Spec: SBCP004-TFS-Spec.md v1.1
เปลี่ยนแปลงจาก v1.0:
1. Section 6: null fisaccount → INSERT tposterr
2. Section 9: exportCount ต้องเป็น AtomicInteger
กรุณาแก้ไขตาม Spec v1.1 ที่แนบมา
```

---

## ส่วนที่ 2: `/test_service` — สร้าง Test Script

### รูปแบบคำสั่ง

```
/test_service [ชื่อโปรแกรม] [scenario]
```

### เตรียมก่อนเรียก

**แนบ DDL ก่อน** — ช่วยให้ Test Data ตรง schema จริง ไม่ต้องปรับเอง

**วิธี Extract DDL จาก Informix:**
```bash
# Shell Script (แนะนำ)
./extract_ddl.sh
# ได้ไฟล์: ddl_output.sql → แนบให้ AI

# dbschema ทีละ table
dbschema -d [db_name] -t [table_name] -ss >> ddl_output.sql
```

### ไฟล์ที่ได้

| ไฟล์ | ประกอบด้วย |
|------|-----------|
| `[ชื่อ]-Test-Script.md` | Environment Checklist (Section 0), Test Cases, Code Review Checklist, SQL Verification, Sign-off |
| `[ชื่อ]-Test-Data.md` | SQL Script เตรียมข้อมูล + Verification Queries |

---

## ส่วนที่ 3: ส่งงานให้ Dev

### ไฟล์ที่ควรส่งครบชุด

**กรณี new / convert:**
```
📁 ส่งให้ Dev
├── [ชื่อ]-TFS-Spec.md          ← Spec (version ที่ /release แล้ว)
├── [ชื่อ]-DDL-informix.sql     ← DDL (ถ้ามี Table ใหม่)
├── [ชื่อ]-DDL-mysql.sql        ← DDL MySQL (ถ้ารองรับ)
├── [ชื่อ]-DDL-mssql.sql        ← DDL MSSQL (ถ้ารองรับ)
├── [ชื่อ]-Test-Script.md       ← Test Script
├── [ชื่อ]-Test-Data.md         ← Test Data (SQL + CSV content)
└── [ชื่อ]-*.csv                ← ไฟล์ CSV สำหรับ test (เฉพาะโปรแกรม Import)
```

> **โปรแกรม Import — ต้องส่ง CSV test files ด้วยเสมอ**
> Dev ต้องมีไฟล์ CSV จริงจึงจะรัน test ได้ — CSV content อยู่ใน Test Data แล้ว
> แต่ SA ควรสร้างไฟล์จริงส่งให้ Dev ด้วยเพื่อความสะดวก

**กรณี modify (แก้ bug):**
```
📁 ส่งให้ Dev
├── [ชื่อ]-TFS-Spec.md          ← Spec version ใหม่ที่ /release แล้ว
├── [ชื่อ]-Test-Script.md       ← Test Script (update ถ้ามี test case เพิ่ม)
├── [ชื่อ]-Test-Data.md         ← Test Data
└── Git Issue                   ← Change Summary ที่ AI สร้างให้ (ระบุ version ที่มีปัญหา)
```

> **กรณีแก้ bug — ต้องแจ้ง version ที่มีปัญหาด้วยเสมอ:**
> Dev ต้องรู้ว่า bug เกิดใน version ไหน เพื่อ checkout code version นั้นมาแก้ได้ถูกต้อง
> ระบุใน Git Issue เช่น "พบปัญหาใน v1.2 ที่ deploy บน server PROD-01"

### Git Issue

ใช้ Git Issue Template ที่ AI สร้างให้ตอน `/release` ได้เลย — ระบุชัดว่า Dev ต้องทำอะไร

---

## ส่วนที่ 4: `/review_service` — ตรวจโปรแกรมที่ Dev ส่งกลับ

### รูปแบบคำสั่ง

```
/review_service [ชื่อโปรแกรม]
```

> **Flow จริงมี 2 รอบ — Dev ส่งคนละชุดในแต่ละรอบ**

### รอบที่ 1: รอบ Review (ก่อน SA approve) — ใช้ /review_service

Dev ส่งมาให้ SA ก่อน — **ยังไม่ต้อง SonarQube และยังไม่ได้ control version**

| ไฟล์ | จำเป็น | หมายเหตุ |
|------|-------|---------|
| Java source code | ✅ ต้องมี | Main Class + Sub Class |
| Spec .md (version Released) | ✅ ต้องมี | ใช้เป็น reference |
| Log file หลังรันโปรแกรม | ✅ ต้องมี | ส่ง 2 ไฟล์: จากการรัน `-c 0` และ `-c 1` (ดูชื่อไฟล์ด้านล่าง) |
| DB-Result.txt | ✅ ต้องมี | output จาก Verification Queries ทุกข้อใน Test Script Section 4 (ดู format ด้านล่าง) |

> **Log file — naming convention:**
> SBA framework เขียน log ชื่อเดียวกันทั้งสองรอบ Dev ต้องเปลี่ยนชื่อก่อนส่ง:
> ```
> [ชื่อโปรแกรม]_c0.log   ← จากการรัน -c 0 (rollback — ตรวจ flow ไม่กระทบ DB)
> [ชื่อโปรแกรม]_c1.log   ← จากการรัน -c 1 (commit จริง — ตรวจ DB ถูกต้อง)
> ```
> ตัวอย่าง: `SBCP005_c0.log` และ `SBCP005_c1.log`

> **DB-Result.txt — format ที่ AI อ่านได้:**
> Dev copy output จาก dbaccess มาวางตามนี้ทุก query:
> ```
> === Query 1: ตรวจ SFBCM statusflag หลัง process ===
> reqid            statusflag  resultcode  errmsg
> TEST-REQ-001     C           000
> 1 rows returned.
>
> === Query 2: ตรวจ JJCBL sendflag ===
> account          sendflag    senddate
> 0000001234567    1           2026-05-02
> 1 rows returned.
>
> === Query 3: [ชื่อ query] ===
> No rows returned.
> ```
> กฎ: ขึ้นต้นด้วย `=== Query N: [ชื่อ] ===` · copy raw output ทั้งหมด · ถ้าไม่มีผลลัพธ์ใส่ `No rows returned.`
| Sign-off Checklist | ✅ ต้องมี | Dev กรอกครบ — ระบุ Commit Hash ที่ใช้รัน test |
| Test Script .md | แนะนำ | AI ใช้เป็น checklist ตรวจครบทุก case |

> ⚠️ ถ้า Dev ส่ง SonarQube มาในรอบนี้ แสดงว่า Dev เข้าใจ flow ผิด — ยังไม่ควร control version ก่อน SA approve

### ไฟล์ที่ได้

`[ชื่อ]-Review-Report.md` ประกอบด้วย Executive Summary, Code vs Spec Gap (Critical 🔴 / Minor 🟡), Code Quality Check, Test Case Verification, Bug Report, Sign-off Checklist

### หลังได้ Report

**ถ้าผ่าน (SA approve):**
1. กรอก Sign-off Checklist ให้ครบ
2. **Comment ใน Git Issue เดิม** พร้อม Commit Hash ที่ approve:

```
✅ Approved — [ชื่อโปรแกรม] v[x.y]

Spec Version : [ชื่อโปรแกรม]-TFS-Spec.md v[x.y]
Commit Hash  : [hash จาก Sign-off Checklist ของ Dev]

Action ที่ Dev ต้องทำ:
1. ใช้ commit [hash] เป็น base — ห้าม commit เพิ่ม
2. tag: [ชื่อโปรแกรม]-v[x.y] จาก hash นั้น
3. run SonarQube จาก commit ที่ tag แล้ว → ต้อง Passed
4. comment กลับ: "Tagged [ชื่อโปรแกรม]-v[x.y] from [hash]" พร้อมแนบ SonarQube report
```

3. Assign Issue กลับให้ Dev

### รอบที่ 2: รอบ Control Version (หลัง SA approve) — SA ตรวจเองเฉยๆ

**ไม่ต้องเรียก `/review_service` อีก** — code ผ่าน review แล้ว ไม่มีอะไรเปลี่ยน

Dev comment ใน Issue เดิม พร้อมแนบ SonarQube report:
```
Done — Tagged [ชื่อโปรแกรม]-v[x.y] from [hash]
```

**SA ตรวจแค่ 2 อย่างก่อนปิด Issue (ผ่าน GitLab UI):**
1. เข้า GitLab → Repository → **Tags**
2. หา tag `[ชื่อโปรแกรม]-v[x.y]` → คลิกดู commit ที่ tag ชี้
3. hash ตรงกับที่ approve ไว้ + SonarQube Passed → ปิด Issue ✅

> **ทำไม Commit Hash ถึงสำคัญ?** ป้องกัน Dev หยิบ code version ผิดไป tag — hash ที่ SA approve คือ code ที่ผ่าน review แล้ว Dev ต้อง tag จาก hash นั้นเท่านั้น

**ถ้าไม่ผ่าน (รอบ Review):**
1. copy Bug Report จาก Report → แจ้ง Dev แก้
2. เมื่อ Dev ส่งกลับมา → เรียกใหม่แนบ Report เดิม:

```
/review_service SBCP004
[แนบ code ใหม่ + SBCP004-Review-Report.md]
"ช่วยตรวจว่า Dev แก้ Bug #1 และ #2 แล้วหรือยัง"
```

AI จะตรวจเฉพาะ issue เดิม ไม่ต้อง review ใหม่ทั้งหมด

---

## Tips

### ✅ ทำแบบนี้
- **แนบไฟล์พร้อมคำสั่งทันที** — ไม่ต้องรอให้ AI ถามก่อน
- **บอกตรงๆ ถ้าไม่รู้** — พิมพ์ "TBD" ดีกว่าเดา
- **อ่าน Draft Summary ก่อน Confirm** ทุกครั้ง
- **พิมพ์ /release** เมื่อ review ครบแล้ว — อย่าส่ง draft ให้ Dev
- **แนบ Spec เดิม** เมื่อต้องการแก้ Spec หลัง release

### ❌ หลีกเลี่ยง
- **อย่า Confirm ทันที** ถ้ายังไม่ได้อ่าน Draft Summary
- **อย่าเดาชื่อ Table/Field** — บอก AI ว่าต้องตรวจสอบก่อน
- **อย่าส่งแค่ Spec** — Dev ต้องการ Test Script ด้วย
- **อย่าส่ง Spec ที่ยัง draft** (ยังไม่ /release) ให้ Dev

---

## คำถามที่พบบ่อย

**Q: มีโปรแกรมอยู่แล้วแต่ไม่เคยมี Spec .md ต้องการสร้างเพื่อใช้ AI ช่วยงานในระยะยาว ต้องทำอะไร?**
A: ใช้ `/spec_service [ชื่อโปรแกรม] convert [type]` แล้วแนบ Source Code ทุกไฟล์ + DDL (ถ้ามี) AI จะอ่าน code แล้ว gen Spec .md มาตรฐานให้ พร้อมถามเฉพาะส่วนที่ code ไม่ชัดเจน

**Q: โปรแกรมต้อง connect หลาย database (เช่น BA, refdb, do หรือ database อื่นๆ) ต้องทำอะไร?**
A: บอก AI ว่าโปรแกรม connect database อะไรบ้าง และแต่ละตัวมีสิทธิ์ read-only หรือ read+write — AI จะถามใน Pillar 1 อัตโนมัติ แล้วระบุใน Spec ว่า SQL ไหนใช้ connection ไหน

> **หมายเหตุ:** refdb ของ Product อื่น (เช่น BrokerMgmt) → read-only เสมอ แต่ database อื่นเช่น `do` → write ได้ถ้า SA ระบุว่ามีสิทธิ์

**Q: โปรแกรมเป็น 4GL ต้องแก้ bug ต้องทำอะไร?**
A: ใช้ `/spec_service [ชื่อโปรแกรม] modify [type]` แล้วแนบไฟล์ `.4gl` มาด้วย AI จะรู้ทันทีว่าเป็น 4GL และออก Spec แนวทางแก้ 4GL โดยไม่ gen Java Class Template

**Q: Spec เปลี่ยนแล้วกระทบ Test Script ต้องทำอะไร?**
A: เรียก `/test_service [ชื่อโปรแกรม] modify` แล้วแนบ Spec version ใหม่ + Test Script เดิม แล้วบอกว่า Spec เปลี่ยนตรงไหน AI จะแก้เฉพาะ test case ที่ได้รับผลกระทบ ไม่ gen ใหม่ทั้งหมด

**Q: release Spec v1.0 ไปแล้ว แต่นึกออกว่าตกหล่นบางอย่าง Dev ยังไม่ได้ code — ต้องทำอะไร?**
A: ใช้ `/spec_service [ชื่อ] modify [type]` แนบ Spec v1.0 มาด้วย แล้วบอกว่าต้องการเพิ่มอะไร AI จะ draft d2 ต่อจาก v1.0 → SA review → `/release` เป็น v1.1 — ไม่ต้องสร้าง Spec ใหม่ทั้งหมด

**Q: ไม่รู้ Service Type ต้องทำอะไร?**
A: บอก AI ว่า "โปรแกรมนี้ทำอะไร" AI จะแนะนำ Service Type ให้

**Q: Spec ที่ได้ไม่ถูกต้อง แก้ยังไง?**
A: บอก AI ตรงๆ เช่น "Table ไม่ใช่ tfee แต่เป็น tcharge" AI จะแก้และ draft ใหม่

**Q: SA คนละคนแก้ Spec ต่อได้ไหม?**
A: ได้ครับ — แนบ Spec เดิมมาพร้อมบอกว่าต้องแก้อะไร AI จะอ่าน Version History แล้ว draft ต่อจากตรงนั้นได้เลย

**Q: AI Readiness Assessment ได้แค่ 80% ต้องทำอะไร?**
A: อ่านว่าขาดอะไร → ถ้ามีข้อมูลแนบให้ AI update Spec → ถ้าไม่มีระบุเป็น Dev Action Required ใน Spec

**Q: Dev บอก Spec ไม่ครบ ต้องทำอะไร?**
A: เรียก /spec_service แนบ Spec เดิม + บอกสิ่งที่ขาด → AI แก้ → /release เป็น version ใหม่ → เปิด Git Issue ด้วย Change Summary ที่ AI สร้างให้
