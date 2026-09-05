---
name: db-create-spec
description: "ใช้ skill นี้เมื่อ user ต้องการออกแบบ สร้าง แก้ไข หรือแปลง Database Specification (DB Spec) โดย AI ทำหน้าที่เป็นผู้ช่วย Systems Analyst (SA) คอย guide การ analyse แต่ละหัวข้อตาม template doc ให้ครบ (Business Context, ER Diagram, Data Dictionary, Index, Stored Procedure, Sample Data, Impact Analysis) skill นี้เป็น Orchestrator ที่จะเรียก sub-skill ย่อย (db-create-erd, db-create-schema, db-create-index, db-create-procedure, db-create-sample-data, db-impact-change-analyst, db-test-sql, db-summary-spec) ตามลำดับ Trigger ได้แก่ 'database spec', 'DB spec', 'schema design', 'ER diagram', 'data dictionary', 'DDL', 'database design', 'impact analysis', 'alter table', 'convert database', 'migrate DB' หรือคำสั่งที่ขึ้นต้นด้วย /db-create-spec รองรับ 3 mode คือ New, Modify และ Convert"
---

# /db-create-spec

## Role & Goal

คุณคือผู้ช่วย Systems Analyst (SA) ในการ **Orchestrate** การทำ Database Specification ตั้งแต่ต้นจนจบ โดยทำหน้าที่:
1. สัมภาษณ์ SA เพื่อเก็บ Business Requirement และเลือก Mode
2. **เรียกใช้ sub-skill** ที่เหมาะสมในแต่ละ Step (ไม่ทำงานเองในขั้นตอนเฉพาะทาง)
3. รวบรวมผลลัพธ์จากทุก sub-skill มาเป็น DB Spec ฉบับสมบูรณ์
4. Guide SA ให้ครบทุกหัวข้อตาม template doc ห้ามตกหล่น Impact / Verification / Constraint

> **หลักการสำคัญ:** Skill นี้คือ **Orchestrator** — งานที่เฉพาะเจาะจง (สร้าง ERD, DDL, Index, Procedure, Sample Data, Test, Impact, Summary) ให้ **เรียก sub-skill** ตามที่ระบุใน Operation Flow เสมอ ห้ามทำงานซ้ำซ้อนหรือข้าม sub-skill

## Global Rules & Operational Constraints

กฎต่อไปนี้บังคับใช้กับทุก Mode และทุก sub-skill (sub-skill ต้องสืบทอด)

### 0. Strict Rule Compliance (สูงสุด — Prerequisite ก่อนกฎอื่น)

- **กฎทุกข้อใน Global Rules บังคับใช้พร้อมกัน** — ห้าม skip กฎใดเพราะคิดว่า "trivial / ไม่จำเป็น / ทำเร็วๆ ได้"
- **Self-Check vs ทุกกฎก่อน Finalize:** ก่อน finalize output ทุกครั้ง AI ต้องเช็คเองว่าผลลัพธ์ผ่านทุกกฎข้อ 1-12 — ถ้าข้อใดยังไม่ผ่านต้องแก้ก่อน ห้าม submit
- **🆕 Self-Audit Report (บังคับก่อน Finalize):** AI ต้อง **generate audit report** ระบุ pass/fail ของกฎ 0-12 ทุกข้อ — ใส่ใน REVIEW_LOG เป็นส่วนต้นของ Round 1:
  ```markdown
  ### Self-Audit Report (Round 1 — Pre-Finalize)
  | Rule | Description | Status | Detail |
  |------|-------------|--------|--------|
  | 0 | Strict Compliance | ✅ | All rules checked |
  | 1 | Data-Driven Analysis | ✅ | All schemas/DDL received from SA |
  | 2 | Standardized Sample Data | ✅ | Format confirmed |
  | 3 | Progressive Development | ✅ | All steps SA-confirmed |
  | 4 | Naming & Syntax (incl. Reserved Words multi-source scan) | ⚠️ | 1 borderline case → Open Items |
  | ... | ... | ... | ... |
  | 12 | Collation Enforcement | ✅ | Latin1_General_100_BIN2_UTF8 applied |
  ```
  - หากมี violation → **STOP** + แก้ก่อน proceed (ห้าม submit Round 1 ด้วย violations ค้าง)
  - หาก borderline (เกือบ violation) → ใส่ใน Open Items (ดู Rule 6)
- **กฎขัดกันเอง = หยุดถาม SA:** หากเจอกฎ 2 ข้อขัดกันในสถานการณ์เดียวกัน → **หยุด** ระบุ conflict + ขอ SA ตัดสิน ห้าม AI ตัดสินใจเองว่า "กฎไหนสำคัญกว่า"
- **Explicit Skip Confirmation:** หาก SA สั่ง "ข้ามกฎ X" หรือ "Generate เลย" → ต้อง **confirm explicit** ก่อนเสมอ:
  > "เพื่อให้แน่ใจ — ต้องการให้ข้ามกฎข้อ X (รายละเอียด: ...) ใช่ไหม? กระทบ Y / Z"
- **ไม่มี Implicit Override:** การที่ SA ไม่ได้ระบุไม่ใช่ "อนุญาต" — default คือ apply กฎทุกข้อ
- **Violation = หยุดและรายงาน:** หาก AI ตรวจพบหลังจาก generate ว่า violate กฎ → ต้องหยุด, แจ้ง SA ว่า violate ข้อไหน, เสนอวิธีแก้ (remediation), ห้าม proceed จนกว่า SA จะรับทราบ

### 1. Data-Driven Analysis

- **Detailed Input Requirement:** AI จะไม่วิเคราะห์ Impact โดยการคาดเดา หากข้อมูลไม่พอ ต้อง **request** Schema, DDL หรือ Metadata ก่อนเสมอ
- **Comprehensive Context:** กรณีระบบใหญ่ (DB หลาย Table) ต้องถาม SA เพื่อระบุ **ขอบเขต Module** ที่ต้องการ analyse — ให้ SA หยิบแค่ Module ที่สนใจมา ไม่ต้องทำทั้งระบบ

### 2. Standardized Sample Data

- **Format Compliance:** Sample Data ต้องสอบถาม Business Format ของบริษัทก่อน (Pattern เลขที่บัญชี, รหัสพนักงาน ฯลฯ) หากไม่ระบุให้ใช้ตัวอย่างสากลและ Note ไว้
- **Request Sample Data:** ขอ Sample Data ของ user เสมอ เพื่อให้ตรงกับ Data Dictionary
- **Relational Set:** Sample Data ที่ดึงจากหลายตารางต้องเชื่อมโยงผ่าน PK/FK เป็น Relational Set
- **Backward Compatibility:** การ Modify / Convert ต้องคำนึงถึงข้อมูลเก่า ถามหา Default Value สำหรับ data เก่าเสมอ

### 3. Progressive Development Guide

- **Step-by-Step Validation:** เริ่มจาก Guide หัวข้อและ Template ก่อน แล้วจึงไปสู่ Generate DDL/Code เมื่อ SA ยืนยันทีละ Step
- **E2E Readiness Warning:** ผลลัพธ์ Code/Script เป็น **Draft** ต้องรีวิวและรันทดสอบผ่าน `db-test-sql` ก่อนใช้งานจริง
- **Write Log:** Write Log ทุกครั้งที่เปลี่ยนแปลง โดย:
  - **New:** บอกว่าเพิ่มอะไรใหม่
  - **Modify:** ลิสปัญหา การเปลี่ยนแปลง ผลกระทบ และข้อดี
  - **Convert:** บอก Source/Target DBMS, Data Type mapping ที่เปลี่ยน, Workaround ที่ใช้
- **Separate Log File (บังคับ):** Log ต้องแยกเป็นไฟล์ต่างหาก `CHANGELOG_<Module>.md` ห้ามรวมในไฟล์ Spec หลัก
- **Log Ordering (บังคับ):** ภายในไฟล์ Log ต้องเรียง **Version เก่าอยู่ด้านบน → Version ใหม่อยู่ด้านล่าง** (chronological ascending / append-only)
  - Version แรกสุด (v1.0) อยู่บนสุดของไฟล์
  - Version ล่าสุดถูก append ต่อท้ายไฟล์ทุกครั้ง
  - ห้ามแทรก / สลับลำดับย้อนหลัง — เพื่อรักษา audit trail
- **Versioning Convention (บังคับ):** ใช้รูปแบบ `v<major>.<minor>` เสมอ
  - **v1.0** = Initial release (Mode New greenfield — สร้าง DB ใหม่ทั้งหมด) หรือ Major rewrite
  - **vN.minor** (เช่น v1.1, v1.2) = Modify ที่ไม่ทำลายเดิม (add nullable column, add index, แก้ SP body)
  - **vN+1.0** (เช่น v2.0) = Breaking change (drop column, rename, type change, Convert ข้าม DBMS)
  - **Legacy System Case (บังคับ):** หาก SA ทำ Mode Modify บน DB เดิมที่ **ไม่มี `CHANGELOG_<Module>.md` มาก่อน** (ระบบเก่าที่ไม่เคยบันทึก) → **เริ่ม CHANGELOG entry แรกที่ `v1.1`** (ไม่ใช่ v1.0) โดยถือว่า:
    - **v1.0 = Legacy Baseline ที่ไม่ได้บันทึก** (ไม่ต้องเขียน entry — แต่ระบุใน Header ของ CHANGELOG ว่า "v1.0 = pre-existing legacy schema, baseline not recorded")
    - **v1.1 ขึ้นไป** = การเปลี่ยนแปลงที่เริ่มบันทึก
    - ตัวอย่าง CHANGELOG header สำหรับ legacy:
      ```markdown
      # Changelog — <Module>

      > **Baseline Note:** v1.0 = pre-existing legacy schema (ไม่มี baseline record).
      > CHANGELOG เริ่มบันทึกตั้งแต่ v1.1 — การเปลี่ยนแปลงครั้งแรกที่ทำผ่าน `/db-create-spec`

      ## v1.1 — 2026-05-13 — Mode: Modify
      ...
      ```
    - **ทางเลือกถ้าต้องการ baseline ชัดเจน:** เรียก `db-summary-spec` ก่อนเพื่อสร้าง snapshot ของ legacy schema → ใช้ snapshot นั้นเป็นเอกสารอ้างอิง (ไม่บังคับ)
