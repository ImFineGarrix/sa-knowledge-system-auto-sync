---
name: db-summary-spec
description: "ใช้ skill นี้สำหรับ \"อธิบาย\" ว่า Database Spec ของระบบ / Module หนึ่งคืออะไร โดยอ่านจาก DB Spec ที่มีอยู่แล้ว, DDL Script, หรือเชื่อมต่อกับฐานข้อมูลจริง แล้วเรียบเรียงออกมาเป็นเอกสาร Spec ที่มีโครงสร้างเดียวกับที่ db-create-spec สร้าง (Business Context, ER Diagram, Data Dictionary, Index, Stored Procedure, Constraints) เหมาะกับสถานการณ์ที่ต้องการเข้าใจระบบเดิมก่อน Modify, สร้าง Documentation ย้อนหลัง (Reverse Engineering), หรือ Onboard ทีมใหม่ Trigger ได้แก่ 'อธิบาย spec', 'อธิบาย database', 'describe database', 'describe schema', 'document existing DB', 'reverse engineer', 'what is in this DB', 'อ่าน spec' หรือเมื่อต้องการสรุปสิ่งที่อยู่ในฐานข้อมูลเดิมเป็นเอกสาร"
---

# db-summary-spec

## Role & Goal

Skill นี้ทำงาน **ตรงข้ามกับ `db-create-spec`** — แทนที่จะ **สร้าง** Spec ใหม่, skill นี้ **อ่านและอธิบาย** Spec ที่มีอยู่แล้วออกมาเป็นเอกสาร โดยรับ input ได้ 3 รูปแบบ:

1. **DB Spec File เดิม** (`DB_SPEC_<Module>.md` ที่ทำไว้แล้ว) → reformat / สรุปใหม่
2. **DDL Script / SQL File** → reverse engineer เป็น Spec
3. **Live Database** (ถ้ามี connection / metadata) → query system catalog แล้ว generate Spec

> **สถานะของ skill นี้:** เป็น **utility แยก** (standalone) — ไม่ใช่ sub-skill ของ orchestrator `db-create-spec` และไม่สร้าง flow create/modify/convert
> - **กฎทั่วไป** (DBMS, Language, ER Diagram Format, Null Constraint format, Header style, Collation) ยังคง **สืบทอดจาก `db-create-spec` กฎข้อ 1-12** (ดู Inherited Global Rules ด้านล่าง)
> - **Output Format** เป็น **single file** `DB_SUMMARY_<Module>.md` (ตามที่ผู้ใช้เลือก Option C1 — snapshot อ่านอย่างเดียว ไม่ใช่ active spec)
> - **ไม่บังคับ** สร้าง CHANGELOG / IMPACT / REVIEW_LOG / PACK_INSTALL / SAMPLE_DATA / CONVERT — เพราะเอกสารนี้คือ snapshot ไม่มี Audit Trail / Approval Flow / Test Result ที่ต้อง track

ผลลัพธ์ที่ได้คือเอกสารที่ **ครอบคลุมหัวข้อเดียวกับ `db-create-spec`** (Business Context, ERD, Data Dictionary, Null Constraint, Index, SP) **แต่รวมในไฟล์เดียว** เพื่อให้ SA / Dev / PM อ่านแล้วเข้าใจระบบเดิมได้ทันที

## Use Cases

- 📖 ทำ Documentation ย้อนหลังสำหรับระบบเก่าที่ไม่มี Spec
- 🔍 SA ต้อง Modify ระบบเดิม ต้องการเข้าใจ Schema ก่อน
- 👥 Onboard ทีมใหม่ ให้ดูภาพรวม DB ของระบบ
- 🔄 ก่อนเข้า Mode Convert — ต้องอธิบาย Source DB ก่อน
- 📋 รวบรวม Spec จากหลาย Module เป็น Master Documentation

## Inherited Global Rules

