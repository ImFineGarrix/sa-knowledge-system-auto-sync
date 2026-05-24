---
name: db-create-schema
description: "ใช้ skill นี้สำหรับสร้าง Database Schema (DDL) ออกมาเป็น SQL Script ส่งให้ Developer นำไปใช้ Develop ต่อ โดย AI จะถาม DBMS แบบ Choice-Based, ตรวจ Reserved Words, รองรับ Case Style (camelCase, snake_case, PascalCase), สร้าง Data Dictionary พร้อม Null Constraint Table แยกออกมา และรวบรวม SQL เป็น Pack Install ได้ Input รับได้ทั้ง text spec หรือ SQL เดิม → SA review และ input final SQL กลับมาให้ AI เก็บลง spec Trigger ได้แก่ 'create schema', 'create table', 'DDL', 'data dictionary', 'pack install', 'ALTER TABLE', 'schema design'"
---

# db-create-schema

## Role & Goal

Skill นี้สร้าง **Database Schema (DDL)** ออกมาเป็น SQL Script พร้อม Data Dictionary และ Null Constraint Table ส่งให้ Developer นำไปใช้ Develop ต่อ — โดยรับ input ได้ทั้งจาก:
- Text spec / Business Requirement
- SQL Script เดิม (ให้ AI ปรับ / แปลง / เพิ่ม Index)
- Data Dictionary ที่ระบุชื่อ Table / Column มาแล้ว

SA Review ผลลัพธ์ และส่ง Final SQL กลับมาให้ AI เก็บลง Spec

## Inherited Global Rules

สืบทอดจาก `db-create-spec` (กฎข้อ 1-12) โดยกฎที่บังคับใช้กับ skill นี้โดยตรง:

### Pre-Run Check (บังคับทุกครั้ง)

ก่อนเริ่มทำงาน skill นี้ **ต้องถาม 5 หัวข้อแบบ Multiple Choice เสมอ** ห้ามเดาหรือใช้ค่าจาก session ก่อนหน้าโดยไม่ยืนยัน:

**1. DBMS Type:**
```
กรุณาเลือกประเภท Database Engine ที่ต้องการ:
  1) MySQL
  2) MSSQL (SQL Server)
  3) PostgreSQL
  4) Oracle
  5) Informix
  6) DB2
  7) MariaDB
  8) SQLite
  9) อื่นๆ (โปรดระบุ)
```

**2. DBMS Version:** (เพื่อตัดสินใจ Feature เช่น JSON Type, CTE, Window Function)

**3. Case Style (🚨 บังคับ — Company Standard ตาม Rule 4):**
```
กรุณาเลือก Case Style สำหรับชื่อ Table / Column / Index / SP / Variable:
  1) snake_case        — lowercase + underscore separator (เช่น customer_id, cash_movement, order_idx1)
  2) lowercase         — lowercase ติดกัน ไม่มี separator (เช่น customerid, tradedate, orderno)
```

> 🚨 **ปัจจุบัน Company Standard บังคับเหลือแค่ 2 options** — **ห้ามใช้** PascalCase, camelCase, UPPER_SNAKE_CASE เด็ดขาด (ดู Rule 4 — Case Style Lock)
> ⚠️ **Preserve Exact Names Exception:** Case Style นี้ใช้เฉพาะกรณีที่ SA **ไม่ได้** ระบุชื่อมาใน Data Dict — หาก Data Dict มีชื่อระบุไว้แล้วและไม่ตรง pattern → ใช้ตามต้นฉบับ + flag ใน Open Items ว่า "Grandfathered — pre-existing names"

**4. Column Ordering Preference:** (ถามทุกครั้งก่อน Generate DDL)
```
กรุณาเลือกวิธีการเรียงลำดับ Column ใน CREATE TABLE:
  1) ตามลำดับใน Data Dict ที่ระบุมา                    (default — รักษา order เดิม)
  2) เรียงตามแนะนำ: PK → FK → Business Columns → Audit  (เช่น created_at, updated_at อยู่ท้าย)
  3) อื่นๆ (โปรดระบุ)
```
- หาก SA ไม่ตอบ → ใช้ตัวเลือก (1) เป็น default และระบุไว้ใน Output ว่า "Column order: ตาม Data Dict"
- ถ้าเลือก (2) AI ต้อง Generate ทั้งใน DDL Script **และ** Data Dictionary Table ให้เรียงตามแบบ PK → FK → ... ให้สอดคล้องกัน
- หาก Input เป็น SQL เดิม (ไม่มี Data Dict) → ใช้ลำดับใน SQL เดิมเป็น default

**5. 🚨 Collation + Text Type Confirmation (Critical — บังคับ — สืบทอด Rule 12):**

```
กรุณายืนยัน Text Type + Collation ที่จะใช้ (auto-suggest ตาม DBMS):
  1) MSSQL    → NVARCHAR + Latin1_General_100_BIN2_UTF8  (Company Default — บังคับ NVARCHAR)
  2) MySQL    → VARCHAR + utf8mb4_bin                    (charset utf8mb4)
  3) MariaDB  → VARCHAR + utf8mb4_bin                    (charset utf8mb4)
  4) PostgreSQL → VARCHAR + C collation                  (encoding UTF8)
  5) Oracle   → NVARCHAR2 + BINARY                       (NLS_COMP=BINARY, AL32UTF8)
  6) DB2      → VARCHAR + IDENTITY collation             (UTF-8 codeset)
  7) SQLite   → TEXT + BINARY                            (default)
  8) Informix → NVARCHAR + en_US.utf8                    (locale en_US.utf8)
  9) อื่นๆ (โปรดระบุ + ทำ Explicit Skip Confirmation ตาม Rule 0)
```