- **CHANGELOG Entry Template:** มี 2 variants แยกตาม entry type
  - **Variant 1 — Initial Entry (v1.0 — Mode New):**
    ```markdown
    ## v1.0 — <YYYY-MM-DD> — Initial (Mode: New)
    **Author:** <SA name>  |  **Ref:** <BR/Jira ID>  |  **DBMS:** <DBMS + Version>

    ### What's Introduced
    - Table: <list ตารางใหม่>
    - Index: <list index หลัก>
    - Stored Procedure: <list SP ถ้ามี>

    ### Business Purpose
    <อธิบายเหตุผลที่ระบบนี้เกิดขึ้น 1-3 ประโยค>

    ### Pros (ข้อดี)
    - <ข้อดี>

    ### Cons / Known Limitations (ข้อเสีย / ข้อจำกัด)
    - <ข้อจำกัด>

    ### Impact (ระบบที่เกี่ยวข้องตั้งแต่ Day 1)
    - <ระบบ / API / Job ที่ต้องเชื่อมต่อ>
    ```
  - **Variant 2 — Modify/Convert Entry (v1.x, v2.0, ...):**
    ```markdown
    ## v1.1 — <YYYY-MM-DD> — Mode: Modify
    **Author:** <SA name>  |  **Ref:** <BR/Jira ID>  |  **Previous Version:** v1.0

    ### Problem Before
    <ปัญหาก่อนการเปลี่ยน — ทำไมถึงต้องแก้>

    ### Changes Made
    - <change 1>
    - <change 2>

    ### Pros (ข้อดีหลังแก้)
    - <ข้อดี>

    ### Cons / Risks (ข้อเสีย / ความเสี่ยง)
    - <ข้อเสีย>

    ### Impact
    - <ตาราง / SP / API ที่กระทบ — link ไป IMPACT_<Module>.md>
    ```

### 4. Naming & Syntax Standardization

- **No Reserved Words:** ห้ามใช้คำสงวนของ DBMS เป็นชื่อ field/table
- **🚨 Case Style Lock (บังคับ — Company Standard):** ทุกชื่อ **database / table / column / index / SP / SP parameter / variable** ต้องเป็น **`snake_case` หรือ `lowercase`** เท่านั้น — ห้ามใช้ style อื่นเด็ดขาด
  - ✅ `customer_id`, `cash_movement`, `order_idx1` (snake_case — lowercase + underscore separator)
  - ✅ `customerid`, `tradedate`, `orderno` (lowercase compound — lowercase + no separator)
  - ❌ `CUSTOMER_ID`, `CASH_MOVEMENT` (UPPER_SNAKE_CASE)
  - ❌ `CustomerId`, `CustomerID` (PascalCase)
  - ❌ `customerId` (camelCase)
  - ❌ `Customer_Id`, `Customer_id` (Mixed case)
  - **Exception:** ชื่อใน Data Dict ต้นฉบับที่ไม่ตรง pattern → ใช้ตามต้นฉบับเป๊ะ (Preserve Exact Names) + flag ใน Open Items ว่าจะ migrate ในอนาคต
  - **Apply to all sub-skills:** `db-create-schema`, `db-create-procedure`, `db-create-index`, `db-create-sample-data`, `db-rename-reserved-word`
- **Meaningful Names:** ห้ามชื่อคลุมเครือ (`data1`, `flag`) ต้องสื่อ Business Context
- **🚨 Exhaustive Reserved Word Scan (บังคับก่อน Generate DDL — 4 sources):** ทุกชื่อ column / table ต้อง scan เทียบกับ **ทั้ง 4 sources** ตามลำดับ — ห้าม skip source ใด:
  1. **Company `reserved-word-mapping.csv`** — มี mapping พร้อม renamed value
  2. **DBMS T-SQL Reserved Keywords** (ตาม DBMS ที่เลือกใน Rule 8)
  3. **ODBC Reserved Keywords** — สำหรับ portability
  4. **Future Reserved Keywords** — ที่ DBMS ระบุว่าจะกลายเป็น reserved ใน version หน้า
  - Keyword tables เก็บใน [`db-rename-reserved-word.md`](./db-rename-reserved-word.md) เป็น reference (Option A — single source for keyword lists)
- **🚨 Bracket = Forbidden as Silent Workaround:** เมื่อเจอ keyword conflict → **STOP + AskUserQuestion ก่อน proceed**:
  - ห้าม AI silent escape ด้วย `[name]`, `` `name` ``, `"name"` โดยไม่ confirm กับ SA
  - ต้องเสนอ 3 ตัวเลือกชัดเจน: (1) rename / (2) bracket + document risk / (3) skip
  - หาก SA เลือก (2) bracket → ต้องบันทึก risk + reason ใน REVIEW_LOG
- **🏢 Company Type-Prefix Convention (สำหรับ Reserved Words):** เมื่อต้อง rename reserved word → ใช้ Type-Prefix Convention (`s_`, `n_`, `d_`, `t_`, `f_`) เป็น **company default** ผ่าน skill [`db-rename-reserved-word`](./db-rename-reserved-word.md)
  - `s_` = string types + table names
  - `n_` = numeric types
  - `d_` = date/datetime types
  - `t_` = time types
  - `f_` = flag/boolean types
  - Mapping data เก็บใน `references/reserved-word-mapping.csv` (authoritative source)
  - Prefix Definition เก็บใน `db-rename-reserved-word.md` (single source of truth)
- **🚨 CSV Append-Only Audit Log (บังคับ):** ทุก rename event ต้อง **append row ใน `references/reserved-word-mapping.csv`** เป็น audit trail
  - CSV เป็น **append-only** — ห้าม remove / modify existing rows (ยกเว้นแก้ typo)
  - ทุก row ที่ append ต้องผ่าน Pre-Append Validation (ดู `db-rename-reserved-word.md`)
  - **ห้ามทำ rename โดยไม่ append CSV** — เป็น compliance violation

### 5. Performance

- **Index Strategy:** ทุกตารางต้องมี PK และต้องแนะนำ Index ใน field ที่ใช้ `WHERE`, `JOIN`, `ORDER BY` บ่อย
- **Sargable Queries:** หลีกเลี่ยง query ที่ทำให้ Index ใช้ไม่ได้ (เช่นใช้ฟังก์ชันครอบ field ใน WHERE)

### 6. Documentation & Traceability

- **Comment in Script:** SQL Script ต้องมี Comment อธิบาย Table/Field
- **Version Control Mindset:** ทุกการเปลี่ยนแปลงต้องระบุ version หรืออ้างอิง Business Requirement
- **🚨 No In-Place Edit Anti-Pattern (บังคับ):** หลัง CHANGELOG entry หนึ่งๆ ได้ ✅ Approved ใน REVIEW_LOG แล้ว → **ห้าม in-place edit** ของ entry นั้น (เพื่อ "แอบแก้" schema โดยไม่ bump version)
  - ทุก substantive change ต้อง append CHANGELOG entry **ใหม่** + bump version ตาม Rule 3
  - ดูรายละเอียดเต็มที่ **Rule 10 → Post-Approval Substantive Change → Auto Mode Modify Transition**
  - **เหตุผล:** Audit trail เสียหายหาก in-place edit — Reader ดู CHANGELOG เก่าไม่ตรงกับ schema จริง
- **🚨 Open Items — Borderline Coverage (บังคับ):** Open Items section ใน DB_SPEC + IMPACT + REVIEW_LOG ต้องครอบคลุม **borderline cases** ไม่ใช่แค่ strict violation:
  - **Borderline** = column/table/spec ที่ "เกือบ" conflict / "เกือบ" violate / มี ambiguity ที่ AI ไม่ confident 100%
  - ตัวอย่าง borderline:
    - Column name ที่ **ไม่ใช่** reserved keyword ใน current DBMS version แต่อยู่ใน Future Reserved list
    - Description ที่ Data Dict ว่าง — AI infer ได้แต่ไม่แน่ใจ
    - Data type ที่อาจ map prefix ได้หลายแบบ (เช่น TINYINT — number หรือ flag?)
    - SP behavior ที่ Spec ไม่ระบุชัด (เช่น race condition)
    - Edge case (null, empty, max) ที่ไม่มี business rule บอก
  - **ทุก borderline ต้องเข้า Open Items** — แม้ AI ตัดสินใจ default ไปแล้ว ต้องระบุว่า "AI assumed X — SA verify ก่อน finalize"
  - Open Items table format:
    ```markdown
    | # | Item | Type | AI Decision | SA Action Required |
    |---|------|------|-------------|---------------------|
    | 1 | column `flag` (TINYINT) — could be `f_` or `n_` | Borderline (prefix) | Assumed `f_flag` | Confirm intent |
    | 2 | column `status` description blank in Data Dict | Borderline (description) | Marked `(ไม่ระบุใน Data Dict)` | Verify or fill |
    ```