สืบทอดจาก `db-create-spec`:
- **กฎข้อ 1 (Data-Driven)** — ห้ามอธิบายโดยเดา ต้องอ่านจากไฟล์/DDL/DB จริงเท่านั้น
- **กฎข้อ 6 (Description Preservation)** — ห้ามย่อ / แปล / สรุป / reformat description จาก Spec / DDL / Data Dict ต้นฉบับ ใช้ verbatim เป๊ะ
- **กฎข้อ 7 (Language)** — ภาษาไทยเป็นหลัก, technical terms ภาษาอังกฤษ
- **กฎข้อ 8 (DBMS)** — ระบุ DBMS ที่ตรวจพบและ Version
- **กฎข้อ 9 (ER Diagram)** — ER Diagram ต้องเป็น Mermaid `erDiagram` เท่านั้น
- **Null Constraint Format** — Data Dictionary ต้องระบุ Nullable และมีตารางสรุป Null Constraint (รูปแบบตามที่ `db-create-schema` กำหนด — ดู section "Null Constraint Rule" ใน `db-create-schema.md` ไม่ใช่กฎข้อ 11 ของ `db-create-spec` ซึ่งปัจจุบันเป็นเรื่อง Database Conversion)
- **กฎข้อ 10 (File Finalization)** — รับเฉพาะ:
  - Naming convention UPPER_SNAKE (`DB_SUMMARY_<Module>.md`)
  - DB_SPEC Header Fields (adapted สำหรับ snapshot — ดู Output Format)
  - Composite Module Name (ถ้าใช้ — `DB_SUMMARY_CashFlow_Receive.md`)
  - **ไม่บังคับ** ส่วนอื่นของกฎข้อ 10 เพราะไม่ใช่ active spec

## Operation Flow

### Step 1: Input Source Selection
ถาม SA แบบ Multiple Choice:
```
กรุณาเลือก Source ที่ต้องการให้ AI อธิบาย:
  1) DB Spec File เดิม (.md)        — แนบไฟล์ Spec ที่มีอยู่
  2) DDL Script (.sql / .ddl)       — แนบ Source SQL
  3) Database Dump (.sql / .dump)   — แนบ Dump file
  4) Live Database                   — ระบุ DBMS + Connection (read-only)
  5) ผสม (Spec + DDL ประกอบกัน)
```

### Step 2: Module Scope & Split Strategy (บังคับถาม)

**Part A — Scope:** ถามว่าต้องการอธิบาย:
- ทั้ง Database
- เฉพาะ Module / Schema ที่ระบุ
- เฉพาะ Table ที่ระบุ

**Part B — Split Strategy (บังคับถาม Multiple Choice เมื่อ Scope มีมากกว่า 1 Module):**
```
กรุณาเลือกรูปแบบ Output:
  1) Combined — รวมทุก Module ในไฟล์เดียว `DB_SUMMARY_<DBName>.md`
     → เหมาะกับ DB ขนาดเล็ก-กลาง, อ่านภาพรวมง่าย, scroll ครั้งเดียวเห็นหมด

  2) Split per Module — แยกเป็นหลายไฟล์
     `DB_SUMMARY_<ModuleA>.md`, `DB_SUMMARY_<ModuleB>.md`, ...
     → เหมาะกับ DB ใหญ่ที่ Module เป็นอิสระต่อกัน, scroll สั้นลง

  3) Composite (ผสมตามกฎข้อ 10) — แยกตาม Parent Module แต่ใช้ composite name
     `DB_SUMMARY_CashFlow_Receive.md`, `DB_SUMMARY_CashFlow_Pay.md`
     → เหมาะกับ Module ใหญ่ที่มี sub-module ชัดเจน
```

- **ห้าม AI เลือกแทน SA** — ต้องรอคำตอบเสมอ
- หาก Scope = 1 Module → ใช้ Option 1 อัตโนมัติ (ไม่ต้องถาม)
- บันทึก choice ใน Output Header (`Split Strategy: Combined / Split / Composite`)

### Step 3: DBMS Detection
- ถ้า SA ระบุ DBMS → ใช้ตามนั้น
- ถ้าไม่ระบุ → วิเคราะห์จาก Syntax ใน DDL (เช่น `AUTO_INCREMENT` → MySQL, `IDENTITY` → MSSQL) แล้วเสนอผลให้ SA ยืนยัน
- บันทึก Version ของ DBMS ถ้าทราบ