- **🚨 MSSQL บังคับ NVARCHAR (Company Standard ตาม Rule 12):**
  - ห้าม `VARCHAR` ใน MSSQL — text column ทุกตัวต้องเป็น `NVARCHAR`
  - เหตุผล: 100% Unicode safety + ทำงานทุก MSSQL version 2008+
  - ใช้ Collation `Latin1_General_100_BIN2_UTF8` กับ NVARCHAR — collation ให้ behavior binary + case/accent sensitive (storage ยังเป็น UTF-16 ตามปกติของ NVARCHAR)
- **Default Behavior:** AI auto-suggest ตาม DBMS ใน Pre-Run Check ข้อ 1 — SA ยืนยันหรือเปลี่ยน
- **Apply Level (บังคับทั้ง 3 ระดับ):**
  - **Database Level** — `CREATE DATABASE ... COLLATE ...` หรือ encoding/charset clause ของ DBMS
  - **Table Level** — `CREATE TABLE ... COLLATE ...` (ถ้า DBMS รองรับ — MSSQL/MySQL/MariaDB)
  - **Column Level** — ทุก text column ต้องมี `COLLATE` clause inline + ใช้ NVARCHAR (MSSQL) ตามที่กำหนด
- **Exception (Critical):** หาก SA เลือก (9) อื่นๆ หรือต้องการใช้ VARCHAR ใน MSSQL → AI ต้องถาม Explicit Skip Confirmation ตาม Rule 0 + บันทึก reason ใน `REVIEW_LOG_<Module>.md` + ระบุ risk ที่เกิดขึ้น
- **Output Header:** บันทึก `Text Type: NVARCHAR` + `Collation: <ค่าที่เลือก>` ใน DB_SPEC Header (ตาม Rule 10 Header Fields) เพื่อ Audit ภายหลัง

### Naming Rules

- **Preserve Exact Names from Data Dict (กฎสูงสุด):** หาก SA ระบุชื่อ Table / Column มาใน Data Dict / Spec / SQL เดิม ให้ใช้ชื่อนั้น **เป๊ะตัวอักษรต่อตัวอักษร** — รวมทั้ง `_` (underscore), ตัวเลข, ตัวพิมพ์ใหญ่/เล็ก ห้ามปรับให้เข้ากับ Case Style ที่เลือกไว้ใน Pre-Run Check
- **Preserve Exact Descriptions from Data Dict (บังคับ — สืบทอด Rule 6):** ห้ามย่อ / แปล / สรุป / reformat **description** ของ Table หรือ Column ใช้ verbatim จาก Data Dict / Main Page เป๊ะ — Technical annotations (Business Key, Surrogate PK, normalized type, ...) **ต้องใส่ใน column แยก** ในตาราง Data Dict ห้ามทับของเดิม (ดูตัวอย่างใน `db-create-spec.md` Rule 6 — Description Preservation)
  - ตัวอย่าง: ถ้า Data Dict ระบุ `customer_account` ห้าม Generate เป็น `CustomerAccount`, `customeraccount`, หรือ `customer account`
  - ตัวอย่าง: ถ้า Data Dict ระบุ `m_user_profile` ห้ามตัด prefix `m_` ออก หรือเปลี่ยนเป็น `UserProfile`
  - หากพบความขัดแย้งระหว่างชื่อใน Data Dict กับ Case Style ที่เลือก → **แจ้ง SA** และให้ SA Confirm ว่าจะใช้ชื่อจาก Data Dict (default) หรือจะให้ปรับเป็น Case Style
  - Case Style ที่ถามใน Pre-Run Check ใช้เฉพาะกรณีที่ AI ต้อง **ตั้งชื่อใหม่เอง** (ไม่มีระบุใน Data Dict) เท่านั้น เช่น Junction Table, Lookup Table ที่ Spec ไม่ได้บอก
- **No Reserved Words:** ตรวจชื่อ Table / Column ทุกตัวกับ Reserved Words List ของ DBMS ที่เลือก (ดู Section "Reserved Words Check Flow" ด้านล่าง)
- **Consistency:** Case Style ต้องเหมือนกันทั้ง Schema (เฉพาะชื่อที่ AI ตั้งใหม่)
- **Meaningful Names:** ห้ามชื่อคลุมเครือ (`data1`, `flag`, `tmp`) ต้องสื่อ Business Context