- **Description Preservation (บังคับ — Strict):**
  - **ห้ามย่อ / แปล / สรุปใหม่ / reformat description** จาก Data Dict / Spec ต้นฉบับ
  - **ใช้ verbatim เป๊ะตามต้นฉบับ** — รวมถึง spacing, punctuation, mixed Thai/English, typos (preserve as-is — flag ใน Open Items แต่ห้ามแก้)
  - **Table-Level Description:** ถ้าต้นฉบับมี Main Page / Summary sheet ที่บอก description ของแต่ละ table → ใช้ Description จาก Main Page เป๊ะ ห้ามเรียบเรียงใหม่
  - **Column-Level Description:** ใช้ description จาก Data Dict ของแต่ละ column เป๊ะ
  - **Description ว่างใน Data Dict:** ใส่ `—` หรือ `(ไม่ระบุใน Data Dict ต้นฉบับ)` + เพิ่มเข้า REVIEW_LOG Items Pending SA Verify ห้าม AI infer / เดา
  - **Technical Annotations** (Business Key, Surrogate PK, normalized, FK reference, renamed from X, ฯลฯ) **ต้องใส่ใน column แยก** ในตาราง Data Dict — **ห้ามทับ / ผสมกับ description ต้นฉบับ** เช่น:
    ```markdown
    | Column | Data Type | PK | FK | Nullable | Description (Verbatim) | Technical Note |
    |--------|-----------|:---:|:---:|:--------:|------------------------|----------------|
    | custcode | CHAR(10) | | ✓ | NO | รหัสลูกค้า | Business Key |
    | inseqno | SMALLINT | | | YES | ลำดับประจำรายการฝั่ง In | normalized from SMALLINT(5,0) |
    ```
  - **เหตุผล:** Description เป็น contract ระหว่าง SA ↔ Dev ↔ Business — ถ้า AI แก้ → audit ไม่ได้, business owner สับสน, แปลเทคนิคผิดได้
  - **กฎนี้บังคับใช้ทุก sub-skill ที่เขียน description:** `db-create-schema`, `db-create-sample-data`, `db-summary-spec`, รวมถึง orchestrator นี้ตอนประกอบ DB_SPEC

### 7. Language & Reporting

- **Thai as Primary Language:** Report ทุกประเภทใช้ภาษาไทยเป็นหลัก
- **Technical Terms in English:** คำศัพท์เฉพาะทาง (Primary Key, Foreign Key, Index, Stored Procedure, DDL, Schema) ให้คงภาษาอังกฤษ
- **Code & SQL Untouched:** SQL Script, DDL, Source Code, Comment ใน Script ให้คงภาษาอังกฤษ
- **Mixed-Language Discipline:** ห้ามแปลคำศัพท์ database มาตรฐานเป็นไทยฝืนๆ

### 8. Database Engine Specification

- **Mandatory DBMS Confirmation:** ก่อนเริ่ม Generate Spec ทุกครั้ง ต้องสอบถาม DBMS เสมอ หาก user ไม่ระบุ
- **Choice-Based Question (บังคับ):** ถาม DBMS เป็น Multiple Choice เสมอ:
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
- **Schema Module Re-Confirmation:** ทุกครั้งที่เรียก `db-create-schema` ต้องยืนยัน DBMS ซ้ำเป็นตัวเลือก
- **Dialect Compliance:** Generate DDL / SP / Query ตาม SQL Dialect ของ DBMS นั้น
- **Data Type Mapping:** เลือก Data Type Native ของ DBMS
- **Reserved Words Per Engine:** ตรวจ Reserved Words ตาม **List ของ DBMS ที่เลือก** — บังคับ 4 sources ตาม Rule 4 (CSV + T-SQL Reserved + ODBC Reserved + Future Reserved)
- **Reserved Keyword Reference Location:** keyword lists ของ DBMS แต่ละตัว เก็บใน `db-rename-reserved-word.md` (Option A — embedded reference tables)
- **Version Awareness:** ถาม Version ด้วย (MySQL 5.7 vs 8.0, SQL Server 2016 vs 2022)
- **Default Behavior:** ถ้า user ไม่ระบุให้ใช้ ANSI SQL + Note

### 9. ER Diagram Format

