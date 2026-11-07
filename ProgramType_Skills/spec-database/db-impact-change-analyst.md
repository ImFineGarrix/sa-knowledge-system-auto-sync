---
name: db-impact-change-analyst
description: ใช้ skill นี้สำหรับวิเคราะห์ Impact Analysis ของการเปลี่ยนแปลง Database Schema ว่า change นี้ส่งผลกระทบต่อ Column / Table ไหน, Program / Module / API / Stored Procedure ไหน, Index ไหน, Permission และ Security เปลี่ยนยังไง พร้อมเสนอ Migration Plan และ Rollback Strategy Trigger ได้แก่ 'impact analysis', 'change analysis', 'analyse impact', 'ALTER TABLE impact', 'breaking change', 'migration risk' หรือเมื่อ parent skill (db-create-spec) เรียกใช้ใน Mode Modify
---

# db-impact-change-analyst

## Role & Goal

Skill นี้เป็น **เจ้าของไฟล์ `IMPACT_<Module>.md`** ซึ่งครอบคลุม **2 มิติ:**

**มิติ 1 — Impact Analysis** (เมื่อมีการเปลี่ยนแปลง Schema)
รายงานครอบคลุม:
1. **Schema-level:** Column / Table ที่ถูกกระทบโดยตรง
2. **Code-level:** Program / Module / API / Stored Procedure / Trigger ที่ใช้ Field นั้น
3. **Index-level:** Index ที่ต้องสร้าง / drop / rebuild
4. **Permission & Security:** สิทธิ์ที่อาจเปลี่ยน
5. **Data-level:** Data Migration ที่ต้องทำ + ความเสี่ยง
6. **Rollback Strategy**

**มิติ 2 — Verification Reporting** (ทุก Mode รวม Greenfield)
รวบรวมผลทดสอบและการตรวจสอบ:
1. SQL Test Result (จาก `db-test-sql`)
2. Constraint Check Result (NOT NULL, UNIQUE, FK, CHECK)
3. Sample Data Validation (ทดสอบกับ Sample Data จาก `db-create-sample-data`)
4. Rollback Dry-Run Result

> **Mode New greenfield** จะใช้เฉพาะมิติ 2 (Verification-Only) — ไฟล์ยังคงชื่อ `IMPACT_<Module>.md` เพื่อ consistency ของ Companion File Split (Rule 10) แต่ Part 1 จะถูก skip โดยระบุ `Has Impact Section: No` ใน Header

> **เหตุผลที่ skill นี้เป็นเจ้าของทั้ง 2 มิติ:** Verification กับ Impact มักทำคู่กัน (Verify ว่าผลทดสอบรองรับ Impact ที่คาดไว้) — แยกไฟล์จะทำให้ trace ยาก จึงรวมไว้ที่เดียว

## Inherited Global Rules

สืบทอด:
- กฎข้อ 1 (Data-Driven Analysis) — ห้ามเดา ต้อง request DDL/Source Code ก่อนเสมอ
- กฎข้อ 2 (Backward Compatibility) — ถาม Default Value สำหรับ data เก่า
- กฎข้อ 6 (Documentation & Traceability — Open Items Borderline Coverage) — Impact analysis ต้อง include borderline cases ใน Open Items:
  - กระทบ column ที่ใน Future Reserved list (อาจ break ใน DBMS upgrade)
  - กระทบ SP behavior ที่ Spec เดิมไม่ระบุชัด
  - กระทบ trigger chain ที่ไม่มี explicit documentation
  - Edge cases (null, empty, max) ที่ change อาจกระทบ
- **กฎข้อ 10 (Mandatory Companion File Split):** ผลลัพธ์ทั้ง **Impact List + Verification** ต้องเขียนลงไฟล์แยก `IMPACT_<Module>.md` **ห้าม** ฝังในไฟล์ Spec หลัก (`DB_SPEC_<Module>.md`)
- **🏢 Type-Prefix Convention Impact (สืบทอด Rule 4):** เมื่อ Mode Modify มีการ rename column ผ่าน `db-rename-reserved-word` (เช่น `key` → `n_key`) → ต้องวิเคราะห์ Impact เพิ่มเติมในมิติของ rename — ดู Step 9.6 ด้านล่าง