### Step 4: Parse & Extract
อ่านและสกัดข้อมูล:
- **Tables:** ชื่อ + Column + Data Type + Nullable + Default + Comment
- **Constraints:** PK, FK, Unique, Check, NOT NULL
- **Indexes:** ทุก Index รวม PK / FK / Custom
- **Views, Stored Procedures, Functions, Triggers, Sequences**
- **Relationships:** map ผ่าน FK สำหรับสร้าง ERD
- **🏢 Type-Prefix Convention Detection (Company Standard — สืบทอด Rule 4):** Scan ชื่อ column/table ทุกตัวเทียบกับ pattern `s_*`, `n_*`, `d_*`, `t_*`, `f_*`:
  - ✅ **ถ้า match pattern + prefix ตรงกับ data type:** infer ว่าใช้ Company Type-Prefix Convention → ใส่ note ใน DB_SUMMARY ว่า "ใช้ Company Type-Prefix Convention" + อาจ cross-check ใน `references/reserved-word-mapping.csv` ว่าเป็น renamed reserved word เดิมหรือไม่
  - ⚠️ **ถ้า match pattern แต่ prefix ไม่ตรง data type** (เช่น `n_customer_name` ที่เป็น VARCHAR): flag ใน Open Questions ว่า "Prefix ไม่สอดคล้องกับ data type — อาจ rename ผิด หรือ data type เปลี่ยนหลัง rename?"
  - ⚠️ **ถ้าไม่ match pattern แต่ชื่อตรงกับ reserved word ของ DBMS** (เช่น column ชื่อ `key`, `condition`): flag ใน Open Questions ว่า "ระบบเดิมไม่ได้ใช้ Company Type-Prefix Convention — ต้อง rename หรือ accept exception?"
  - ดู skill [`db-rename-reserved-word`](./db-rename-reserved-word.md) สำหรับ Convention reference
- **🚨 Collation (บังคับ — Rule 12):** Detect collation ของระบบเดิมจากแหล่งต่อไปนี้ — ใส่ผลใน Header + Open Questions:
  - **MSSQL:** Query `SELECT DATABASEPROPERTYEX('<DB>', 'Collation')` และ `INFORMATION_SCHEMA.COLUMNS.COLLATION_NAME` ของทุก text column
  - **MySQL/MariaDB:** Query `SHOW VARIABLES LIKE 'collation_database'` และ `INFORMATION_SCHEMA.COLUMNS.COLLATION_NAME`
  - **PostgreSQL:** Query `SELECT datcollate FROM pg_database WHERE datname='<DB>'` + `pg_collation`
  - **Oracle:** Query `NLS_DATABASE_PARAMETERS` (`NLS_SORT`, `NLS_COMP`) + `USER_TAB_COLUMNS.COLLATION`
  - **DDL Only (no live connection):** Grep `COLLATE` clause ใน DDL — หาก DDL ไม่มี `COLLATE` → ระบุว่า "Inherit database default (unknown)" + ใส่ใน Open Questions
  - **Compliance Check (Rule 12 Baseline):** หาก collation ที่ detect ได้ **ไม่ตรง** กับ `Latin1_General_100_BIN2_UTF8` (หรือ DBMS equivalent) → **flag เป็น Critical Open Question** ว่า:
    > "ระบบเดิมใช้ `<collation_X>` ซึ่งไม่ตรงกับ baseline Rule 12. ต้อง migrate ไปใช้ baseline หรือ accept exception (ระบุเหตุผล)?"

### Step 5: Infer Business Context
- ถ้า input เป็น DB Spec เดิม → ดึง Business Context จากไฟล์ตรงๆ
- ถ้า input เป็น DDL ล้วน → AI **ไม่เดา** Business Logic แต่ทำดังนี้:
  - สังเกตจากชื่อ Table / Column / Comment เพื่อ infer Purpose
  - เขียนเป็น "**คาดการณ์เบื้องต้น**" และระบุชัดว่า SA ต้อง verify
  - ถาม SA เพื่อยืนยัน Business Context ถ้าจำเป็น

### Step 6: Generate Description Document
สร้างเอกสารตาม Output Format ด้านล่าง

### Step 7: SA Review & Refinement
- ส่งให้ SA Review
- หากมีจุดที่ AI infer ผิด → SA แก้ไข → AI update เอกสาร
- เมื่อ Approve → Finalize เป็นไฟล์เดียว `DB_SUMMARY_<Module>.md` (UPPER_SNAKE — ตามชื่อไฟล์ใน Output Format) — **ไม่ต้องสร้าง companion files** (CHANGELOG / IMPACT / REVIEW_LOG / etc.) เพราะเป็น snapshot read-only

## Output Format

> **Option C1 — Single File Snapshot** (ที่ SA เลือก): output เป็นไฟล์เดียว `DB_SUMMARY_<Module>.md` รวมทุกหัวข้อ — ไม่แยกเป็นหลาย companion file เพราะเป็น snapshot อ่านอย่างเดียว ไม่มี audit trail / approval flow ที่ต้อง track