> **หมายเหตุ — ความสัมพันธ์กับ Pre-Run Check item 3 (Case Style):**
> - Case Style ที่ SA เลือกใน Pre-Run Check item 3 ใช้ **เฉพาะกรณีที่ AI ต้องตั้งชื่อใหม่เอง** (เช่น Junction Table, Lookup Table ที่ Spec ไม่ได้บอก)
> - หากชื่อมีอยู่แล้วใน Data Dict / Spec / SQL เดิม → **"Preserve Exact Names from Data Dict" override Case Style เสมอ**
> - ตารางอ้างอิงรูปแบบ:
>
>   | รูปแบบ      | ชื่อเรียก     | การใช้งานที่พบบ่อย                                                |
>   |-------------|---------------|--------------------------------------------------------------------|
>   | snake_case  | Snake Case    | ชื่อ Column และ Table ใน Database (มาตรฐานทั่วไป)                  |
>   | PascalCase  | Pascal Case   | ชื่อ Table หรือชื่อ Model ใน Code (เช่น C#, Java)                  |
>   | camelCase   | Camel Case    | ชื่อตัวแปรใน Code หรือ Key ในไฟล์ JSON                              |
>   | UPPER_SNAKE | Upper Snake   | ชื่อ Table/Column ใน Oracle (มาตรฐาน Oracle)                       |

### Reserved Words Check Flow (บังคับ — Exhaustive Scan → Warn → Ask 4 Options → Confirm → Apply → Audit CSV)

ทุกครั้งที่ Generate Schema ต้องตรวจ Reserved Words ของ DBMS ที่เลือกตามขั้นตอนนี้ — **ห้ามข้ามขั้นตอนการถาม User เด็ดขาด** แม้ว่า:
- session ก่อนหน้าจะเคยตอบไว้แล้ว
- AI จะคิดว่ามี default ที่ดีกว่า
- มีหลาย Reserved Words ใน Schema เดียวกัน (ต้องถามทุกชื่อทีละตัว ห้ามรวบหรือเดาแทน)
- User สั่งให้ "Generate เลย" / "ไม่ต้องถาม" → ยังคงต้องถาม Reserved Words นี้ก่อนเสมอ (Mandatory Gate)

> **🚨 Bracket Forbidden as Silent Workaround (Rule 4):** ห้าม AI silent escape ด้วย `[name]` / `` `name` `` / `"name"` โดยไม่ผ่าน Option (5) — ถ้าจะใช้ bracket ต้อง explicit confirm + บันทึก risk
>
> **🚨 Sub-Skill Trigger (Rule 4):** Scan + Rename ทั้งหมดต้องเรียก skill [`db-rename-reserved-word`](./db-rename-reserved-word.md) — ห้าม orchestrator/schema skill inline ทำเอง

1. **🚨 Exhaustive Multi-Source Scan (บังคับ 4 sources ตามลำดับ — Rule 4):** เรียก `db-rename-reserved-word` ส่ง DBMS + ชื่อ Column/Table:
   1. **Company `references/reserved-word-mapping.csv`** — ถ้าเจอ ใช้ค่า `renamed` ตรงๆ
   2. **DBMS T-SQL Reserved Keywords** (อยู่ใน `db-rename-reserved-word.md` reference table)
   3. **ODBC Reserved Keywords** — portability check
   4. **Future Reserved Keywords** — ที่ DBMS ระบุว่าจะกลายเป็น reserved
   - **ห้าม skip source ใด** — ต้องเช็คครบทั้ง 4 source แม้ source 1 เจอแล้ว
   - **Borderline (เจอใน Future Reserved):** flag ใน Open Items + SA decide (ไม่ใช่ strict violation)

2. **Warn:** หากพบ → แจ้งเตือนแบบชัดเจน ระบุ:
   - ชื่อไหนเป็น Reserved Word
   - **อยู่ใน source ไหน** (CSV/T-SQL/ODBC/Future) — สำคัญสำหรับ severity
   - Table/Column ที่กระทบ
   - ปัญหา (Query Error, ต้องใส่ bracket, อาจกระทบ ORM)

3. **Ask User — บังคับเสนอ 4 ตัวเลือกตาม Pattern คงที่นี้เสมอ (ห้ามเปลี่ยน ห้ามเพิ่ม ห้ามลด):**

   | ตัวเลือก | รูปแบบ                                          | คำอธิบาย                                                                |
   |----------|-------------------------------------------------|--------------------------------------------------------------------------|
   | **(1)**  | `<prefix>_<ReservedWord>` (Type-Prefix Convention) | 🏢 **Company Standard** — เรียก skill `db-rename-reserved-word` เพื่อ apply Type-Prefix Convention |
   | **(2)**  | `<TableName><ReservedWord>`                     | ใช้ชื่อ Table มาขึ้นต้น + Reserved Word จาก Data Dict เดิม (Concatenation) |
   | **(3)**  | `<AI-Suggested-Name>`                           | ชื่อที่ AI วิเคราะห์จากบริบท Business / Domain แล้วเสนอเอง 1 ชื่อ          |
   | **(4)**  | `<User-Defined>` — ให้ User เป็นคนพิมพ์ชื่อเอง  | เปิดช่องให้ SA ระบุชื่อที่ต้องการเอง                                       |

   **กฎการสร้างตัวเลือก (1) `<prefix>_<ReservedWord>` (Type-Prefix Convention — Company Default):**
   - **เรียก skill `db-rename-reserved-word`** ส่ง context: `dbms`, `original`, `context (table/column)`, `data_type`
   - Skill จะ lookup ใน `references/reserved-word-mapping.csv` ก่อน — ถ้าเจอ ใช้ค่าจาก CSV
   - ถ้าไม่เจอใน CSV → Skill จะ auto-detect prefix จาก data type (s_, n_, d_, t_, f_)
   - ผลลัพธ์: ชื่อใหม่รูปแบบ `<prefix>_<original>` เช่น `n_key`, `s_condition`, `d_utc_date`
   - **เป็น company default** — แนะนำ SA ให้เลือกข้อนี้เป็นอันดับแรก
   - ⚠️ **Exception ของ Case Style Preference:** Type-Prefix renamed ใช้ **`snake_case + lowercase` เสมอ** ไม่ว่า project จะเลือก Case Style แบบใดใน Pre-Run Check ข้อ 3 (PascalCase / camelCase / UPPER_SNAKE) — ทำให้ใน project ที่ใช้ PascalCase อาจเห็น naming mixed style: `CustomerName`, `OrderDate` ปนกับ `n_key`, `s_index` — ถือเป็น acceptable convention เพราะ Type-Prefix เป็น company standard ที่ override case preference
   - ดู [Type-Prefix Convention](./db-rename-reserved-word.md#type-prefix-convention-single-source-of-truth) ใน `db-rename-reserved-word.md`

   **กฎการสร้างตัวเลือก (2) `<TableName><ReservedWord>`:**
   - ใช้ชื่อ Table ตามที่อยู่ใน Data Dict / DDL (Preserve Exact Names) — ห้ามตัด prefix, ห้ามแปลง case
   - ใช้ Reserved Word ตามตัวอักษรเดิมจาก Data Dict
   - การต่อชื่อต้องเป็นไปตาม Case Style ที่ SA เลือกใน Pre-Run Check:
     - `PascalCase`       → `CashMovementType`        (ติดกันไม่มี separator)
     - `snake_case`       → `cash_movement_type`      (ใช้ `_` คั่น, lowercase)
     - `camelCase`        → `cashMovementType`        (ตัวแรกของ word แรก lowercase)
     - `UPPER_SNAKE_CASE` → `CASH_MOVEMENT_TYPE`      (ใช้ `_` คั่น, uppercase)

   **กฎการสร้างตัวเลือก (3) `<AI-Suggested-Name>`:**
   - AI วิเคราะห์ Business Context และเสนอ **1 ชื่อ** ที่สื่อความหมายตรงที่สุด (ต้องเป็นชื่อที่ **ต่างจากตัวเลือก (1) และ (2)** — ห้ามซ้ำ pattern)
   - เช่น Prefix/Suffix ตามบริบท (`app_user`, `order_main`), เปลี่ยนคำพ้อง (`group` → `team`), หรือชื่อตาม Domain (`Type` → `TransactionCategory`)
   - ต้องวงเล็บอธิบายเหตุผลสั้นๆ ว่าเสนอชื่อนี้เพราะอะไร

   **กฎการสร้างตัวเลือก (4) `<User-Defined>`:**
   - ระบุไว้เป็นข้อความ "ให้คุณเป็นคนเขียนชื่อเอง — โปรดพิมพ์ชื่อที่ต้องการ"
   - เมื่อ User เลือกข้อนี้ → **หยุดรอ** ให้ User พิมพ์ชื่อกลับมา
   - เมื่อได้ชื่อใหม่จาก User → ต้อง Validate ว่าชื่อใหม่:
     - ไม่ใช่ Reserved Word ใน DBMS เดิม (ถ้าเป็น → วน Flow ใหม่ตั้งแต่ Warn)
     - ไม่ขัดกับ Naming Rules อื่น (ความยาว, อักขระพิเศษ ฯลฯ)

   > 🚨 **ตัวเลือกที่ 5: Bracket + Documented Risk (แสดง explicit — ไม่ silent — Rule 4):** หาก User เลือกใช้ชื่อเดิม:
   > - AI **ต้อง AskUserQuestion** ก่อนทุกครั้ง — ห้าม silent escape
   > - SA ต้อง confirm explicit: "ใช้ bracket + รับ risk"
   > - AI ต้อง Escape ด้วย Quote ที่เหมาะกับ DBMS (`[name]` MSSQL / `` `name` `` MySQL / `"name"` PostgreSQL/Oracle) **ทุกที่ใน DDL**
   > - **บังคับบันทึก** ใน:
   >   - Output Audit Trail: "User accepted risk — name escaped"
   >   - REVIEW_LOG: reason ที่ SA เลือก option นี้ + risk assessment
   >   - Open Items section: flag เป็น "Bracket workaround — Dev/IMP ต้องระวัง"

4. **Confirm:** **หยุดรอ** ให้ User ตอบกลับ — **ห้าม Generate DDL** จนกว่า User จะเลือก / พิมพ์ชื่อใหม่ครบทุก Reserved Word ที่พบ

5. **Apply:** เมื่อ User Confirm แล้ว ให้ใช้ชื่อใหม่นั้นทั้ง DDL, Data Dictionary, Null Constraint Table, และ Index Suggestion ให้สอดคล้องกันหมด พร้อมบันทึก Rename Map ไว้ใน Output

6. **🚨 Audit CSV (บังคับ — Rule 4 Append-Only):** ทุก rename event (รวม Option (5) bracket) ต้อง **append row** ใน `references/reserved-word-mapping.csv`:
   - ผ่าน Pre-Append Validation ของ `db-rename-reserved-word` (Prefix Existence / DBMS Validity / Duplicate / Format)
   - CSV เป็น append-only audit log — ห้าม remove rows
   - **ห้าม skip CSV append** — เป็น compliance violation
   - Option (5) bracket ต้อง append row พิเศษระบุ `prefix=ESCAPE` หรือ flag ใน `note` ว่า "Bracket workaround"

**ตัวอย่างรูปแบบการถาม (บังคับใช้รูปแบบนี้):**

```
⚠️ พบ Reserved Word ใน <DBMS> v<Version> — ต้องเปลี่ยนชื่อก่อน Generate DDL ครับ

[1/N] Table `Sales` → Column `key` (Data Type: INT)
      Reserved In: SQL Server

      กรุณาเลือกชื่อใหม่:
        (1) n_key                    ← 🏢 Type-Prefix Convention (Company Standard, Recommended)
                                        n_ = number type (จาก INT) → n_<original>
        (2) Saleskey                  ← <TableName><ReservedWord> Concat ตาม Case Style
        (3) primary_key_id            ← AI Suggested (สื่อความหมายชัดว่าเป็น PK)
        (4) ให้คุณเป็นคนเขียนชื่อเอง  ← พิมพ์ชื่อที่ต้องการมาเลยครับ

      [ถ้ายืนยันใช้ `key` เดิม → AI จะ Escape เป็น [key] ทุกที่ และบันทึก risk ไว้]

กรุณาตอบเป็นเลข (1)/(2)/(3) หรือพิมพ์ชื่อเอง สำหรับทุก Reserved Word ที่พบครับ
```

**กรณีพบหลาย Reserved Words ในงานเดียว:**
- ต้องถามทีละตัว (numbering `[1/N]`, `[2/N]`, ...) หรือถามรวมในข้อความเดียวแต่แยก Section ชัดเจน
- ห้าม Generate DDL จนกว่าจะได้คำตอบครบทุก Reserved Word

**Audit Trail (บันทึกใน Output ทุกครั้ง):**

| Original | Table        | Reserved In  | Option Chosen        | Final Name        | Confirmed By User |
|----------|--------------|--------------|----------------------|-------------------|--------------------|
| key      | Sales        | MSSQL        | (1) Type-Prefix      | n_key             | ✅ Yes             |
| index    | (Table name) | MySQL        | (1) Type-Prefix      | s_index           | ✅ Yes             |
| Type     | CashMovement | MSSQL        | (2) Concat           | CashMovementType  | ✅ Yes             |
| order    | Sales        | SQL Standard | (4) Custom           | sales_order       | ✅ Yes             |
| user     | Login        | MSSQL        | (5) Escape           | [user]            | ⚠️ Risk Accepted   |

### Null Constraint Rule (`db-create-schema` owns this rule)

- Data Dictionary ทุกตารางต้องมีคอลัมน์ `Nullable` (Yes/No)
- ต้องสร้าง **ตารางสรุป Null Constraint** เพิ่ม 1 ตาราง: `| Table | Column | Nullable | Default | Business Reason |`
- Field NOT NULL ต้องระบุ **Business Reason**
- Field NOT NULL ที่จะเพิ่มในตารางที่มีข้อมูลเก่า ต้องระบุ **Default Value** สำหรับ Migration

## Operation Flow

1. **Pre-Run Check:** ถาม DBMS + Version + Case Style + Column Ordering + **Collation** ตามข้างต้น (Multiple Choice ทั้ง 5 ข้อ — Collation บังคับตาม Rule 12)
2. **Input Type Detection:** ถาม SA ว่า input เป็น
   - (a) Text Spec / Business Requirement → AI ออกแบบใหม่ (AI ตั้งชื่อเอง ใช้ Case Style)
   - (b) Data Dictionary ที่ระบุชื่อ Table/Column แล้ว → ใช้ชื่อเป๊ะตามที่ระบุ (Preserve Exact Names)
   - (c) SQL Script เดิม → AI parse แล้วปรับปรุง / เพิ่ม Index / แปลง dialect (รักษาชื่อเดิม)
3. **Reserved Words Check:** ตรวจชื่อทั้งหมดตาม Reserved Words Check Flow → ถ้าพบ ให้ Warn + Ask 4 Options + รอ Confirm **ก่อน** จะไป Step ถัดไป
4. **Schema Design:**
   - สร้างรายการ Table + Column + Data Type + PK/FK + Default + Comment
   - ใช้ Column Ordering ตามที่ SA เลือกใน Pre-Run Check
   - ระบุ Null/NotNull พร้อม Business Reason
5. **Data Dictionary Generation:** ตารางรายละเอียดทุก Column (เรียงตาม Column Ordering Preference)
6. **Null Constraint Summary Table:** แยกตาราง `| Table | Column | Nullable | Default | Business Reason |`
7. **Index Suggestion (Inline):** แนะนำ Index พื้นฐานติดมากับ CREATE TABLE (PK, FK Index, Unique Constraint) — ส่วน Index ขั้นสูงให้ส่งไปที่ `db-create-index`
8. **DDL Generation:** Generate SQL ตาม Dialect ของ DBMS ที่เลือก พร้อม Comment — Column order ใน CREATE TABLE ต้องตรงกับ Data Dictionary
   - **Collation Compliance (บังคับ — Rule 12):** ทุก text column (`CHAR`, `VARCHAR`, `NCHAR`, `NVARCHAR`, `TEXT`, `CLOB`, ฯลฯ) ต้องมี `COLLATE` clause inline + `CREATE DATABASE` ต้องระบุ Collation/Encoding + `CREATE TABLE` ต้องระบุ Collation (ถ้า DBMS รองรับ)
   - **Lint Check ก่อนส่ง:** ตรวจ DDL ที่ Generate ว่าทุก text column มี `COLLATE` — หากพบ column ที่ขาด → ต้องเติม + แจ้ง SA
   - **PACK_INSTALL Section 1 ต้องขึ้นต้นด้วย `CREATE DATABASE ... COLLATE ...` (หรือ equivalent)** ก่อน `CREATE TABLE` ใดๆ
9. **Pack Install Bundling (DB + Tables + Constraints เท่านั้น — บังคับ):** รวบรวม SQL ของ **CREATE DATABASE + CREATE TABLES + ADD CONSTRAINTS** เป็น `PACK_INSTALL_<Module>.sql` — **ไม่รวม:**
   - ❌ INDEX (แยกไป `INDEX_<Module>.sql`)
   - ❌ INSERT / Sample Data (แยกไป `INSERT_<Module>.sql`)
   - ❌ ROLLBACK / DROP (แยกไป `ROLLBACK_<Module>.sql`)
   - ❌ Stored Procedure (แยกไป `STORED_PROCEDURE_<Module>.sql`)
   - **🚨 ห้ามใช้ `GO`** ใน PACK_INSTALL — เพื่อให้ run ได้ทั้ง sqlcmd, programmatic deploy, และ ORM migration tools (SSMS ที่ต้องการ GO ให้ wrap script เอง):

   ```sql
   -- ============================================================
   -- PACK_INSTALL_<Module>.sql — DB + Tables + Constraints ONLY
   -- DBMS: <DBMS> v<Version>   Module: <Module>   Generated: YYYY-MM-DD
   -- Author: <SA name>   Version: v<x.y> (sync with CHANGELOG)
   -- Collation: Latin1_General_100_BIN2_UTF8 (หรือ DBMS equivalent — Rule 12)
   -- ============================================================
   -- Companion files (run separately):
   --   → INDEX_<Module>.sql        — CREATE INDEX statements
   --   → INSERT_<Module>.sql       — Sample / Reference data
   --   → STORED_PROCEDURE_<Module>.sql — SP / Function source
   --   → ROLLBACK_<Module>.sql     — DROP statements
   -- ============================================================

   -- =========== Section 0: CREATE DATABASE & COLLATION (Rule 12) ===========
   -- บังคับขึ้นต้นด้วย CREATE DATABASE + Collation baseline
   -- 🚨 NO GO statements — รองรับ sqlcmd / programmatic deploy
   IF DB_ID(N'<db_name>') IS NULL
   BEGIN
       CREATE DATABASE <db_name>
       COLLATE Latin1_General_100_BIN2_UTF8;
   END;

   USE <db_name>;

   -- หรือ MySQL: CREATE DATABASE <db_name> CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
   -- หรือ PostgreSQL: CREATE DATABASE <db_name> ENCODING 'UTF8' LC_COLLATE 'C' LC_CTYPE 'C' TEMPLATE template0;

   -- =========== Section 1: CREATE TABLES ===========
   -- DDL ของทุก Table ใน Module นี้ พร้อม PK, Default, Comment
   -- เรียงลำดับตาม dependency: parent table ก่อน → child table
   -- ⚠️ ทุก text column ต้องเป็น NVARCHAR (MSSQL) + COLLATE clause (Rule 12)
   CREATE TABLE customer (
       customer_id   INT PRIMARY KEY,
       customer_name NVARCHAR(100) COLLATE Latin1_General_100_BIN2_UTF8 NOT NULL,
       email         NVARCHAR(255) COLLATE Latin1_General_100_BIN2_UTF8 NOT NULL
   );
   CREATE TABLE product (...);
   CREATE TABLE "order" (...);
   -- ...

   -- =========== Section 3: ADD CONSTRAINTS ===========
   -- FK Constraints, Check Constraints, Unique Constraints ที่ไม่ได้ inline ใน CREATE TABLE
   -- (separate เพื่อให้ rollback / disable ได้สะดวก)
   ALTER TABLE "order" ADD CONSTRAINT fk_order_customer
       FOREIGN KEY (customer_id) REFERENCES customer(customer_id);
   -- ...

   -- END OF PACK_INSTALL — สำหรับ Index / Insert / Rollback ดูไฟล์แยก
   ```

   **Section Mapping (PACK_INSTALL only — มี 3 sections):**

   | Section | เนื้อหา | ที่มา |
   |---------|---------|-------|
   | **0** | **CREATE DATABASE & COLLATION (Rule 12) — no GO** | `db-create-schema` (skill นี้) |
   | 1 | CREATE TABLES (text column ทุกตัวต้องมี COLLATE) | `db-create-schema` (skill นี้) |
   | 3 | ADD CONSTRAINTS (FK, CHECK) | `db-create-schema` (skill นี้) |

   **Companion Files (แยกออกไป):**

   | ไฟล์ | เนื้อหา | ผู้สร้าง |
   |------|---------|---------|
   | `INDEX_<Module>.sql` | CREATE INDEX statements (เคย Section 2) | `db-create-index` |
   | `INSERT_<Module>.sql` | Reference / Sample data INSERT (เคย Section 4) | `db-create-sample-data` |
   | `ROLLBACK_<Module>.sql` | DROP statements reverse order (เคย Section 99) | `db-create-schema` |
   | `STORED_PROCEDURE_<Module>.sql` | SP / Function source | `db-create-procedure` |
10. **🚨 Self-Audit (บังคับก่อน SA Review — Rule 0):** Generate Self-Audit Report สำหรับ schema:
    - Check ทุกกฎ 0-12 ผ่านครบไหม
    - List Open Items ทั้ง strict violation + borderline cases
    - หาก violation → หยุด + แก้ก่อน proceed
11. **SA Review Loop:** ส่งผลให้ SA Review → ถ้า SA ส่ง Final SQL กลับมา ให้ AI เก็บลง Spec
12. **Hand-off:** ส่งต่อ Schema ให้ `db-create-index` (ถ้าต้อง Index เพิ่ม) หรือ `db-test-sql` (ก่อน Finalize)

## Special Mode: Modify (ALTER TABLE)

หาก parent ส่งมาในโหมด Modify ให้:
- Generate `ALTER TABLE` แทน `CREATE TABLE`
- ใช้ชื่อ Table / Column เดิมเป๊ะ (Preserve Exact Names)
- ระบุ Backward Compatibility (Default Value สำหรับ data เก่า ถ้าเพิ่ม NOT NULL)
- แนบ Rollback Script (`ALTER TABLE ... DROP COLUMN ...`)

## Special Mode: Convert (Cross-DBMS)

หาก parent ส่งมาในโหมด Convert ให้:
- รับ Data Type Mapping Table จาก parent (ต้อง Approve แล้ว)
- Generate DDL ของ **Target DBMS** ตาม mapping
- รักษาชื่อ Table / Column เดิมเป๊ะ (ยกเว้นกรณีชื่อเดิมเป็น Reserved Word ใน Target DBMS → ใช้ Reserved Words Check Flow)
- ห้าม Generate จนกว่า parent จะส่ง mapping ที่ SA Approve มาให้

### บังคับสร้างไฟล์ `CONVERT_<Module>.md` (เฉพาะ Mode Convert)

`db-create-schema` รับผิดชอบสร้างไฟล์ `CONVERT_<Module>.md` คู่กับ `PACK_INSTALL_<Module>.sql` โดยมีเนื้อหา:

```markdown
# Convert Plan — <Module>

**Related Spec:** [DB_SPEC_<Module>.md](./DB_SPEC_<Module>.md)
**Pack Install:** [PACK_INSTALL_<Module>.sql](./PACK_INSTALL_<Module>.sql)

## Module Scope
- **Module ที่ Convert:** <Module Name (รวม Composite parts ถ้ามี เช่น CashFlow_Receive)>
- **Tables in Scope:** <list>

## Source → Target
| Field | Source | Target |
|-------|--------|--------|
| **DBMS** | <Source DBMS> | <Target DBMS> |
| **Version** | v<x.y> | v<x.y> |
| **Case Style** | <style> | <style> |
| **Collation** | <Source Collation> | <Target Collation — baseline Rule 12> |

## Data Type Mapping (ฉบับเต็ม)

| Table.Column | Source Type | Target Type | Precision/Length Change | Risk Note |
|--------------|-------------|-------------|-------------------------|-----------|
| ... | ... | ... | ... | ... |

## Collation Mapping (บังคับ — Rule 12)

> ระบุ Source Collation → Target Collation พร้อม Risk Note ทุก text column ที่มี collation ไม่ตรง baseline ของ Target DBMS

| Scope | Source Collation | Target Collation | Risk Note |
|-------|------------------|------------------|-----------|
| **Database (default)** | <e.g. SQL_Latin1_General_CP1_CI_AS> | `Latin1_General_100_BIN2_UTF8` หรือ equivalent | ⚠️ Case-insensitive → Case-sensitive: duplicate ที่เคย fold จะถูก enforce แยก |
| **Table: `customer`** | <inherit / overridden> | <baseline> | <note> |
| **Column: `customer.email`** | <inherit / specific> | `Latin1_General_100_BIN2_UTF8` | <note> |
| ... | ... | ... | ... |

**Migration Impact ที่ต้อง brief Dev / SA:**

- ⚠️ **Comparison Behavior Change** — query ที่ assume case-insensitive จะ break (เช่น login by email ที่ user พิมพ์ตัวพิมพ์ใหญ่)
- ⚠️ **Sort Order Change** — `ORDER BY` ของ text column ผลลัพธ์จะต่างจากเดิม
- ⚠️ **Duplicate Key Exposure** — UNIQUE constraint ที่เคย fold case → ใน BIN2 อาจ "ผ่าน" tuple ที่จริงๆ business ถือว่า duplicate
- ✅ **Index Rebuild Required** — ทุก index บน text column ต้อง drop + recreate ตาม Target collation

## Unsupported Features + Workaround

| Source Object | Type | Why Not Convertible | Proposed Workaround |
|---------------|------|---------------------|---------------------|
| ... | ... | ... | ... |

## Reserved Words Renamed (ถ้ามี)

| Original | Reserved In Target | Final Name |
|----------|---------------------|------------|
| ... | ... | ... |
```

> **หมายเหตุเรื่อง CONVERT vs Conversion Report:**
> - `CONVERT_<Module>.md` (ไฟล์นี้) = **Meta / Plan** บอก "convert module ไหน จาก DBMS อะไร ไป DBMS อะไร พร้อม mapping ฉบับเต็ม"
> - **Conversion Report ภายใน `DB_SPEC_<Module>.md`** (parent เป็นคนจัดการ) = **Compare** Schema เก่า ↔ ใหม่ บอก "แก้จากอะไรเป็นอะไร" + Migration Plan + Rollback

## Output Format

```markdown
## Schema Spec — <Module>

**DBMS:** <DBMS> v<Version>  |  **Collation:** <Latin1_General_100_BIN2_UTF8 / DBMS equivalent>  |  **Case Style:** <style>  |  **Column Order:** <Data Dict / PK-FK-Business-Audit>  |  **Mode:** New / Modify / Convert

### Reserved Words Check Result

- ✅ No conflict found
*หรือ*
- ⚠️ Found conflicts: `key`, `Type`, `order` → User confirmed renames

| Original | Table        | Reserved In  | Option Chosen        | Final Name        | Confirmed By User |
|----------|--------------|--------------|----------------------|-------------------|--------------------|
| key      | Sales        | MSSQL        | (1) Type-Prefix      | n_key             | ✅ Yes             |
| Type     | CashMovement | MSSQL        | (2) Concat           | CashMovementType  | ✅ Yes             |
| order    | Sales        | SQL Standard | (4) Custom           | sales_order       | ✅ Yes             |

### Data Dictionary

(เรียงตาม Column Ordering Preference ที่ SA เลือก)

> **Key Marker Policy:** ใช้แค่ **PK** และ **FK** เท่านั้น (Rule 9) — **UNIQUE** constraint info ไปอยู่ใน Index Strategy section ใต้ตาราง Data Dict ของแต่ละ table
>
> **Collation Note (Rule 12):** ทุก text column ใช้ Collation เดียวกันทั้ง schema (ระบุไว้ที่ Header ของ DB_SPEC แล้ว) — ไม่ต้องใส่ column `Collation` ในตาราง Data Dict นี้ ยกเว้นมี column ที่ใช้ Collation ต่างจาก default (ซึ่งต้องผ่าน Explicit Skip Confirmation ตาม Rule 0)
>
> **Open Items Note (Rule 6):** column ที่มี borderline case (เช่น Future Reserved, ambiguous data type prefix, blank description) ต้อง mark `⚠️` ใน Technical Note + ลงรายละเอียดใน Open Items section ของ DB_SPEC

| Table | Column | Data Type | PK | FK | Nullable | Default | Description (Verbatim) | Technical Note |
|-------|--------|-----------|:---:|:---:|----------|---------|------------------------|----------------|
| ...   | ...    | ...       | ... | ... | ...      | ...     | (verbatim จาก Data Dict) | (Business Key, normalized, ⚠️ Open Item ref) |

### Null Constraint Summary

| Table | Column | Nullable | Default | Business Reason |
|-------|--------|----------|---------|-----------------|
| ...   | ...    | NO       | ...     | ...             |

### DDL Script

```sql
-- ตาม Dialect ของ DBMS ที่เลือก
-- Column order: <ตามที่ SA เลือกใน Pre-Run Check>
CREATE TABLE ... ;
```

### Pack Install File (DB + Tables + Constraints — 3 sections)

- `PACK_INSTALL_<Module>.sql` — Section 0 (CREATE DATABASE), Section 1 (CREATE TABLES), Section 3 (ADD CONSTRAINTS) — **no GO**

### ROLLBACK File (บังคับ — แยกออกจาก PACK_INSTALL)

- `ROLLBACK_<Module>.sql` — DROP statements reverse order:
  ```sql
  -- ============================================================
  -- ROLLBACK_<Module>.sql — Teardown script
  -- WARNING: Data Loss — backup ก่อนรัน
  -- ============================================================
  USE <db_name>;
  DROP TABLE IF EXISTS dbo.<child_table>;  -- child first
  DROP TABLE IF EXISTS dbo.<parent_table>;
  -- ...
  USE master;
  DROP DATABASE IF EXISTS <db_name>;
  ```

### Convert File (เฉพาะ Mode Convert)

- `CONVERT_<Module>.md` (Source → Target meta + Data Type Mapping ฉบับเต็ม + Unsupported Features)
```

## Hand-off Notes

- ส่ง Schema ที่ผ่าน SA Review กลับไป parent (`db-create-spec`) เพื่อรวมใน DB_SPEC_<Module>.md
- หากมี Index ขั้นสูง ส่งต่อ `db-create-index`
- หากต้องการ Sample Data ส่งต่อ `db-create-sample-data`
- Mode Convert: ต้องสร้างทั้ง `PACK_INSTALL_<Module>.sql` และ `CONVERT_<Module>.md`

## Changelog

- **v1.5** — Enforce 6 กฎใหม่:
  1. **Exhaustive Multi-Source Scan** — 4 sources (CSV / T-SQL Reserved / ODBC / Future Reserved) ต้องเช็คครบ
  2. **Bracket Forbidden as Silent Workaround** — Option (5) Escape ต้อง explicit + บันทึก risk
  3. **Sub-Skill Trigger Enforce** — บังคับเรียก `db-rename-reserved-word` ห้าม inline
  4. **Self-Audit Step** — เพิ่ม Step 10 ก่อน SA Review Loop
  5. **Open Items Borderline Coverage** — Data Dict มี ⚠️ marker + section Open Items ใน DB_SPEC
  6. **CSV Append-Only Audit Log** — เพิ่ม Step 6 ใน Reserved Words Check Flow
- **v1.4** — เพิ่ม **Option (1) Type-Prefix Convention** ใน Reserved Words Check Flow เป็น Company Default:
  - เพิ่ม cross-reference ไปยัง skill ใหม่ `db-rename-reserved-word`
  - shift Options เดิม → (2) Concat / (3) AI Suggested / (4) User-Defined / (5) Escape (hidden)
  - Audit Trail Table ใส่ตัวอย่าง Type-Prefix mapping (`n_key`, `s_index`)
  - Prompt ตัวอย่างใหม่แสดง 4 options พร้อม Type-Prefix เป็น Recommended
- **v1.3** — เพิ่ม Pre-Run Check ข้อ 5: **Collation Confirmation** (Critical — บังคับ Rule 12)
  - บังคับยืนยัน Collation ก่อน Generate DDL — Default = `Latin1_General_100_BIN2_UTF8` (MSSQL) หรือ equivalent ของ DBMS อื่น
  - Apply ทั้ง 3 ระดับ: Database / Table / Column
  - DDL Generation บังคับใส่ `COLLATE` clause ทุก text column + `CREATE DATABASE ... COLLATE ...` ขึ้นต้น PACK_INSTALL Section 1
  - Lint Check ก่อนส่ง: text column ที่ขาด `COLLATE` = Violation
  - MSSQL < 2019 fallback: `Latin1_General_100_BIN2` + `NVARCHAR`
- **v1.2** — เพิ่ม Reserved Words Check Flow แบบ 3 Options บังคับ:
  1. `<TableName><ReservedWord>` (Concatenation ตาม Case Style)
  2. AI Suggested Name (1 ชื่อ จาก Business Context)
  3. User-Defined (ให้ User พิมพ์ชื่อเอง)
  - บังคับว่า "เจอ Reserved Word ต้องถาม User ทุกครั้ง" — ห้ามข้ามแม้ User สั่ง "Generate เลย"
  - เพิ่ม Audit Trail Table แสดง Option ที่เลือกและ Final Name
  - เพิ่ม Validation: เมื่อ User เลือก Option (3) → ต้อง re-check ว่าชื่อใหม่ไม่ใช่ Reserved Word
- **v1.1** — เพิ่ม 3 rules ตาม SA feedback:
  1. **Preserve Exact Names from Data Dict** — ใช้ชื่อตาม Data Dict เป๊ะ (รวม `_`) ห้ามปรับตาม Case Style
  2. **Column Ordering Preference** — เพิ่มคำถาม Multiple Choice (1) ตาม Data Dict (2) PK→FK→Business→Audit
  3. **Reserved Words Check Flow** — แบ่งเป็น Scan → Warn → Suggest (2-3 ชื่อ) → Confirm → Apply พร้อมตัวอย่าง output