## Trigger Condition (เมื่อไหร่ต้องสร้างไฟล์ `IMPACT_<Module>.md`)

> **กฎสั้นๆ:** **สร้างเสมอ** ทุก Mode — แต่ **content variant** ต่างกันตาม Mode ดังตารางนี้

| Mode | มี Impact Section? | มี Verification Section? | หมายเหตุ |
|------|:-----------------:|:------------------------:|---------|
| **Mode New (greenfield, ไม่มี SQL เดิม)** | ❌ | ✅ | Verification-only file — เก็บผล SQL Test จาก `db-test-sql` |
| **Mode New + legacy SQL (migration)** | ✅ | ✅ | มี Impact ของ SQL เดิมที่ถูกรวม + Verification |
| **Mode Modify** | ✅ | ✅ | Impact + Verification ครบ (default case ของ skill นี้) |
| **Mode Convert** | ✅ | ✅ | Impact ของ Schema change + Verification บน Target DBMS |

**ทำไมต้องสร้างเสมอ:** เพราะ Verification (ผล SQL Test) ต้องมีที่เก็บที่ traceable ทุก Mode — ไม่ใช่แค่ Modify/Convert

### Content Variant Detail

**Variant A — Verification-Only (Mode New greenfield):**
- ไม่มี Part 1 (Impact List)
- มีเฉพาะ Part 2 (Verification): SQL Test Result, Constraint Check, Sample Data Validation, Rollback Dry-Run
- Header `Has Impact Section: No`

**Variant B — Full (Mode Modify / Convert / Mode New + legacy):**
- มีทั้ง Part 1 (Impact List) + Part 2 (Verification) ครบ
- Header `Has Impact Section: Yes`

## Operation Flow

### Step 1: Pre-Run Check (บังคับ)

**ก่อนอื่น:** ระบุ Mode + Variant ที่จะทำ:

| Mode | Variant | Input ที่ต้องการ |
|------|---------|-------------------|
| New (greenfield) | **Verification-Only (Variant A)** | ข้าม Schema/Change input — ไปรอผล `db-test-sql` แล้วจัด Verification section |
| New + legacy SQL | **Full (Variant B)** | ต้องการ Current SQL เดิม + Proposed New Schema |
| Modify | **Full (Variant B)** | ต้องการ Current Schema + Proposed Change |
| Convert | **Full (Variant B)** | ต้องการ Source DDL + Target DBMS info |

**สำหรับ Variant B — ขอ Input จาก SA ครบทุกข้อต่อไปนี้** — ห้ามวิเคราะห์ก่อนได้ครบ:

1. **Current Schema:** DDL ของ Table ที่จะแก้ + Index + Constraint ปัจจุบัน
2. **Proposed Change:** อธิบายการเปลี่ยนแปลง (เพิ่ม column, drop column, เปลี่ยน type, เพิ่ม constraint ฯลฯ)
3. **Source Code Reference** *(ถ้ามี)***:** ระบบ / Repo ที่ใช้ตาราง / column นี้
4. **Module Scope:** Module ไหนเกี่ยวข้องบ้าง

**สำหรับ Variant A (Verification-Only)** — ข้าม Step 2-9 ไปทำ Step 10 (Verification) เลย โดยใช้ผลจาก `db-test-sql` + Sample Data validation จาก `db-create-sample-data`

### Step 2: Identify Direct Schema Impact
รายงานสิ่งที่ถูกกระทบโดยตรง:
- Column ที่ถูก add / drop / rename / type change
- Table ที่ถูก rename / drop
- Constraint ที่ถูก add / drop (PK, FK, Unique, Check, NOT NULL)