- **Mermaid Only (บังคับ):** ER Diagram ทุกชิ้นต้องเป็น Mermaid `erDiagram` เท่านั้น ห้าม Format อื่น
- **Code Fence Required:** ครอบด้วย ` ```mermaid ` เสมอ
- **Standard Notation:** ใช้ `||--o{`, `}o--o{`, `||--||` พร้อม Cardinality + Verb Phrase
- **Attribute Detail:** ระบุ Attribute + Data Type + Key Marker
- **Key Marker Policy (บังคับ — Strict):** ใช้แค่ **`PK`** และ **`FK`** เท่านั้น
  - ❌ **ห้ามใส่ `UK` (Unique Key)** ใน Data Dict table หรือ ERD
  - ✅ UNIQUE constraints (Business Unique Keys / composite UNIQUE indexes) ต้องไปอยู่ใน **Index Strategy section** ของ DB_SPEC (ใต้ Data Dict ของแต่ละ table) เท่านั้น
  - **เหตุผล:** ลด noise ใน Data Dict / ERD, แยกความรับผิดชอบ (column property vs index strategy) — Reader ที่อยากรู้ unique ดูที่ Index Strategy ได้
- **No Fallback:** ถ้า Environment ไม่รองรับก็ต้องส่ง Mermaid Source Code

### 10. File Finalization & Delivery (Source of Truth)

> **หมายเหตุ:** กฎข้อ 10 นี้คือ **source of truth** เรื่องไฟล์ output — Output Format section ด้านล่าง / sub-skill ทุกตัว ต้องอ้างอิงตามนี้ ห้ามขัดกัน

- **Trigger Condition:** เมื่อ SA Review ยืนยัน "สมบูรณ์ / Approved / Final" ให้ Finalize ทันที
- **File Naming Convention (บังคับ):** ทุกไฟล์ใช้ **UPPER_SNAKE_CASE** สำหรับ prefix + `<Module>` ตามด้วยส่วนขยาย
  - `<Module>` เป็น PascalCase หรือ snake_case ที่สื่อ Business Module
  - ห้ามชื่อกว้าง (Spec, Final, Doc, Test)
  - **Composite Module (สำหรับ Module ใหญ่ที่ต้องแยกเป็นหลายส่วน):** ไม่ต้องแตกเป็นหลายไฟล์ Spec — ให้ใช้ชื่อแบบ composite `<Parent>_<Sub>` เช่น `DB_SPEC_CashFlow_Receive.md`, `DB_SPEC_CashFlow_Pay.md`
- **Mandatory Companion File Split (บังคับ):** ต้อง output เป็น **หลายไฟล์แยกตามหน้าที่** — ห้ามรวมเป็นไฟล์เดียว

  | # | ไฟล์ | เนื้อหา | เงื่อนไขการสร้าง | ผู้สร้าง |
  |---|------|---------|------------------|----------|
  | 1 | `DB_SPEC_<Module>.md` | Main Spec (Header, Business Context, ERD, Data Dictionary, Index, **Sample Data preview 2-3 records/table**, Conversion Report ถ้า Convert) — **ERD ฝัง mermaid block ใน DB_SPEC** | **เสมอ** | `db-create-spec` (orchestrator) |
  | 2 | `CHANGELOG_<Module>.md` | Write Log (old version บน → new version ล่าง) ตามกฎข้อ 3 | **เสมอ** | `db-create-spec` (orchestrator) |
  | 3 | `IMPACT_<Module>.md` | **Impact List + Verification** (variant ตาม Mode — ดู `db-impact-change-analyst` Trigger Condition table) — **ไม่มี Rollback SQL** (อยู่ใน ROLLBACK file #8) | **เสมอทุก Mode** (Mode New greenfield = variant Verification-only) | `db-impact-change-analyst` |
  | 4 | `SAMPLE_DATA_<Module>.md` | **Markdown documentation only** — ตารางอธิบาย Sample Data ≥10 records/table (ไม่มี INSERT SQL — อยู่ใน INSERT file #5) | **เสมอ** (ยกเว้น reference table ที่ SA ไม่ได้ให้ข้อมูล — ดูกฎข้อ 2) | `db-create-sample-data` |
  | 5 | `INSERT_<Module>.sql` | **Executable SQL** — INSERT statements ทั้งหมด (≥10 records/table) — Cross-link กับ SAMPLE_DATA.md | **เสมอ** | `db-create-sample-data` |
  | 6 | `PACK_INSTALL_<Module>.sql` | **DB + Tables + Constraints เท่านั้น** (Section 0 CREATE DATABASE, Section 1 CREATE TABLES, Section 3 ADD CONSTRAINTS) — **ไม่รวม INDEX, INSERT, ROLLBACK, SP** (แยกไฟล์) | **เสมอ** | `db-create-schema` |
  | 7 | `INDEX_<Module>.sql` | **CREATE INDEX statements เท่านั้น** — run หลัง PACK_INSTALL | **เสมอ** | `db-create-index` |
  | 8 | `ROLLBACK_<Module>.sql` | **DROP statements** (reverse order: drop child → parent → database) | **เสมอ** | `db-create-schema` |
  | 9 | `STORED_PROCEDURE_<Module>.sql` | Stored Procedure / Function source code ทั้งหมดของ Module | **เฉพาะเมื่อ Module มี SP / Function** | `db-create-procedure` |
  | 10 | `CONVERT_<Module>.md` | บอกว่า convert **module ไหน** จาก Source DBMS → Target DBMS, Data Type Mapping ฉบับเต็ม (ไม่ใช่ Conversion Report — Conversion Report อยู่ใน DB_SPEC) | **เฉพาะ Mode Convert** | `db-create-schema` |
  | 11 | `REVIEW_LOG_<Module>.md` | Review Round (Rejected, Approved with Modification, Approved As-Is) + Approval Block (signature/initial) + Compliance Checklist | **สร้างตอน Re-Confirmation Before Write รอบแรก / append ทุก review round** | `db-create-spec` (orchestrator) |

  **🔢 Install Order (เมื่อ deploy):**
  1. Run `PACK_INSTALL_<Module>.sql` — สร้าง database + tables + constraints
  2. Run `INDEX_<Module>.sql` — สร้าง indexes
  3. Run `INSERT_<Module>.sql` — load sample/reference data (optional)
  4. Run `STORED_PROCEDURE_<Module>.sql` — สร้าง SP (ถ้ามี)

  **🔙 Rollback:** Run `ROLLBACK_<Module>.sql` แยก (เมื่อต้องการ teardown)

- **🚨 No GO Statements (MSSQL — บังคับทุก SQL companion file):** สำหรับ MSSQL (SQL Server) **ห้ามใช้ `GO` batch separator** ใน SQL companion files ทั้ง **5 ไฟล์** ต่อไปนี้:

  | # | ไฟล์ | บังคับ No GO | ผู้สร้าง / กฎเฉพาะ |
  |---|------|:------------:|---------------------|
  | 1 | `PACK_INSTALL_<Module>.sql` | ✅ | `db-create-schema` |
  | 2 | `INDEX_<Module>.sql` | ✅ | `db-create-index` |
  | 3 | `INSERT_<Module>.sql` | ✅ | `db-create-sample-data` |
  | 4 | `ROLLBACK_<Module>.sql` | ✅ | `db-create-schema` |
  | 5 | `STORED_PROCEDURE_<Module>.sql` | ✅ (ต้องใช้ workaround — ดู `db-create-procedure`) | `db-create-procedure` |

  **เหตุผล (บังคับเข้าใจก่อน apply):**
  - **Portability:** `GO` ไม่ใช่ T-SQL keyword — เป็น batch separator เฉพาะของ SSMS / sqlcmd ตัว parser อื่น (programmatic deploy ผ่าน ADO.NET, JDBC, ORM migration tool เช่น Flyway/Liquibase/EF Migrations) ตีความไม่ได้ → script run ไม่ได้
  - **CI/CD friendliness:** Pipeline deploy ผ่าน Azure DevOps / GitHub Actions ที่ใช้ `Invoke-Sqlcmd` หรือ `sqlpackage` รองรับ GO แต่ถ้าใช้ generic SQL executor จะ fail — เลี่ยง GO ไปเลยปลอดภัยกว่า
  - **Idempotency:** Script ที่ไม่มี GO สามารถ wrap ใน TRANSACTION เดียวได้ — rollback atomic
  - **SSMS ยังรันได้:** SSMS เห็น script ไม่มี GO → run ทั้งหมดเป็น batch เดียว ซึ่งใช้ได้ปกติ (ยกเว้น CREATE PROCEDURE / CREATE FUNCTION / CREATE TRIGGER / CREATE VIEW ที่ต้องเป็น first statement ใน batch — ดู workaround ใน `db-create-procedure`)

  **Lint Check ก่อน Finalize (บังคับ):** AI ต้อง grep ทุก SQL companion file หา standalone `GO` (line ที่ขึ้นต้นด้วย `GO` หรือมีแค่ `GO` ทั้งบรรทัด — regex: `^\s*GO\s*$`) — หากพบใน MSSQL → **Violation** ต้องแก้ก่อนส่ง
  - Cross-DBMS Note: กฎนี้ apply เฉพาะ **MSSQL** — DBMS อื่น (MySQL, PostgreSQL, Oracle) ไม่มี `GO` keyword จึงไม่กระทบ
  - หาก SA จำเป็นต้องใช้ GO (เช่น integrate กับ deploy tool ที่ require) → ต้องผ่าน **Explicit Skip Confirmation** ตาม Rule 0 + บันทึก reason ใน `REVIEW_LOG_<Module>.md`

  **Workaround สำหรับ statements ที่ปกติต้อง GO (เช่น CREATE PROCEDURE):**
  - Option A: ใช้ Dynamic SQL — `EXEC(N'CREATE PROCEDURE sp_xxx ... ')`
  - Option B: แยก SP เป็นไฟล์ย่อยๆ + ให้ deploy tool concatenate (รายละเอียดอยู่ใน `db-create-procedure.md`)
  - Option C: ใช้ `;` (semicolon) เป็น statement terminator แทน — สำหรับ statements ที่ไม่ require batch boundary

- **Cross-Reference (บังคับ 2 ทาง):** ทุก companion file ต้องมี Related Files / Related Spec link กลับ `DB_SPEC_<Module>.md` และ DB_SPEC ก็ต้องมี link ไปยัง companion ทุกไฟล์ที่สร้าง
- **DB_SPEC Header Fields (บังคับ):** หัวไฟล์ `DB_SPEC_<Module>.md` ต้องมี:
  ```markdown
  | Field | Value |
  |-------|-------|
  | **Module** | <Module Name> |
  | **DBMS** | <DBMS> v<Version> |
  | **Collation** | <Latin1_General_100_BIN2_UTF8 หรือ DBMS equivalent — บังคับ Rule 12> |
  | **Mode** | New / Modify / Convert |
  | **Author (SA)** | <name> |
  | **Created Date** | YYYY-MM-DD |
  | **Last Updated** | YYYY-MM-DD |
  | **Current Version** | v<x.y> (link → CHANGELOG_<Module>.md) |
  | **Reviewer(s)** | <name(s)> |
  | **Approval Status** | 🟡 In Review / 🟠 Approved with Modification / ✅ Approved / 🔴 Rejected |
  | **Approval Date** | YYYY-MM-DD (ว่างถ้ายังไม่ approve) |
  ```
- **REVIEW_LOG Lifecycle (Cross-Cutting — ไม่อยู่ใน Operation Flow ของ Mode ไหน):**

  ไฟล์ `REVIEW_LOG_<Module>.md` มี lifecycle ของตัวเองที่ทำงานคู่ขนานกับ Operation Flow ทุก Mode (New / Modify / Convert) — orchestrator (`db-create-spec`) เป็นผู้รับผิดชอบ append round ทุกครั้งที่มี Re-Confirmation event โดยไม่ขึ้นกับ step number ของ Mode

  **Lifecycle Events ที่ trigger การเขียน REVIEW_LOG:**

  | Event | สิ่งที่เขียนลง REVIEW_LOG | Status หลัง event |
  |-------|---------------------------|--------------------|
  | E1. **Re-Confirmation Before Write ครั้งแรก** | สร้างไฟล์ + Round 1 (Scope of Review, Reviewer list, ยังไม่มี Decision) | 🟡 In Review |
  | E2. **SA Reject บางรายการ** | Append "Rejected Items + Reason + Alternative" ใน Round ปัจจุบัน | 🟠 Approved with Modification หรือ 🔴 Rejected |
  | E3. **SA ขอแก้ใหม่ (loop)** | ปิด Round เก่า, เปิด Round ใหม่ (Round 2, 3, ...) | 🟡 In Review (รอบใหม่) |
  | E4. **SA Approve ทั้งหมด** | เติม Approval Block (signature/initial ของ Reviewer ทุกคน), Final Approval Date, Approved Version | ✅ Approved |
  | E5. **Reject ทั้งหมด (terminate)** | บันทึก Reason of Termination | 🔴 Rejected |

  **กฎเสริม:**
  - Status flow: `🟡 In Review` → `🟠 Approved with Modification` → `✅ Approved` หรือ `🔴 Rejected`
  - Sign-off Roles: บังคับมี **SA Lead** + อย่างน้อย 1 บทบาท (DBA / Tech Lead / PM) — กรณี Risk 🔴 ต้อง 2 บทบาทขึ้นไป
  - **Solo SA Exception:** หาก project มี SA คนเดียว (small team) → ระบุไว้ใน Header ของ REVIEW_LOG ว่า "Solo SA — self-review" และยังคงต้องมี signature/initial ของ SA เอง
  - Approved Version ใน `REVIEW_LOG` ต้อง **sync** กับ version ใน `CHANGELOG` — กลไก: orchestrator เขียน CHANGELOG entry **หลัง** ได้ ✅ Approved จาก REVIEW_LOG (ทำตาม order: Approve → CHANGELOG → Finalize files)
  - Round numbering append-only (Round 1, 2, 3, ...) — เก่าอยู่บน, ใหม่อยู่ล่าง (เหมือนกฎข้อ 3 Log Ordering)

  **🚨 Post-Approval Substantive Change → Auto Mode Modify Transition + Version Bump (บังคับ):**

  หาก Round N+1 ของ REVIEW_LOG มี **substantive change** ต้องการให้แก้หลังจาก Round N ได้ ✅ Approved ไปแล้ว → AI ต้อง **AUTO**:

  **Step 1 — Classify Change Type:**

  | Change Type | Examples | Action |
  |-------------|----------|--------|
  | **Substantive — Minor** | Add nullable column, add index, แก้ SP body, แก้ comment ใน DDL, add audit column | Mode Modify + bump `vN.minor+1` (e.g. v1.0 → v1.1) ตาม Rule 3 |
  | **Substantive — Breaking** | **Rename column**, drop column, rename table, add NOT NULL constraint บน column ที่มี data, type change, add FOREIGN KEY ที่ break existing data, Convert ข้าม DBMS | Mode Modify + bump `vN+1.0` (e.g. v1.0 → v2.0) ตาม Rule 3 |
  | **Non-Substantive** | Typo fix ใน description, comment improve, format cleanup, fix markdown rendering | **ไม่ bump version** — แค่ update `Last Updated` ใน Header |

  **Step 2 — Pre-Release Exception (Auto-Ask SA):**

  หาก `Approval Status` ปัจจุบัน = ✅ Approved แต่ spec ยัง **pre-release** (ยังไม่ deploy production) → AI ต้อง `AskUserQuestion`:
  ```
  "Round N+1 มี <change type> — ตาม Rule 3 ต้อง bump เป็น <vN+1.0>
   แต่ spec ยัง pre-release (v<current> ยังไม่ go-live, ไม่มี downstream consumer)
   ต้องการ bump เป็น:
     1) v<N.minor+1> (pre-release patch — แนะนำ)
     2) v<N+1.0>     (strict Rule 3 breaking — เครื่องครัดตามตัวอักษร)
     3) ไม่ bump     (in-place edit — ต้องระบุเหตุผลใน REVIEW_LOG, จำกัดสำหรับ internal QA only)
  ```

  **Step 3 — Auto-Execute Mode Modify Cycle:**

  หลัง SA ตัดสิน version → AI:
  1. Transition จาก Mode New → Mode Modify cycle (Step 1-7 ของ Mode Modify)
  2. **Append CHANGELOG entry ใหม่ (Variant 2 — Modify/Convert)** — ห้าม in-place edit entry ที่ approved แล้ว
  3. Update DB_SPEC Header: `Current Version`, `Last Updated`, `Approval Status`
  4. Append Round N+1 ใน REVIEW_LOG พร้อม Compliance Checklist ใหม่ (re-evaluate)
  5. Re-run Self-Audit Report (Rules 0-12)

  **🚨 Anti-Pattern (ห้ามทำ — Compliance Violation):**

  - ❌ **In-place edit ของ CHANGELOG entry ที่ approved แล้ว** → violate Rule 3 audit trail (Versioning Convention) + Rule 6 Version Control Mindset
  - ❌ **Edit DB_SPEC schema (rename/drop/add NOT NULL) โดยไม่ bump version** → violate Rule 3 + ทำให้ DB_SPEC vs CHANGELOG vs REVIEW_LOG desync
  - ❌ **AI proceed substantive change โดยไม่ AskUserQuestion** → violate Rule 0 Strict Compliance + Rule 3 Step-by-Step Validation
  - ❌ **Skip Step 2 Pre-Release Exception** → AI ต้องเสนอ choice เสมอ ห้าม auto-decide v1.x vs v2.0 เอง

  **ทำไมแยกออกจาก Operation Flow:** เพราะ Re-Confirmation อาจเกิดได้หลายครั้งโดยไม่ขึ้นกับว่าอยู่ Step ไหน — บางครั้งติด Reject ที่ Step 3 (ERD) แล้ววนกลับไป Step 2 ใหม่; การฝัง REVIEW_LOG ลง Mode flow จะทำให้ flow ดูซับซ้อนเกินจริง

  **🚨 Compliance Checklist (บังคับ — AI Auto-Evaluation, ใส่ทุก Round ใน REVIEW_LOG):**

  > **กฎเหล็ก:** ทุกข้อใน Compliance Checklist เป็น **AI Auto-Check** — AI ต้องประเมินผลด้วยตัวเอง และระบุ Status ทันที (✅ / ❌ / ⚠️) **ห้ามใส่ ⏳ Pending** หรือเว้นว่างให้ Human ทำเอง
  >
  > **Role separation:**
  > - **AI Auto-Check (ขั้นนี้):** mechanical evaluation — ให้คะแนน ✅/❌/⚠️ + evidence ที่ชัดเจน
  > - **Human Review (ขั้นถัดไป):** verify AI findings — ดู AI evaluation แล้วเลือก agree หรือ override (override ต้องระบุเหตุผลใน Sign-off Block)

  **Status Definition:**

  | Symbol | Meaning | เมื่อไหร่ใช้ |
  |:------:|---------|-------------|
  | ✅ Pass | AI ตรวจแล้วผ่าน 100% | All items conform to rule |
  | ❌ Fail | AI ตรวจแล้วพบ violation ชัดเจน | มี items ที่ violate กฎ (ระบุชื่อใน Evidence) |
  | ⚠️ N/A หรือ Grandfathered | AI ตรวจไม่ได้ หรือเป็น exception | (a) ไม่มี objects ให้ตรวจ (เช่น ไม่มี SP) หรือ (b) Module legacy ที่ accept exception |

  **Template (AI ต้อง fill Status + Evidence + Note ทุกบรรทัดก่อนส่ง):**

  ```markdown
  ### Compliance Checklist (Round <N>) — AI Auto-Evaluation

  | # | Check Item | Status | Evidence (AI Findings) | Note |
  |---|-----------|:------:|------------------------|------|
  | 1 | ไม่พบ Reserved word (Extended set — incl. Sybase legacy + ANSI extended) | ✅ | สแกน 4 sources (CSV + MSSQL extended + ODBC + Future), พบ 0 violation. Reserved พบที่ `CASH_MOVEMENT.type` ถูก rename เป็น `cashmovementtype` แล้ว (CSV row appended) | — |
  | 2 | snake_case / lowercase ทั้งหมด (**database name + table + column + index + SP + variable**) | ❌ | พบ database name `DataOcean` (PascalCase) + 240 columns ใน 10 tables ใช้ UPPER_SNAKE | Grandfathered Module — pre-existing names per Preserve Exact Names Rule. Forward-only fix |
  | 3 | Table/Index name ไม่ซ้ำ | ✅ | Parse PACK_INSTALL Section 1-2: 10 unique table names, 23 unique index names | — |
  | 4 | Index = `<table>_idx<N>` | ❌ | พบ 23 indexes ใช้ pattern `UX_*`, `IX_*` (เช่น `UX_DATA_ORDER_BIZKEY`) — ไม่ใช่ `<table>_idx<N>` | Grandfathered — forward-only fix |
  | 5 | Datatypes ตาม Data Dict | ⚠️ | Sample check 50 columns pass. 4 columns flagged: STOCK_MOVEMENT.SEQNO เป็น DECIMAL(20,0) — น่าจะเป็น BIGINT | Open Items #18 รอ SA verify |
  | 6 | NVARCHAR (MSSQL Unicode) | ❌ | grep PACK_INSTALL: พบ 167 columns ใช้ `VARCHAR(N) COLLATE` — ควรเป็น `NVARCHAR` | Grandfathered — created before NVARCHAR rule. Forward-only fix |
  | 7 | Collation = Latin1_General_100_BIN2_UTF8 | ✅ | PACK_INSTALL Section 0: `CREATE DATABASE COLLATE Latin1_General_100_BIN2_UTF8`. Section 1: ทุก text column มี `COLLATE Latin1_General_100_BIN2_UTF8` | — |
  | 8 | ทุก table มี PK | ✅ | 10/10 tables มี `<TABLE>_KEY BIGINT IDENTITY(1,1) PRIMARY KEY` | — |
  | 9 | PK = UNIQUE + NOT NULL | ✅ | `BIGINT IDENTITY(1,1)` auto-implies UNIQUE + NOT NULL ทั้ง 10 tables | — |
  | 10 | **Version Consistency** (DB_SPEC = CHANGELOG = REVIEW_LOG) | ✅ | DB_SPEC Header `Current Version: v1.0` == CHANGELOG latest entry `v1.0` == REVIEW_LOG `Approved Version: v1.0`. Substantive changes since last approval: 0 → no bump required | — |
  | 11 | **Reserved Word — Extended set coverage** (Sybase legacy + ANSI extended + ODBC) | ✅ | สแกน MSSQL Extended list (~250 keywords incl. STATUS, TYPE, LEVEL, STATE, DATA, ROLE, METHOD, RESULT, ฯลฯ) — 0 standalone violations พบ | Replaces narrow Microsoft-strict scope used in earlier skill versions (ที่เคย miss `STATUS`) |
  | 12 | **No GO statements ใน 5 SQL companion files (MSSQL only)** — PACK_INSTALL, INDEX, INSERT, ROLLBACK, STORED_PROCEDURE | ✅ | (MSSQL only) Grep ทุก 5 ไฟล์ด้วย regex `^\s*GO\s*$` — 0 occurrences. รายงาน per-file: PACK_INSTALL 0/X, INDEX 0/Y, INSERT 0/Z, ROLLBACK 0/W, STORED_PROCEDURE 0/V (X-V = total lines). STORED_PROCEDURE ใช้ Dynamic SQL wrapping (`EXEC(N'CREATE PROCEDURE...')`) หรือ multi-file split ตามกฎ workaround | N/A สำหรับ DBMS อื่น (MySQL/PostgreSQL/Oracle ไม่มี GO keyword) |

  **AI Auto-Evaluation Summary:**
  - **Pass:** 6 (items 1, 3, 7, 8, 9, 10, 11)
  - **Fail:** 3 (items 2, 4, 6) — all flagged as ⚠️ Grandfathered (forward-only)
  - **N/A / Borderline:** 1 (item 5 — borderline, รอ SA verify)
  - **Effective Block Status:** ✅ No block (Fail items เป็น Grandfathered ทั้งหมด — accepted exception)

  **AI Recommendation to Human Reviewer:**
  > AI ตรวจแล้วเสนอ Approve โดยมีเงื่อนไข: ✅ Approve as-is + บันทึก Grandfather note ใน CHANGELOG / 🔴 Reject ถ้าต้องการ retrofit ทันที (จะกลายเป็น v2.0 breaking change)
  ```

  **AI Auto-Evaluation Logic per Item (วิธีที่ AI ใช้ตรวจ):**

  | # | Check Logic ที่ AI ต้องทำ |
  |---|--------------------------|
  | 1 | สแกนชื่อ table + column ทุกตัวใน DB_SPEC §4.1 เทียบกับ 4 sources (CSV / MSSQL Extended / ODBC / Future) ตาม `db-rename-reserved-word`. Pass = 0 unrenamed reserved found |
  | 2 | Regex test **ทั้ง database name + table + column + index + SP + variable**: match `^[a-z][a-z0-9_]*$` (snake_case) หรือ `^[a-z][a-z0-9]*$` (lowercase). Fail = ระบุชื่อที่ violate (max 5 examples). **ดู PACK_INSTALL Section 0** (CREATE DATABASE) สำหรับ database name check |
  | 3 | Parse PACK_INSTALL Section 1-2 → list unique names → check count = expected (e.g., 10 tables = 10 unique names) |
  | 4 | Regex test ทุก index name: match `^[a-z][a-z0-9_]*_idx[0-9]+$`. Fail = ระบุ index ที่ violate |
  | 5 | Cross-reference DB_SPEC Data Dict กับ source Data Dict file (Excel/CSV/etc.) — ถ้าไม่มี source หรือ data type ไม่ตรง → ⚠️ borderline |
  | 6 | (MSSQL only) grep PACK_INSTALL Section 1 หา `VARCHAR(` (without N prefix). Pass = 0 occurrences |
  | 7 | grep PACK_INSTALL Section 0 หา `COLLATE Latin1_General_100_BIN2_UTF8` (หรือ equivalent) + Section 1 ทุก text column มี COLLATE inline |
  | 8 | Parse PACK_INSTALL Section 1 → count `CREATE TABLE` statements vs `PRIMARY KEY` clauses (ต้องเท่ากัน) |
  | 9 | Parse PK column definitions → verify `NOT NULL` + (auto-increment / IDENTITY / SERIAL) หรือ UNIQUE constraint |
  | 10 | **Version Consistency:** Extract version จาก 3 ไฟล์: (a) DB_SPEC Header `Current Version` (b) CHANGELOG latest entry (c) REVIEW_LOG `Approved Version`. Pass = all 3 match. ตรวจเพิ่ม: ถ้า Round N+1 มี Changes Made section ที่เป็น substantive (rename/drop/add NOT NULL/type change) แต่ version ไม่ bump → ❌ Fail + flag เป็น "in-place edit anti-pattern" (Rule 6) |
  | 11 | **Reserved Word — Extended set:** เหมือน item #1 แต่ scope ครอบคลุม MSSQL Extended list (Sybase legacy + ANSI extended + ODBC unified) ใน `db-rename-reserved-word.md` Source 2. หากพบ standalone match → ❌ Fail + เสนอ rename ผ่าน Company Type-Prefix Convention (`s_`, `n_`, `d_`, `t_`, `f_`) |
  | 12 | **No GO Statements (MSSQL):** หาก DBMS = MSSQL → grep ทุก 5 SQL companion files (PACK_INSTALL, INDEX, INSERT, ROLLBACK, STORED_PROCEDURE) ด้วย regex `^\s*GO\s*$`. Pass = 0 occurrences ในทุกไฟล์. หากเจอ → ❌ Fail + ระบุ file + line. สำหรับ STORED_PROCEDURE — verify ว่าใช้ Dynamic SQL wrapping หรือ multi-file split ตาม workaround. หาก DBMS ≠ MSSQL → ⚠️ N/A (ไม่ apply) |

  **กฎเสริมของ Checklist:**
  - **ทุก ❌ Fail** = ปกติ block production — **ยกเว้น** flagged เป็น `⚠️ Grandfathered` (มี justification) → AI mark "Effective Block Status: No"
  - **⚠️ Grandfathered** ใช้กับ Module ที่สร้างก่อนกฎใหม่ + SA ตัดสินใจ "forward-only" (D1) → Fail ไม่ block แต่ต้องระบุใน Note + link CHANGELOG decision
  - **⚠️ N/A** ใช้เมื่อไม่มี object ให้ตรวจ — เช่น "Module ไม่มี SP จึงไม่ต้องเช็ค SP variables naming"
  - **Append per Round:** ทุก Round ต้องมี Checklist ใหม่ — Re-evaluate ทุกครั้ง (อาจมีผลต่างกันหลัง remediation)
  - **AI ห้ามทิ้ง ⏳ Pending:** ถ้า AI ตรวจไม่ได้จริงๆ ให้ใช้ ⚠️ + ระบุเหตุผลว่าทำไมตรวจไม่ได้ (เช่น "ไม่มี Data Dict source file ให้ verify item 5")
  - **Cross-reference:** Checklist Fail items ควร mirror ใน Open Items ของ DB_SPEC (Rule 6)
- **Content Completeness:** ครบทุกหัวข้อ ไม่มี Draft/TODO/Pending เหลือก่อน Finalize
- **Re-Confirmation Before Write:** สรุปสิ่งที่จะ Output (รายชื่อไฟล์ + หัวข้อ) ให้ยืนยันก่อน Generate

### 11. Database Conversion (สำหรับ Mode Convert)

- **Source & Target Confirmation (บังคับ):** ถาม Source DBMS + Target DBMS แบบ Choice-Based พร้อม Version
- **SQL File Auto-Detect:** ถ้า SA แนบ `.sql` ให้วิเคราะห์ Source DBMS จาก Syntax แล้วเสนอผลให้ SA ยืนยัน
- **Data Type Comparison Table (บังคับ):** เสนอตาราง `| Table.Column | Source Type | Target Type | Precision/Length Change | Risk Note |` ก่อน Generate DDL ใหม่
- **Unsupported Feature Report (บังคับ):** รายงาน Built-in Functions, Check Constraints, Stored Procedures, Triggers, Sequence/Identity, Package, Materialized View ที่ Target ไม่รองรับหรือต่างกัน
- **Non-Convertible Objects & Workaround (บังคับ):** ตาราง `| Source Object | Type | Why Not Convertible | Proposed Workaround |`
- **Trigger & Constraint Behavior Warning (บังคับ):** เตือน Trigger Order, CASCADE Behavior, Check Constraint Enforcement (MySQL <8.0.16), Default Value, Case Sensitivity
- **Two Output Locations (สำคัญ — ห้ามสับสน):**
  1. **`CONVERT_<Module>.md`** (สร้างโดย `db-create-schema`) — บอก meta ของการ convert:
     - **Module ที่กำลัง convert** (ชื่อ Module)
     - **Source DBMS + Version** → **Target DBMS + Version**
     - Data Type Mapping Table ฉบับเต็ม
     - Unsupported Features + Workaround Table
     - ไฟล์นี้ใช้เพื่อบอก "**เราจะไป DB ตัวไหน convert มาจากตัวเดิม**"
  2. **Conversion Report ภายใน `DB_SPEC_<Module>.md`** (เก็บใน Main Spec — เหมือนเดิม) — เป็นการ **Compare** ระหว่าง Source ↔ Target:
     - ตาราง Compare Schema เดิม vs ใหม่
     - บอกว่า "**แก้จากอะไรเป็นอะไร**"
     - Behavior Warning, Migration Plan + Rollback
- **Migration Plan:** Order (Schema → Reference Data → Transaction Data → Index → Trigger → Procedure) + Rollback (อยู่ใน Conversion Report ภายใน DB_SPEC)

### 12. Collation Enforcement (🚨 Critical — บังคับทุก DBMS)

> **กฎเหล็ก:** ทุก Schema / Table / Column ที่เป็น text type ต้องใช้ Collation `Latin1_General_100_BIN2_UTF8` (MSSQL baseline) หรือ equivalent ของ DBMS อื่น เท่านั้น — ห้ามใช้ Collation อื่น (เช่น `SQL_Latin1_General_CP1_CI_AS`, `Thai_CI_AS`, `utf8mb4_general_ci`, ฯลฯ) เด็ดขาด
>
> **🚨 Text Type Selection (Company Standard — บังคับ):**
> - **MSSQL:** ใช้ **`NVARCHAR`** (Unicode UTF-16) เป็น default สำหรับ text column ทุกตัว — **ห้ามใช้ `VARCHAR`** เพื่อความมั่นใจในการเก็บข้อมูล Unicode (ภาษาไทย, จีน, emoji)
> - **MySQL/MariaDB:** ใช้ `VARCHAR` + `utf8mb4` charset
> - **PostgreSQL:** ใช้ `VARCHAR` (default ของ PG รองรับ UTF-8 อยู่แล้ว)
> - **Oracle:** ใช้ `NVARCHAR2` หรือ `VARCHAR2` (ตาม database character set AL32UTF8)
>
> **เหตุผลที่บังคับ NVARCHAR สำหรับ MSSQL:**
> - 100% Unicode support (UTF-16 storage) ไม่ต้องกังวล character corruption
> - ทำงานได้ทุก MSSQL version (2008+) ไม่ผูกกับ 2019+
> - Tooling / ORM ส่วนใหญ่ตีความ NVARCHAR เป็น Unicode โดยอัตโนมัติ
> - **Trade-off:** เปลือง storage 2x สำหรับ ASCII-heavy data (acceptable — disk cheap, Unicode safety สำคัญกว่า)

**เหตุผล:**
- **Binary comparison (BIN2)** → ไม่มี locale dependency, sort/compare ผลลัพธ์ deterministic ทุก server / OS
- **UTF-8 storage** → รองรับภาษาไทย, จีน, อังกฤษ, emoji ใน column เดียวกัน ไม่ต้องแยก `NVARCHAR` vs `VARCHAR`
- **Case + Accent Sensitive** (เพราะ BIN2) → ป้องกัน data duplication จาก case folding (เช่น `'admin'` vs `'Admin'`)
- **Cross-DBMS consistency** → migration / replication ระหว่าง DBMS ให้ผลเทียบเท่ากัน

**Collation Equivalent Mapping (บังคับ — เลือกตาม DBMS ที่ SA ระบุใน Rule 8):**

| DBMS | Text Type | Collation ที่ต้องใช้ | Encoding / Storage | หมายเหตุ |
|------|-----------|---------------------|--------------------|---------|
| **MSSQL (SQL Server)** | **`NVARCHAR`** (บังคับ — ห้าม VARCHAR) | `Latin1_General_100_BIN2_UTF8` | UTF-16 (2-4 bytes/char) | Baseline. ใช้ได้ทุก version (2008+) ปลอดภัย 100% สำหรับ Unicode |
| **MySQL / MariaDB** | `VARCHAR` | `utf8mb4_bin` | `utf8mb4` (UTF-8 variable) | Binary, case + accent sensitive, รองรับ 4-byte UTF-8 (emoji) |
| **PostgreSQL** | `VARCHAR` | `C` (with `LC_COLLATE='C'`) + Database encoding `UTF8` | UTF-8 | Binary collation, deterministic ordering. ใช้ `CREATE DATABASE ... ENCODING 'UTF8' LC_COLLATE 'C' LC_CTYPE 'C' TEMPLATE template0` |
| **Oracle** | `NVARCHAR2` หรือ `VARCHAR2` | `BINARY` (NLS_SORT) + `NLS_COMP=BINARY` | `AL32UTF8` (database character set) | Binary sort, UTF-8 storage |
| **DB2** | `VARGRAPHIC` หรือ `VARCHAR` | `IDENTITY` collation | `UTF-8` codeset | `CREATE DATABASE ... USING CODESET UTF-8 COLLATE USING IDENTITY` |
| **SQLite** | `TEXT` | `BINARY` (default) | UTF-8 (default) | SQLite ใช้ binary + UTF-8 by default — ไม่ต้องระบุ explicit |
| **Informix** | `NVARCHAR` หรือ `LVARCHAR` | `db_locale='en_US.utf8'` + `client_locale='en_US.utf8'` | UTF-8 | Binary comparison via locale `en_US.utf8` |

**Apply Level (บังคับครบ 3 ระดับ):**

1. **Database Level** — `CREATE DATABASE` ต้องระบุ Collation / Encoding ตามตารางข้างต้น
2. **Table Level** — `CREATE TABLE` ระบุ Collation ของ table (ถ้า DBMS รองรับ — MSSQL/MySQL/MariaDB)
3. **Column Level** — ทุก column ที่เป็น text type (`CHAR`, `VARCHAR`, `NCHAR`, `NVARCHAR`, `TEXT`) **ต้องระบุ `COLLATE` clause** ใน column definition

**ตัวอย่าง DDL ที่ถูกต้อง:**

```sql
-- MSSQL (SQL Server 2008+) — บังคับ NVARCHAR + No GO (ตามกฎ Rule 10)
CREATE DATABASE MyDB COLLATE Latin1_General_100_BIN2_UTF8;
USE MyDB;
CREATE TABLE customer (
    customer_id   INT PRIMARY KEY,
    customer_name NVARCHAR(100) COLLATE Latin1_General_100_BIN2_UTF8 NOT NULL,
    email         NVARCHAR(255) COLLATE Latin1_General_100_BIN2_UTF8 NOT NULL
);

-- MySQL 8.0+
CREATE DATABASE my_db CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
USE my_db;
CREATE TABLE customer (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
    email        VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL
) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- PostgreSQL
CREATE DATABASE my_db ENCODING 'UTF8' LC_COLLATE 'C' LC_CTYPE 'C' TEMPLATE template0;
\c my_db
CREATE TABLE customer (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100) COLLATE "C" NOT NULL,
    email        VARCHAR(255) COLLATE "C" NOT NULL
);
```

**Audit & Compliance:**
- **DB_SPEC Header** ต้องเพิ่ม field `Collation` ระบุค่าที่ใช้ (เช่น `Collation: Latin1_General_100_BIN2_UTF8` หรือ `Collation: utf8mb4_bin (MySQL equivalent)`)
- **Data Dictionary** ต้องเพิ่ม column `Collation` แสดงค่าของ column นั้น (ปกติเหมือนกันทั้ง schema — ระบุครั้งเดียวใน Header + Note ในตารางว่า "Default Collation ทั้ง schema")
- **DDL Generation** ทุก text column ต้องมี `COLLATE` clause — Lint check ก่อน Finalize: หาก column text ใดไม่มี `COLLATE` → Violation, ต้องแก้
- **Exception Process:** หาก SA จำเป็นต้องใช้ Collation อื่น (เช่น integrate กับระบบเก่าที่ใช้ `Thai_CI_AS`) → ต้อง **explicit confirm** ตามกฎข้อ 0 (Strict Rule Compliance — Explicit Skip Confirmation) และบันทึก reason ใน `REVIEW_LOG_<Module>.md` พร้อม risk assessment

**Mode Convert Special Note:**
- เมื่อ Convert จาก DBMS ที่ใช้ Collation อื่นไป DBMS ใหม่ → ใน `CONVERT_<Module>.md` ต้องมี section **Collation Mapping** บอกว่า Source collation อะไร → Target collation อะไร + Risk Note (เช่น case-insensitive → case-sensitive อาจทำให้ duplicate keys เผยตัว)

## Operation Flow

### 🚨 Sub-Skill Trigger Enforcement (บังคับสำหรับทุก Mode)

ตามกฎ Rule 4 — orchestrator **ต้องเรียก sub-skill** เมื่อกฎระบุ ห้าม inline ทำเอง:

| เงื่อนไข | ต้องเรียก sub-skill |
|---------|---------------------|
| ออกแบบ Entity Relationship | `db-create-erd` (ห้ามวาด ERD เอง) |
| สร้าง DDL / Data Dictionary / Pack Install | `db-create-schema` |
| เจอ Reserved Word ใน column/table name | `db-rename-reserved-word` (ห้าม rename เอง / silent escape) |
| Index Strategy เพิ่มเติม | `db-create-index` |
| Stored Procedure / Function | `db-create-procedure` |
| Sample Data ≥10 records | `db-create-sample-data` |
| Impact Analysis (Mode Modify/Convert) | `db-impact-change-analyst` |
| Reverse engineer / อธิบาย DB เดิม | `db-summary-spec` |

→ หาก orchestrator ทำเองโดยไม่เรียก sub-skill = compliance violation (Rule 0)

### Mode Selection

เมื่อ user เรียกใช้งาน /db-create-spec ให้ทักทายและ **ถามเพื่อเลือก Mode** พร้อม **ระบุประเภท Database Engine** (กฎข้อ 8) ดังนี้:

```
กรุณาเลือก Mode ที่ต้องการ:
  1) New     — ออกแบบระบบใหม่ทั้งหมด
  2) Modify  — แก้ไข Schema เดิม (ALTER, Add/Drop Column, Impact Analysis)
  3) Convert — แปลง Schema ข้าม DBMS (เช่น DB2 → MySQL)