ชื่อไฟล์:
- **1 Module:** `DB_SUMMARY_<Module>.md`
- **Combined (Option 1 ใน Step 2B):** `DB_SUMMARY_<DBName>.md`
- **Split (Option 2):** `DB_SUMMARY_<ModuleA>.md`, `DB_SUMMARY_<ModuleB>.md`, ...
- **Composite (Option 3):** `DB_SUMMARY_<Parent>_<Sub>.md` เช่น `DB_SUMMARY_CashFlow_Receive.md`

โครงสร้างเนื้อหา:

```markdown
# DB Summary (Reverse Engineered) — <Module Name>

## Header

| Field | Value |
|-------|-------|
| **Module** | <Module Name> |
| **Source** | DDL Script / DB Spec File / Live DB |
| **DBMS** | <DBMS> v<Version> |
| **Collation (Detected)** | <e.g. SQL_Latin1_General_CP1_CI_AS> — ✅ matches baseline / ⚠️ deviates from Rule 12 baseline |
| **Generated by** | db-summary-spec |
| **Generated Date** | YYYY-MM-DD |
| **SA (Generator)** | <name> |
| **Split Strategy** | Combined / Split / Composite |
| **Status** | ⚠️ Auto-generated — SA Verify Required |
| **Companion Files** | (ไม่บังคับสร้าง — เพราะเป็น snapshot) |

---

## 1. Business Context

> *(หาก input เป็น Spec เดิม)* ดึงจาก Spec ต้นฉบับ:  
> <ข้อความ Business Context จากไฟล์เดิม>
>
> *(หาก input เป็น DDL ล้วน)* **คาดการณ์เบื้องต้นจาก Schema** *(SA โปรด verify)*:  
> ระบบนี้น่าจะเป็น <Module type> ที่จัดการ <inferred purpose> เนื่องจากพบ Table หลัก <main tables> และมีความสัมพันธ์ที่บ่งชี้ <observation>

## 2. Module Scope

- **Module:** <ชื่อ Module>
- **Tables in scope:** <รายการ Table>
- **Excluded:** <Table ที่ไม่อยู่ใน scope>

## 3. Entity Relationship

```mermaid
erDiagram
    %% สร้างจาก FK ที่พบใน DDL
    CUSTOMER ||--o{ ORDER : places
    ORDER ||--|{ ORDER_ITEM : contains
    ...
```

## 4. Technical Spec

### 4.1 Tables (Data Dictionary)

#### Table: `customer`
**Purpose:** *(infer หรือ ดึงจาก Comment)*

| Column | Data Type | PK | FK | Nullable | Default | Description |
|--------|-----------|-----|-----|----------|---------|-------------|
| customer_id | INT | ✓ | | NO | AUTO_INCREMENT | รหัสลูกค้า |
| customer_name | VARCHAR(100) | | | NO | - | ชื่อ |
| email | VARCHAR(255) | | | YES | NULL | email (Unique) |
| ... | ... | | | | | |

#### Table: `order`
*(ทำซ้ำสำหรับทุก Table)*

### 4.2 Null Constraint Summary (รูปแบบจาก `db-create-schema` — Null Constraint Rule)

| Table | Column | Nullable | Default | Business Reason *(infer)* |
|-------|--------|----------|---------|---------------------------|
| customer | customer_id | NO | AUTO | Primary Key |
| customer | customer_name | NO | - | คาดว่าจำเป็นต่อการ trace |
| order | order_date | NO | CURRENT_DATE | คาดว่าใช้ระบุวันที่สั่ง |
| ... | ... | ... | ... | *(? SA โปรดยืนยัน)* |

### 4.3 Indexes

| Index Name | Table | Columns | Type | Purpose *(infer)* |
|-----------|-------|---------|------|-------------------|
| PRIMARY | customer | (customer_id) | PK | - |
| idx_email | customer | (email) | Unique | ค้นหาด้วย email |
| ... | ... | ... | ... | ... |

### 4.4 Stored Procedures / Functions / Triggers

| Object | Type | Parameters | Purpose *(infer)* |
|--------|------|------------|-------------------|
| sp_create_order | Procedure | p_customer_id INT, p_total DECIMAL | สร้าง Order ใหม่ |
| trg_order_audit | Trigger | AFTER INSERT ON order | คาดว่า log audit |
| ... | ... | ... | ... |

### 4.5 Views / Sequences / Other Objects

*(ถ้ามี — ระบุประเภทตาม DBMS เช่น Oracle Sequence, DB2 Alias, PostgreSQL Materialized View)*

## 5. Relationships Detail

| From Table | FK Column | To Table | On Delete | On Update |
|-----------|-----------|----------|-----------|-----------|
| order | customer_id | customer | RESTRICT | CASCADE |
| order_item | order_id | order | CASCADE | CASCADE |
| ... | ... | ... | ... | ... |

## 6. Open Questions (สำหรับ SA Verify — Rule 6 Borderline Coverage)

> **บังคับครอบคลุม borderline cases:** ไม่ใช่แค่ strict ambiguity แต่รวมทุก case ที่ AI ไม่ confident 100%:
> - Column name ที่อยู่ใน Future Reserved Keywords (อาจ break ใน DBMS upgrade)
> - Description ว่างใน Data Dict — AI infer ได้แต่ไม่แน่ใจ
> - Data type ที่อาจ map prefix หลายแบบ (เช่น TINYINT — `n_` หรือ `f_`?)
> - SP behavior ที่ Spec เดิมไม่ระบุชัด
> - Edge cases (null, empty, max) ที่ schema ไม่มี explicit constraint

รายการประเด็นที่ AI ไม่สามารถระบุได้แน่นอน ต้องการให้ SA ยืนยัน:

1. ⚠️ Column `customer.status` มีค่าอะไรบ้าง? (ไม่พบ CHECK constraint หรือ enum)
2. ⚠️ Trigger `trg_order_audit` log ไปที่ไหน? (ไม่พบ table audit ในระบบ)
3. ⚠️ Field `order.flag` ใช้ทำอะไร? (ชื่อคลุมเครือ)
4. ⚠️ Column `order.condition` อยู่ใน MySQL Reserved Keywords — ไม่ rename ในระบบเดิม (ใช้ escape backtick) — ต้อง migrate ไป `s_condition` ตาม company convention?
5. ⚠️ Column `temp.priority` ตอนนี้ไม่ reserved แต่อยู่ใน MSSQL Future Reserved list — accept risk หรือ rename ก่อน?

## 7. Companion Documents (ไม่บังคับ)

> เอกสารนี้คือ **snapshot** ไม่บังคับสร้างไฟล์เสริม:

- ❌ **CHANGELOG** — ไม่บังคับ (snapshot ไม่มีการเปลี่ยนแปลงต่อ ถ้าจะ migrate เป็น active spec ค่อยใช้ `db-create-spec` Mode Modify)
- ❌ **IMPACT** — ไม่บังคับ (ไม่มีการเปลี่ยน schema)
- ❌ **REVIEW_LOG** — ไม่บังคับ (ไม่มี formal approval flow)
- ❌ **PACK_INSTALL** — ไม่บังคับ (ไม่ deploy)
- ❌ **SAMPLE_DATA** — ไม่บังคับ (ถ้าต้องการ extract live data ค่อยเรียก `db-create-sample-data` แยก)
- ❌ **STORED_PROCEDURE** — ไม่บังคับ (Source SP อยู่ใน DB จริง ไม่ต้อง dump ออก)
- ❌ **CONVERT** — ไม่บังคับ (ไม่ใช่ flow Convert)
- ✅ **Source file** — เก็บ DDL/Spec ต้นฉบับที่ใช้สร้าง snapshot ไว้ใกล้กัน (ถ้ามี)

> **ถ้า SA ต้องการ Migrate snapshot นี้เป็น active spec:** ให้เรียก `/db-create-spec` Mode Modify (หรือ New) แล้ว feed `DB_SUMMARY_<Module>.md` เข้าไปเป็น Input
```

## Notes

- เอกสารที่ skill นี้ Generate เป็น **Reverse Engineered Snapshot** — ความถูกต้องของส่วน Business Context และ Purpose ขึ้นกับการ verify ของ SA
- AI ต้อง**ระบุชัดเจน** ว่าส่วนไหนคือ **fact จาก DDL** (Schema, Column, Type) และส่วนไหนคือ **inference** (Business Purpose) — ใช้ marker เช่น *(infer)* / *(SA verify)*
- หาก input เป็น Spec File เดิม → ไม่ต้อง infer ให้ใช้ข้อมูลจากไฟล์เดิมตรงๆ
- หาก DB ใหญ่มาก → **ให้ถาม SA ใน Step 2B** ว่าจะ Combined / Split / Composite (ห้ามตัดสินใจเอง — ดู Step 2)
- skill นี้สามารถใช้เป็น **input** ให้ `db-impact-change-analyst` หรือ Mode Convert ของ `db-create-spec` ได้