### Step 3: Cross-Reference Code Usage
หาก SA แชร์ Source Code:
- Grep หา Table / Column name ใน Source Code
- ระบุไฟล์ / Class / Method / Endpoint ที่อ้างถึง
- จัดลำดับ Priority (Critical = ใช้ใน production traffic / Low = ใช้ใน utility script)

### Step 4: Cross-Reference Stored Procedure / Trigger / View
- ตรวจ SP ทั้งหมดใน DB ที่อ้างถึง object ที่จะเปลี่ยน
- ตรวจ Trigger ที่ผูกกับ Table
- ตรวจ View ที่ Select จาก Column ที่จะ drop / rename
- ตรวจ FK จาก Table อื่นที่อ้างถึง

### Step 5: Identify Index Impact
- Index เดิมที่ผูกกับ Column ที่จะ drop / type change → ต้อง drop / rebuild
- Index ที่อาจต้องเพิ่มเพื่อรองรับ Query ใหม่

### Step 6: Permission & Security Impact
- หาก rename / drop column ที่มี GRANT / DENY → ต้องตั้งใหม่
- หาก Column เป็น sensitive (PII) → ต้อง audit / encryption

### Step 7: Data Migration Plan
- ข้อมูลเก่าที่ต้อง Backfill (เช่น เพิ่ม NOT NULL ต้องมี Default)
- ความเสี่ยง Data Loss (เช่น เปลี่ยน VARCHAR(200) → VARCHAR(100))
- เวลาที่ต้องใช้ (estimate) สำหรับตารางใหญ่
- ต้อง Downtime หรือทำ Online Migration ได้?

### Step 8: Rollback Strategy
- **🚨 Rollback SQL ห้ามฝังใน IMPACT file** — ต้องอยู่ในไฟล์แยก `ROLLBACK_<Module>.sql` (สร้างโดย `db-create-schema`)
- ใน IMPACT file ระบุเฉพาะ:
  - **Link** ไป `ROLLBACK_<Module>.sql`
  - ขั้นตอนการ rollback (text description: drop column, restore data จาก backup ฯลฯ)
  - Data ที่จะหายตอน Rollback (ถ้ามี)
  - Risk + Warning
- ตัวอย่างใน IMPACT:
  ```markdown
  ### Rollback Strategy
  ดูไฟล์ [ROLLBACK_<Module>.sql](./ROLLBACK_<Module>.sql) สำหรับ executable script
  Steps:
  1. Backup database before rollback
  2. Run `ROLLBACK_<Module>.sql`
  3. Verify ...
  ⚠️ Warning: Data Loss — ...
  ```

### Step 9: Risk Rating
ให้คะแนนความเสี่ยงโดยรวม:
- 🟢 Low — Add nullable column, Add new Index
- 🟡 Medium — Add NOT NULL with Default, Rename, Add Constraint
- 🔴 High — Drop column, Change type, Drop Constraint, Drop Index, **Collation change (Rule 12)**

### Step 9.5: Collation Change Impact (🚨 Critical — บังคับเช็คทุกครั้งที่ Change กระทบ text column หรือ schema-level)

หากการเปลี่ยนแปลงกระทบ Collation (เพิ่ม text column ใหม่, เปลี่ยน type จาก non-text → text, ALTER COLLATE, migrate ระบบเดิมที่ใช้ collation ต่างจาก baseline) ต้องวิเคราะห์ครบ 5 มิติ:

| มิติ | สิ่งที่ต้องเช็ค |
|------|-----------------|
| **1. Sort Order** | Binary collation (BIN2) เรียงต่างจาก case-insensitive — Query ที่มี `ORDER BY text_col` ผลลัพธ์อาจสลับ |
| **2. Comparison Behavior** | Case-sensitive comparison (BIN2) → `WHERE name = 'admin'` จะไม่ match `'Admin'` — กระทบ Application logic ที่ assume case-insensitive |
| **3. Index Rebuild** | ทุก Index บน text column ต้อง drop + recreate เมื่อ collation เปลี่ยน — Estimate time ตามขนาด table |
| **4. Duplicate Key Exposure** | UNIQUE constraint ที่เคยอนุญาต `'admin'` + `'Admin'` (case-insensitive) → ใน BIN2 จะแยกเป็น 2 records — แต่ถ้ามี data เก่าที่ duplicate ใน case-insensitive sense → ADD UNIQUE หลัง migration อาจ pass ทั้งคู่ (false safety) |
| **5. Collation Conflict in SP/View** | SP / View ที่ทำ string compare ระหว่าง 2 tables ที่ collation ต่างกัน → error `Cannot resolve the collation conflict` ต้องใส่ `COLLATE` clause explicit |

**Migration Plan สำหรับ Collation Change (ถ้ามี):**

| Step | Action | Estimated Time | Downtime |
|------|--------|----------------|----------|
| 1 | BACKUP ทั้ง DB | depends on size | None |
| 2 | Export → Re-import ด้วย collation ใหม่ (หรือ ALTER DATABASE ... COLLATE) | depends | Downtime สำหรับ ALTER DATABASE |
| 3 | ALTER ทุก table + text column → COLLATE ใหม่ | depends on rows | Downtime |
| 4 | Drop + Recreate ทุก Index บน text column | depends | None (online ถ้า DBMS รองรับ) |
| 5 | Re-run Constraint validation (เช็ค duplicate keys ที่อาจโผล่) | minutes | None |
| 6 | Re-test ทุก SP/View/Trigger ที่มี string compare | depends | None |

**Rollback for Collation Change:** ต้องมี full DB backup ก่อนเสมอ — Collation change มัก irreversible ใน production ใหญ่

### Step 9.6: Reserved Word Rename Impact (บังคับเช็คเมื่อมีการ rename ผ่าน Type-Prefix Convention)

หากการเปลี่ยนแปลงเกี่ยวข้องกับการ rename column/table ที่เป็น Reserved Word (เช่น `key` → `n_key`, `index` → `s_index`) ต้องวิเคราะห์ครบ 5 มิติ:

| มิติ | สิ่งที่ต้องเช็ค |
|------|-----------------|
| **1. Application Code Reference** | Source code ที่อ้างถึงชื่อเดิม (raw SQL strings, ORM model attributes, query builders) — ทุก reference ต้อง update เป็นชื่อใหม่ |
| **2. Stored Procedure / Trigger / View** | SP/Trigger/View ที่ select/insert/update column ชื่อเดิม → ต้อง rewrite + recompile |
| **3. Index / Constraint Name** | Index หรือ FK name ที่ใช้ชื่อ column เดิม (เช่น `idx_key`, `fk_key`) → drop + recreate ด้วยชื่อใหม่ |
| **4. Backward Compatibility Window** | ระบบเก่าที่ยัง deploy ไม่ทัน อาจ query ด้วยชื่อเดิม → consider creating View หรือ Computed Column เป็น alias ชั่วคราว |
| **5. Documentation / API Spec / ETL** | API response field, ETL mapping, BI report — ทุกที่ที่ expose ชื่อ column ต้อง update |

**ตัวอย่าง Impact row ใน Output Format:**

| Original | Renamed | Affected Object | Action Required |
|----------|---------|----------------|-----------------|
| `key` | `n_key` | `OrderRepository.java` (12 references) | Update field name + getter/setter |
| `key` | `n_key` | `sp_get_order_by_key` | Rewrite parameter + body |
| `key` | `n_key` | `idx_sales_key` | Drop + recreate as `idx_sales_n_key` |
| `index` | `s_index` | API `GET /v1/sales/index` | Rename endpoint + update API doc |

**Risk Rating:**
- 🟢 Low — Rename เฉพาะ table/column ที่ไม่มี code reference (new feature)
- 🟡 Medium — Rename กระทบ 1-5 modules, มี alias view รองรับ
- 🔴 High — Rename column ที่ exposed ใน public API หรือใช้ใน ETL พึ่งพา strict schema