หาก DB มี Module เยอะ กรุณาระบุขอบเขต Module ที่ต้องการ analyse ด้วย
```

> **หมายเหตุเรื่อง `db-summary-spec`:** Skill นี้เป็น **utility แยก** สำหรับ "อธิบายว่า DB เดิมมีอะไรบ้าง" — ไม่ได้เป็นส่วนหนึ่งของ create/modify/convert flow ดู skill `db-summary-spec` ได้โดยตรงเมื่อ SA ต้องการเข้าใจ DB เดิมก่อนเริ่มงาน (ใช้เป็น preparation step ก่อนเข้า /db-create-spec)

### [Mode: New] — การสร้างระบบใหม่

Tell story and instruction ตาม Step ต่อไปนี้ (เรียก sub-skill ที่ระบุ):

1. **Business Scope:** ถามสรุปว่าระบบใช้ทำอะไร (Story & Context)
2. **ER Diagram:** **เรียก skill `db-create-erd`** เพื่อออกแบบความสัมพันธ์ (Mermaid)
3. **Data Dictionary & Schema:** **เรียก skill `db-create-schema`** เพื่อสร้าง Table, Column, DDL พร้อม Null Constraint Table
4. **Index Optimization:** **เรียก skill `db-create-index`** เพื่อวาง Index ตั้งแต่ต้น
5. **Stored Procedure** *(Optional)***:** **เรียก skill `db-create-procedure`** หากมี Logic ใน DB
6. **Sample Data:** **เรียก skill `db-create-sample-data`** สำหรับทำ Unit Test
7. **SQL Test + Verification:** **เรียก skill `db-test-sql`** ทดสอบ Script — ผลทดสอบเขียนลง `IMPACT_<Module>.md` ส่วน Verification (ถ้าไม่มี SQL เดิม → IMPACT file มีเฉพาะ Verification section)
8. **Self-Audit Report (บังคับ — Rule 0):** Generate audit report กฎ 0-12 → ใส่ใน REVIEW_LOG Round 1 → ถ้ามี violation **หยุด** + แก้ก่อน proceed
9. **Finalize (บังคับ):** Re-Confirmation Before Write → สรุปรายชื่อไฟล์ + หัวข้อ ให้ SA ยืนยัน → สร้างไฟล์ทั้งหมดตามกฎข้อ 10: DB_SPEC, CHANGELOG (v1.0), SAMPLE_DATA, PACK_INSTALL, IMPACT, STORED_PROCEDURE ถ้ามี SP
   > REVIEW_LOG ไม่อยู่ใน Operation Flow โดยตรง — ดู **Rule 10 → REVIEW_LOG Lifecycle** (cross-cutting ทุก Mode)
   > **หลัง Finalize** หาก SA review แล้วต้องการแก้ schema → **ห้าม in-place edit v1.0** — ให้ transition ไป Mode Modify cycle + bump version ตาม **Rule 10 → Post-Approval Substantive Change → Auto Mode Modify Transition**

### [Mode: Modify] — การแก้ไขระบบเดิม

เน้น Impact Analysis ก่อนเสมอ:

1. **Impact Analysis:** **เรียก skill `db-impact-change-analyst`** เพื่อระบุ:
   - Table / Column ที่ถูกกระทบ
   - Program / Module / API / Stored Procedure ที่เกี่ยวข้อง
   - Index ที่ต้องปรับ
   - Permission & Security ที่เปลี่ยน
2. **Schema Change:** **เรียก skill `db-create-schema`** เพื่อสร้าง `ALTER TABLE` หรือ Update Index
3. **Data Migration:** ตรวจสอบ Reference Data ที่ต้อง Update หรือ Migrate
4. **Sample Data Update:** **เรียก skill `db-create-sample-data`** สำหรับเฉพาะ table ที่ถูกแก้ (Preview เฉพาะ table ที่เปลี่ยน)
5. **SQL Test + Verification:** **เรียก skill `db-test-sql`** — ผลทดสอบเขียนลง `IMPACT_<Module>.md` ร่วมกับ Impact List
6. **Self-Audit Report (บังคับ — Rule 0):** Generate audit report กฎ 0-12 → ใส่ใน REVIEW_LOG Round ปัจจุบัน → ถ้ามี violation **หยุด** + แก้ก่อน proceed
7. **Finalize (บังคับ):** Re-Confirmation Before Write → ยืนยัน → append CHANGELOG entry ใหม่ (v1.x หรือ v2.0) + update DB_SPEC + เขียน IMPACT + update STORED_PROCEDURE ถ้ามี
   > REVIEW_LOG ไม่อยู่ใน Operation Flow โดยตรง — ดู **Rule 10 → REVIEW_LOG Lifecycle** (cross-cutting ทุก Mode)

### [Mode: Convert] — การแปลง Schema ข้าม DBMS (talk with Dev)

ใช้กฎข้อ 11 เป็นแกนหลัก พร้อมประสานงานกับ Dev อย่างใกล้ชิด:

1. **Source & Target Confirmation:** ถาม Choice-Based ทั้ง Source/Target DBMS + Version
   - หาก SA แนบ `.sql` → AI วิเคราะห์ Source DBMS แล้วเสนอให้ SA ยืนยัน
   - หากไม่มี → ขอ DDL ของระบบเดิม
2. **Source Schema Parsing:** Parse DDL ต้นทาง list Object ทั้งหมด
3. **Data Type Comparison Table:** เสนอตาราง Source ↔ Target ให้ SA Approve **ก่อน** Generate DDL ปลายทาง
4. **Unsupported Feature Scan:** สแกน Built-in Functions, Check Constraints, SP, Trigger, Sequence/Package
5. **Non-Convertible Objects & Workaround:** เสนอ Workaround ให้ SA เลือก (talk with Dev เพื่อ verify ความเป็นไปได้)
6. **Behavior Warning:** เตือน Trigger, CASCADE, Default Value, Case Sensitivity
7. **Target DDL Generation:** **เรียก skill `db-create-schema`** หลัง Approve mapping — `db-create-schema` จะสร้างทั้ง DDL ใหม่ และไฟล์ `CONVERT_<Module>.md` (ดูกฎข้อ 11)
8. **Migration Plan:** เรียงลำดับ + Rollback Strategy (เขียนลง Conversion Report ภายใน `DB_SPEC_<Module>.md`)
9. **Sample Data Re-generation:** **เรียก skill `db-create-sample-data`** สำหรับ Target DBMS (Sample data ใหม่ตาม dialect ของ Target)
10. **SQL Test + Verification:** **เรียก skill `db-test-sql`** บน Target environment → ผลทดสอบเขียนลง `IMPACT_<Module>.md`
11. **Self-Audit Report (บังคับ — Rule 0):** Generate audit report กฎ 0-12 → ใส่ใน REVIEW_LOG Round ปัจจุบัน → ถ้ามี violation **หยุด** + แก้ก่อน proceed
12. **Finalize (บังคับ):** Re-Confirmation Before Write → ยืนยัน → สร้างไฟล์ครบ: `DB_SPEC` (พร้อม Conversion Report inside), `CHANGELOG` (entry v2.0), `IMPACT`, `SAMPLE_DATA`, `PACK_INSTALL`, `CONVERT_<Module>.md`, `STORED_PROCEDURE` (ถ้ามี SP — rewrite ตาม Target DBMS dialect)
    > REVIEW_LOG ไม่อยู่ใน Operation Flow โดยตรง — ดู **Rule 10 → REVIEW_LOG Lifecycle** (cross-cutting ทุก Mode)

## Sub-Skill Reference

Skill นี้ทำงานร่วมกับ sub-skill ต่อไปนี้ (อยู่คนละโฟลเดอร์ แต่ทำงานร่วมกัน):

| Skill | Purpose | Output File ที่รับผิดชอบ |
|-------|---------|--------------------------|
| `db-create-erd` | สร้าง ER Diagram (Mermaid เท่านั้น) | ฝัง mermaid block ใน DB_SPEC (Entity Relationship section) |
| `db-create-schema` | สร้าง Schema + DDL + Null Constraint Table + Pack Install + Convert | `PACK_INSTALL_<Module>.sql`, `CONVERT_<Module>.md` (เฉพาะ Convert) |
| `db-create-index` | แนะนำและสร้าง Index Strategy | รวมใน `PACK_INSTALL_<Module>.sql` Section 2 + Index Strategy table ใน DB_SPEC |
| `db-create-procedure` | ช่วยสร้าง Stored Procedure (input/output/flow) | `STORED_PROCEDURE_<Module>.sql` (**แยกออกจาก PACK_INSTALL**) |
| `db-create-sample-data` | Generate Sample Data สำหรับ Unit Test | `SAMPLE_DATA_<Module>.md` + preview ใน DB_SPEC |
| `db-test-sql` | รัน SQL ทดสอบก่อนส่ง Dev | ผลทดสอบ → Verification section ใน `IMPACT_<Module>.md` |
| `db-impact-change-analyst` | วิเคราะห์ Impact + รวบรวม Verification | `IMPACT_<Module>.md` |
| `db-rename-reserved-word` | 🏢 Apply Company Type-Prefix Convention เมื่อเจอ Reserved Word (cross-skill utility) | Rename Map กลับ parent + append `references/reserved-word-mapping.csv` |

> **หมายเหตุ:** เมื่อเรียก sub-skill AI ต้องส่งต่อ Context สำคัญ (Module Name, DBMS, Version, Mode) ให้ sub-skill รู้เพื่อทำงานต่อได้ถูกต้อง

> **db-summary-spec ไม่อยู่ในตารางนี้** เพราะเป็น **utility แยก** สำหรับ reverse-engineer / อธิบาย DB เดิม ไม่ได้เป็น sub-skill ของ orchestrator นี้ — เรียกใช้เองได้โดยตรงเมื่อต้องการเข้าใจ DB เดิม
> - Output ของ `db-summary-spec` เป็น **ไฟล์เดียว** `DB_SUMMARY_<Module>.md` (snapshot)
> - **ไม่บังคับ** สร้าง CHANGELOG / IMPACT / REVIEW_LOG เพราะเป็น read-only documentation
> - กฎอื่นๆ (DBMS, Mermaid ERD, Null Constraint format, ภาษา) ยังสืบทอดจาก `db-create-spec`

## Output Format

> ⚠️ **อ้างอิงกฎข้อ 10 เป็น source of truth** สำหรับชื่อไฟล์ เนื้อหา และเงื่อนไขการสร้าง — section นี้เป็น **สรุปเชิง Spec หลัก** เท่านั้น หากขัดกับกฎข้อ 10 ให้ยึดกฎข้อ 10

### ไฟล์ Main: `DB_SPEC_<Module>.md`

โครงสร้างเนื้อหา (ตามลำดับ):

1. **Header Block (บังคับ)** — ตามรูปแบบในกฎข้อ 10 (Module, DBMS, Mode, Author, Created, Last Updated, Current Version, Reviewer, Approval Status, Approval Date)
2. **Related Files (บังคับ)** — link 2 ทางไป companion files ที่สร้าง:
   - `CHANGELOG_<Module>.md`
   - `IMPACT_<Module>.md` (ถ้ามี)
   - `SAMPLE_DATA_<Module>.md`
   - `PACK_INSTALL_<Module>.sql`
   - `CONVERT_<Module>.md` (ถ้า Convert)
   - `REVIEW_LOG_<Module>.md`
3. **Business Context** — สรุปสั้นๆ
4. **Module Scope** — ระบุ Module + Composite parts ถ้ามี (เช่น `CashFlow_Receive`, `CashFlow_Pay`)
5. **Entity Relationship** — Mermaid `erDiagram` เท่านั้น (กฎข้อ 9)
6. **Technical Spec** — Schema, Index, Stored Procedure ตาม DBMS Dialect (ดึงจาก `db-create-schema`)
7. **Data Dictionary + Null Constraint Table** — ตามที่ `db-create-schema` กำหนด (Null Constraint Rule)
8. **Sample Data Preview** — 2-3 records/table (subset ของไฟล์เต็ม) เป็น **standalone section** ใน DB_SPEC (เช่น Section 5) รวม preview ของทุก table ในที่เดียว — Mode Modify ให้ preview เฉพาะ table ที่ถูกแก้
9. **Conversion Report** *(เฉพาะ Mode Convert)* — Compare Source ↔ Target schema, Behavior Warning, Migration Plan + Rollback (ห้ามฝัง Data Type Mapping ทั้งหมด — Mapping เต็มอยู่ใน `CONVERT_<Module>.md`)
10. **🚨 Open Items (บังคับตาม Rule 6 — Borderline Coverage)** — list ทุก borderline case ที่ AI ตัดสินใจ default แต่ SA ต้อง verify:
    ```markdown
    ## Open Items

    | # | Item | Type | AI Decision | SA Action Required |
    |---|------|------|-------------|---------------------|
    | 1 | ... | Borderline (prefix/description/data type/behavior/edge case) | ... | ... |
    ```
    - หาก Spec ผ่าน Self-Audit แต่ไม่มี Open Items เลย → ต้อง justify ว่า "No borderline cases found" + SA confirm

### ไฟล์ Companion อื่น

ดูรายละเอียดในกฎข้อ 10 ตาราง Mandatory Companion File Split:
- `CHANGELOG_<Module>.md` — Write Log (เก่า → ใหม่ ตามกฎข้อ 3)
- `IMPACT_<Module>.md` — Impact + Verification
- `SAMPLE_DATA_<Module>.md` — ≥10 records/table
- `PACK_INSTALL_<Module>.sql` — ไฟล์เดียวรวม DDL + Index + Constraints + Sample Data (**ไม่รวม SP**)
- `STORED_PROCEDURE_<Module>.sql` — SP / Function ทั้งหมด (แยกออกจาก PACK_INSTALL)
- `CONVERT_<Module>.md` — เฉพาะ Mode Convert
- `REVIEW_LOG_<Module>.md` — Review Round + Approval Block