### Step 10: Verification Section (บังคับ)
รวม Verification เข้ามาในไฟล์เดียวกับ Impact (ห้ามแยกอีกชั้น) ประกอบด้วย:
- SQL Test Result (อ้างอิงผลจาก `db-test-sql` ถ้ามี)
- Constraint Check Result (NOT NULL, UNIQUE, FK, CHECK)
- Sample Data Validation (ทดสอบ insert/update/delete กับ Sample Data จาก `db-create-sample-data`)
- Rollback Dry-Run Result

### Step 11: Hand-off (เขียนไฟล์แยก)
สร้างไฟล์ `IMPACT_<Module>.md` ที่มี **Impact List + Verification** ครบในไฟล์เดียว แล้วส่ง path กลับ parent (`db-create-spec`) เพื่อ link ใน `DB_SPEC_<Module>.md` ส่วน Related Files

**Back-Link (บังคับ):** หัวไฟล์ `IMPACT_<Module>.md` ต้องมี link กลับ `DB_SPEC_<Module>.md`, `CHANGELOG_<Module>.md`, `SAMPLE_DATA_<Module>.md`, `REVIEW_LOG_<Module>.md`

**ห้าม** ฝัง Impact หรือ Verification ลงในไฟล์ Spec หลัก

## Output Format

> เขียนเป็นไฟล์แยก: `IMPACT_<Module>.md` (รวม Impact + Verification ในไฟล์เดียว)

```markdown
# Impact Analysis & Verification — <Module> — <Change Description>

**Date:** YYYY-MM-DD  |  **Requested by:** <SA name>  |  **Risk:** 🟢 / 🟡 / 🔴
**Mode:** New / Modify / Convert  |  **Has Impact Section:** Yes / No (No = Mode New greenfield)

### Related Files
- **Main Spec:** [DB_SPEC_<Module>.md](./DB_SPEC_<Module>.md)
- **Changelog:** [CHANGELOG_<Module>.md](./CHANGELOG_<Module>.md)
- **Sample Data:** [SAMPLE_DATA_<Module>.md](./SAMPLE_DATA_<Module>.md)
- **Review Log:** [REVIEW_LOG_<Module>.md](./REVIEW_LOG_<Module>.md)

## Part 1 — Impact List

> *(Skip ส่วนนี้ทั้งหมดถ้า Mode New greenfield ไม่มี SQL เดิม — ไปต่อ Part 2 Verification เลย)*

### 1. Proposed Change

<อธิบายการเปลี่ยนแปลงเป็นข้อๆ>

### 2. Direct Schema Impact

| Object | Type | Action | Detail |
|--------|------|--------|--------|
| ORDER.customer_email | Column | ADD | VARCHAR(100) NOT NULL DEFAULT '' |
| ORDER.email_unique | Constraint | ADD | UNIQUE on (customer_email) |

### 3. Code Impact

| File / Module | Reference | Priority | Action Required |
|---------------|-----------|----------|-----------------|
| order-service/OrderRepository.java | INSERT INTO order ... | Critical | เพิ่มการส่ง customer_email |
| order-api/api/v1/order.py | response model | Critical | เพิ่ม field ใน Response |
| reporting-job/daily_report.sql | SELECT * FROM order | Low | ไม่กระทบ (ใช้ *) |

### 4. Stored Procedure / Trigger / View Impact

| Object | Type | Action |
|--------|------|--------|
| sp_create_order | Procedure | ต้องเพิ่ม parameter p_customer_email |
| trg_order_audit | Trigger | ตรวจว่า log customer_email ด้วยไหม |
| v_order_summary | View | ต้อง re-create เพราะ Select * |

### 5. Index Impact

| Index | Action | Reason |
|-------|--------|--------|
| idx_order_email | ADD | รองรับ search by email |

### 6. Permission & Security

- ⚠️ customer_email เป็น PII — ต้องเพิ่ม audit log
- 🔒 ต้อง GRANT SELECT ใหม่ให้ reporting_role

### 7. Data Migration Plan

| Step | Action | Estimated Time | Downtime |
|------|--------|----------------|----------|
| 1 | ALTER TABLE ADD COLUMN (with DEFAULT) | 30 sec | None (Online) |
| 2 | Backfill customer_email จาก customer table | 2 hr (5M rows) | None |
| 3 | ADD UNIQUE Constraint | 5 min | None |

### 8. Rollback Strategy

```sql
-- Rollback Script
ALTER TABLE order DROP CONSTRAINT email_unique;
ALTER TABLE order DROP COLUMN customer_email;
```

⚠️ Data ที่กรอกระหว่าง deploy จะหาย — ให้ backup ก่อน rollback

### 9. Verdict

🟡 **Medium Risk** — ต้องประสานทีม Order Service เพื่อ deploy พร้อมกัน

### 9.5. Collation Change Impact (ถ้ามี — Rule 12)

> Skip section นี้ทั้งหมดถ้า change ไม่กระทบ Collation / text column

| มิติ | Impact Detail | Risk |
|------|---------------|------|
| Sort Order | ORDER BY ของ Query X อาจให้ผลต่างจากเดิม | 🟡 |
| Comparison Behavior | Application code บรรทัด Y assume case-insensitive — ต้องแก้ | 🔴 |
| Index Rebuild | Index `idx_customer_name`, `idx_email` ต้อง drop+recreate (≈30 min) | 🟡 |
| Duplicate Key Exposure | ADD UNIQUE หลัง migration อาจซ่อน duplicate ใน case-insensitive sense | 🔴 |
| Collation Conflict in SP | SP `sp_search_customer` มี join cross-collation → ต้องเติม `COLLATE` clause | 🟡 |

---

## Part 2 — Verification

### 2.1 SQL Test Result

| Test Case | Statement | Expected | Actual | Status |
|-----------|-----------|----------|--------|--------|
| Add column nullable | ALTER TABLE order ADD ... | Success | Success | ✅ |
| Backfill | UPDATE order SET ... | 5,000,000 rows | 5,000,000 rows | ✅ |
| Add UNIQUE | ALTER TABLE order ADD CONSTRAINT ... | No duplicate | No duplicate | ✅ |

### 2.2 Constraint Check

- ✅ NOT NULL: ครบทุก Column
- ✅ UNIQUE (customer_email): ไม่มี duplicate
- ✅ FK customer_id: อ้างอิงถูก
- ✅ CHECK: ผ่านทั้งหมด

### 2.3 Sample Data Validation

ใช้ Sample Data จาก `SAMPLE_DATA_<Module>.md`:
- ✅ Insert ผ่าน 10/10 records
- ✅ Update flow ทดสอบ Backfill ผ่าน
- ✅ Delete + Rollback ผ่าน

### 2.4 Rollback Dry-Run

```sql
-- Dry-run output
ALTER TABLE order DROP CONSTRAINT email_unique;  -- OK
ALTER TABLE order DROP COLUMN customer_email;    -- OK
```

✅ Rollback Script ทดสอบบน staging แล้ว สามารถใช้งานได้
```

## Notes

- ห้ามวิเคราะห์โดยไม่ได้ DDL ของระบบเดิม — ถามจาก SA ก่อน
- หาก Source Code ไม่ได้แชร์มา ให้รายงานเฉพาะ Schema-level + แจ้งว่า Code-level ต้องตรวจเพิ่ม
- รายงานนี้ต้องผ่าน SA Review ก่อน Approve การเปลี่ยนแปลง
- **บังคับ:** Output ต้องเป็นไฟล์ `IMPACT_<Module>.md` แยกออกจาก Spec หลัก (Impact + Verification รวมในไฟล์นี้ไฟล์เดียว)
