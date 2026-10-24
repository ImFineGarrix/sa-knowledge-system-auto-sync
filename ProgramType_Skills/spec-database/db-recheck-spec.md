---
name: db-recheck-spec
description: ใช้ skill นี้สำหรับ "ตรวจสอบความถูกต้อง" (recheck / audit / QA) ของ output files ที่ถูก generate โดย workflow `db-create-spec` ว่าตรงกับ Global Rules 0-12 + Rules เฉพาะของแต่ละ sub-skill หรือไม่ AI จะอ่านครบทั้ง 11 companion files ตาม Rule 10 (DB_SPEC, CHANGELOG, IMPACT, SAMPLE_DATA, INSERT, PACK_INSTALL, INDEX, ROLLBACK, STORED_PROCEDURE, CONVERT, REVIEW_LOG), cross-check กับกฎจากทุก SKILL ในชุด db-skills แล้ว generate Recheck Report ที่ระบุชัดว่าผิดกฎข้อไหน, ไฟล์ไหน, line ไหน พร้อมเสนอ Remediation Plan ให้ SA approve ก่อน หลังจาก SA confirm แต่ละ finding แล้วค่อยเรียก `db-create-spec` Mode Modify เพื่อแก้ไข Trigger ได้แก่ 'recheck spec', 'audit spec', 'verify spec', 'compliance check', 'QA database spec', 'ตรวจ spec', 'ตรวจสอบไฟล์ที่ generate', 'รีเช็ค spec', 'verify rules' หรือคำสั่ง `/db-recheck-spec`
---

# db-recheck-spec

## Role & Goal

Skill นี้เป็น **QA / Compliance Auditor** สำหรับ output files ทั้งหมดที่ generate จาก workflow `db-create-spec` — ทำงาน **ตรงข้ามกับ `db-create-spec`** (ที่สร้าง) โดย:

1. **อ่าน** ทุก companion file (11 ไฟล์ตาม Rule 10) ที่ AI gen ขึ้นมา
2. **เปรียบเทียบ** กับ Global Rules 0-12 + Rules เฉพาะของแต่ละ sub-skill (`db-create-erd`, `db-create-schema`, `db-create-index`, `db-create-procedure`, `db-create-sample-data`, `db-impact-change-analyst`, `db-rename-reserved-word`)
3. **ระบุ Finding** แต่ละข้อ: ไฟล์ไหน / line ไหน / ผิดกฎข้อไหน / severity เท่าไหร่
4. **Generate** ไฟล์ `RECHECK_REPORT_<Module>.md` พร้อม Remediation Plan
5. **รอ SA approve** ทุก finding ก่อน
6. **Handoff** ไปยัง `db-create-spec` Mode Modify เพื่อแก้ไขจริง (skill นี้ **ไม่แก้ไฟล์เอง**)

> **หลักการสำคัญ:** Skill นี้เป็น **read-only auditor** — **ห้ามแก้ไฟล์ output ใดๆ เอง** การแก้ไขทุกครั้งต้องผ่าน `db-create-spec` Mode Modify ตาม Rule 10 → Post-Approval Substantive Change → Auto Mode Modify Transition (เพื่อให้ CHANGELOG, REVIEW_LOG, Version Bump ทำงานตาม audit trail ปกติ)

## Status — Utility (Standalone)

- เป็น **utility แยก** เหมือน `db-summary-spec` — ไม่ใช่ sub-skill ของ orchestrator
- เรียกใช้ได้ทั้งใน 3 สถานการณ์:
  - **Pre-Finalize Recheck** — ก่อน SA approve Round 1 ใน REVIEW_LOG (เป็น second-pass audit นอกเหนือจาก Self-Audit Report ที่ orchestrator ทำเอง)
  - **Post-Delivery Audit** — หลัง Module deploy แล้ว มี SA ใหม่เข้ามา audit ย้อนหลัง
  - **Periodic Compliance Sweep** — รัน batch บนหลาย Module เพื่อเช็คว่ายัง compliant กับกฎใหม่ที่ update หรือไม่
- **ไม่สร้าง** companion files (CHANGELOG / IMPACT / PACK_INSTALL / ฯลฯ) — Output มีไฟล์เดียวคือ `RECHECK_REPORT_<Module>.md`

## Inherited Global Rules

สืบทอดจาก `db-create-spec` ทุกข้อ (Rule 0-12) — แต่ใช้ในมุม **"verify"** ไม่ใช่ **"generate"**:

- **Rule 0 (Strict Rule Compliance):** ตรวจครบทุกกฎ ห้าม skip — ถ้าตรวจไม่ได้บางข้อต้องระบุเหตุผลใน Note (ไม่ใช่ทิ้ง ⏳ Pending)
- **Rule 1 (Data-Driven):** อ่านจากไฟล์จริงเท่านั้น ห้ามเดา content ที่ไม่ได้อ่าน
- **Rule 3 (Progressive / Versioning):** Recheck ต้อง consistency-check version ระหว่าง DB_SPEC ↔ CHANGELOG ↔ REVIEW_LOG
- **Rule 6 (Description Preservation + Open Items Borderline Coverage):** เช็คว่า description verbatim และ Open Items ครอบคลุม borderline
- **Rule 7 (Language):** Report เป็นภาษาไทย, technical terms ภาษาอังกฤษ
- **Rule 8 (DBMS):** ระบุ DBMS ใน report header
- **Rule 10 (File Finalization):** เช็ค 11 files ครบ + naming convention + cross-reference 2 ทาง
- **Rule 12 (Collation Enforcement):** เช็ค NVARCHAR (MSSQL) + COLLATE clause ทุก text column

## Pre-Run Check (บังคับ)

ก่อนเริ่ม recheck **ต้องถาม 4 ข้อแบบ Multiple Choice เสมอ** ห้ามเดา:

**1. Module Path:**
```
กรุณาระบุ path ที่เก็บ output files ของ Module:
  - หาก folder เดียวมีหลาย Module ให้ระบุชื่อ Module ที่ต้องการ recheck
  - หากเป็น Composite Module (เช่น CashFlow_Receive) ให้ระบุชื่อ composite เต็ม
```

**2. Files in Scope:**
```
กรุณาเลือกขอบเขตการ recheck:
  1) ทั้ง 11 ไฟล์ตาม Rule 10 (Comprehensive)        — Recommended
  2) เฉพาะ DDL files (PACK_INSTALL + INDEX + ROLLBACK + STORED_PROCEDURE)
  3) เฉพาะ Documentation files (DB_SPEC + CHANGELOG + IMPACT + REVIEW_LOG)
  4) Custom (ระบุไฟล์เอง)
```

**3. Recheck Mode:**
```
กรุณาเลือก Mode ของการ recheck:
  1) Pre-Finalize    — รัน recheck ก่อน SA approve Round 1 (เน้นป้องกัน violation หลุด)
  2) Post-Delivery   — Audit ย้อนหลังหลัง deploy
  3) Periodic Sweep  — รัน batch ตามรอบ (เช่น ทุก quarter)
```

**4. Handoff Confirmation (บังคับ):**
```
หลัง recheck เสร็จ ต้องการให้:
  1) SA Confirm ก่อนทุก finding → ค่อยเรียก db-create-spec Mode Modify (Recommended — Default)
  2) Report-only (skill จบที่ report — SA ตัดสินใจเองว่าจะเรียก Mode Modify เมื่อไหร่)
```

> **🚨 ห้าม Auto-call Mode Modify ทุก finding** (ไม่มีตัวเลือก auto-fix) — เพราะ false positive จาก recheck อาจ trigger version bump ที่ไม่จำเป็น + breaking change ตาม Rule 10

## Operation Flow

### Step 1: Load & Parse All Files (Read-Only)

**สำหรับแต่ละไฟล์ใน scope:**

| ไฟล์ | สิ่งที่ต้อง Parse |
|------|-------------------|
| `DB_SPEC_<Module>.md` | Header fields, Related Files links, Business Context, Module Scope, Mermaid ERD block, Data Dictionary table, Index Strategy, Sample Data Preview, Open Items, Conversion Report (ถ้ามี) |
| `CHANGELOG_<Module>.md` | Baseline note (ถ้า legacy), Entries (version, date, author, sections), Log Ordering (เก่า → ใหม่) |
| `IMPACT_<Module>.md` | Header (Mode, Has Impact Section), Related Files, Part 1 (Impact List ถ้ามี), Part 2 (Verification), Risk Rating |
| `SAMPLE_DATA_<Module>.md` | Business Format table, Relationship Map, Per-table sections (≥10 records each), Constraint Check |
| `INSERT_<Module>.sql` | INSERT order (Parent → Child → Junction), Comment sections, Data identical กับ SAMPLE_DATA.md |
| `PACK_INSTALL_<Module>.sql` | Header comment, Section 0 (CREATE DATABASE + Collation), Section 1 (CREATE TABLES), Section 3 (ADD CONSTRAINTS), No GO statements |
| `INDEX_<Module>.sql` | Header (run order), CREATE INDEX statements, Naming pattern `<table>_idx<N>` |
| `ROLLBACK_<Module>.sql` | Header (warning), DROP statements (reverse order: child → parent → DB) |
| `STORED_PROCEDURE_<Module>.sql` | (ถ้ามี) Section headers, CREATE PROCEDURE / FUNCTION, Type-Prefix usage |
| `CONVERT_<Module>.md` | (ถ้ามี — Mode Convert เท่านั้น) Source → Target meta, Data Type Mapping, Collation Mapping, Unsupported Features |
| `REVIEW_LOG_<Module>.md` | Round entries, Status flow, Sign-off Block, Compliance Checklist (Round ล่าสุด) |

**Build Internal Model:**
- Map ทุก table → list of columns + constraints + indexes
- Cross-link: index → table, FK → ref table, SP → tables used
- Track: declared collation, case style, DBMS

### Step 2: Cross-Check vs Rules (Compliance Matrix)

ทำ **AI Auto-Evaluation** ตาม Rule 10 → REVIEW_LOG → Compliance Checklist format (reuse template — ต่อยอด 11 items เดิม + เพิ่ม items เฉพาะ recheck):

#### Compliance Matrix (บังคับครบ — ห้าม skip ข้อใด)

| # | Check Item | Source Rule | Logic ที่ AI ต้องทำ |
|---|-----------|-------------|---------------------|
| **A. Global (Rule 0-12)** | | | |
| 1 | Self-Audit Report ใน REVIEW_LOG Round 1 ครบทุกกฎ 0-12 | Rule 0 | Parse REVIEW_LOG → ตรวจ Self-Audit Report block → check ทุกกฎมี Status (✅/❌/⚠️) ไม่ใช่ Pending |
| 2 | Description Preservation (verbatim, no rewrite) | Rule 6 | Cross-check DB_SPEC Data Dict `Description` column กับ source Data Dict (ถ้ามี) — ห้ามต่างกัน |
| 3 | Open Items section มี + ครอบคลุม borderline cases | Rule 6 | Parse DB_SPEC → check Open Items section exists + มี items ที่ flagged ใน Compliance Checklist |
| 4 | Case Style Lock (snake_case / lowercase) ทุก identifier | Rule 4 | Regex: ชื่อ DB, table, column, index, SP, variable — match `^[a-z][a-z0-9_]*$` หรือ `^[a-z][a-z0-9]*$`. ยกเว้น Grandfathered (ต้องระบุใน Open Items) |
| 5 | Reserved Word Multi-Source Scan ครบ 4 sources | Rule 4 | Parse REVIEW_LOG Compliance Checklist item #11 — ต้องระบุ source breakdown (CSV / T-SQL Extended / ODBC / Future) |
| 6 | Bracket Escape ไม่ใช่ silent — มี audit ใน REVIEW_LOG ถ้าใช้ | Rule 4 | Grep PACK_INSTALL หา `[name]`, `` `name` ``, `"name"` — ถ้าเจอ → ตรวจว่ามี entry ใน REVIEW_LOG Audit Trail + reason ใน Open Items |
| 7 | CSV Append-Only Audit Log มี row ใหม่หาก rename | Rule 4 | Compare `references/reserved-word-mapping.csv` กับ Audit Trail ใน DB_SPEC → ทุก rename event ต้องมี row ใน CSV |
| **B. Schema (db-create-schema)** | | | |
| 8 | NVARCHAR (MSSQL) — ห้าม VARCHAR | Rule 12 | (MSSQL only) Grep PACK_INSTALL Section 1 หา `VARCHAR(` (without N prefix) — Pass = 0 occurrences |
| 9 | COLLATE clause ทุก text column | Rule 12 | Parse CREATE TABLE → ทุก column ที่เป็น CHAR/VARCHAR/NCHAR/NVARCHAR/TEXT ต้องมี `COLLATE <baseline>` clause |
| 10 | CREATE DATABASE มี COLLATE/ENCODING clause | Rule 12 | Parse PACK_INSTALL Section 0 → ต้องมี `CREATE DATABASE ... COLLATE ...` หรือ `ENCODING ... LC_COLLATE ...` |
| 11 | **No GO statements ใน 5 SQL files (MSSQL)** — PACK_INSTALL, INDEX, INSERT, ROLLBACK, STORED_PROCEDURE | Rule 10 → No GO Statements + db-create-schema / db-create-index / db-create-sample-data / db-create-procedure | (MSSQL only) Grep ทุก 5 ไฟล์ด้วย regex `^\s*GO\s*$` — Pass = 0 occurrences ในแต่ละไฟล์. หากเจอ → ❌ Fail + ระบุไฟล์ + line. รายงาน per-file breakdown: PACK_INSTALL=0/X, INDEX=0/X, INSERT=0/X, ROLLBACK=0/X, STORED_PROCEDURE=0/X (X = total lines). สำหรับ STORED_PROCEDURE — verify ว่า CREATE PROCEDURE/FUNCTION/TRIGGER/VIEW ใช้ Dynamic SQL wrapping (`EXEC(N'...')`) หรือ multi-file split (workaround ตาม `db-create-procedure`) |
| 12 | Pack Install ครบ 3 sections (0, 1, 3) — ไม่มี Index/Insert/SP | db-create-schema | Parse comment sections — ต้องมี `Section 0`, `Section 1`, `Section 3`; ห้ามมี `Section 2` (Index), `Section 4` (Insert) |
| 13 | Null Constraint Summary table มี (column Business Reason ครบ) | db-create-schema → Null Constraint Rule | Parse DB_SPEC → check `Null Constraint Summary` table exists + ทุก NOT NULL column มี Business Reason |
| 14 | ทุก table มี PK + PK = UNIQUE + NOT NULL | Rule 5 | Parse CREATE TABLE — count = count(`PRIMARY KEY`); PK column ต้อง `NOT NULL` + IDENTITY/SERIAL/UUID หรือ explicit UNIQUE |
| 15 | Reserved Words rename audit table ใน DB_SPEC ครบ | db-create-schema | Parse DB_SPEC → `Reserved Words Check Result` ต้องมี audit table + Final Name ตรงกับ DDL |
| **C. Index (db-create-index)** | | | |
| 16 | Index Naming Pattern `<table>_idx<N>` | db-create-index | Regex ทุก index name ใน INDEX_<Module>.sql: `^[a-z][a-z0-9_]*_idx[0-9]+$` |
| 17 | INDEX file แยกจาก PACK_INSTALL | Rule 10 | ไฟล์ `INDEX_<Module>.sql` exists + PACK_INSTALL ไม่มี `CREATE INDEX` (เฉพาะ PK auto-created OK) |
| 18 | Per-table Index Detail subsection ใน DB_SPEC | db-create-index | Parse DB_SPEC → แต่ละ table ต้องมี subsection `**Indexes on this table:**` พร้อม table |
| 19 | Unique index ใช้ pattern เดียวกับ non-unique | db-create-index | ห้ามมี `ux_*`, `uk_*`, `IX_*`, `UX_*` prefix — ต้อง `<table>_idx<N>` ทั้งหมด |
| 20 | Collation Awareness — text column index ไม่ใช้ function ที่ break sargability | Rule 12 | Parse `CREATE INDEX` หา `LOWER(`, `UPPER(`, ฯลฯ ใน index expression — flag ถ้าเจอ |
| **D. Procedure (db-create-procedure — ถ้ามี SP)** | | | |
| 21 | STORED_PROCEDURE file แยกจาก PACK_INSTALL | Rule 10 | ไฟล์ exists + PACK_INSTALL ไม่มี `CREATE PROCEDURE` |
| 22 | SP text variables/parameters มี COLLATE clause | Rule 12 | Parse SP definitions — ทุก `VARCHAR`, `NVARCHAR` parameter / DECLARE variable ต้องมี `COLLATE` |
| 23 | Type-Prefix ใช้เฉพาะตอนชื่อชน Reserved Word | db-create-procedure | Cross-check parameter/variable name กับ Reserved Words list — Type-Prefix (`@n_*`, `@s_*`) ใช้ได้เฉพาะกรณีนี้ |
| **E. Sample Data (db-create-sample-data)** | | | |
| 24 | ≥10 records/table ใน SAMPLE_DATA.md (ยกเว้น Reference Table ที่ SA ไม่ส่งข้อมูล) | Rule 2 | Count rows per table section — ≥10 หรือมี Note ว่า "Reference Table — รอ SA fill" |
| 25 | ≥10 records/table ใน INSERT.sql ตรงกับ SAMPLE_DATA.md | db-create-sample-data | Parse INSERT statements per table → count = count ใน SAMPLE_DATA.md (data identical) |
| 26 | Sample Data Preview ใน DB_SPEC = subset ของไฟล์เต็ม | db-create-sample-data | Cross-check preview records กับ SAMPLE_DATA.md — preview ต้องเป็น subset |
| 27 | INSERT order ตาม FK dependency (Parent → Child → Junction) | db-create-sample-data | Parse INSERT order vs FK graph — INSERT ของ child ต้องอยู่หลัง parent |
| 28 | Business Format Pattern ระบุครบ (ถ้ามี) | Rule 2 | Parse SAMPLE_DATA.md → `Business Format Applied` table exists + ค่าใน INSERT ตรง pattern |
| **F. ERD (db-create-erd)** | | | |
| 29 | ERD เป็น Mermaid `erDiagram` เท่านั้น | Rule 9 | Parse DB_SPEC → Entity Relationship section ต้องมี ` ```mermaid ` block + `erDiagram` keyword |
| 30 | Key Marker = PK + FK เท่านั้น (ห้าม UK) | Rule 9 | Grep ใน mermaid block หา ` UK` — Pass = 0 occurrences |
| 31 | Relationship Summary table มี | db-create-erd | Parse DB_SPEC → `### Relationship Summary` table exists ใต้ mermaid block |
| 32 | Verb Phrase ทุก relationship | Rule 9 | Parse mermaid relationships → ทุก line `||--o{` ต้องมี `: <verb>` |
| **G. Impact (db-impact-change-analyst)** | | | |
| 33 | IMPACT file exists ทุก Mode (รวม Mode New greenfield) | Rule 10 | ไฟล์ `IMPACT_<Module>.md` exists |
| 34 | IMPACT Variant ถูกต้องตาม Mode | db-impact-change-analyst | Mode New greenfield = `Has Impact Section: No`; อื่นๆ = `Yes` |
| 35 | Rollback SQL ไม่ฝังใน IMPACT — แยกใน ROLLBACK file | db-impact-change-analyst | Grep IMPACT หา `ALTER TABLE ... DROP` หรือ `DROP TABLE` — Pass = 0 (ต้องอยู่ใน ROLLBACK_<Module>.sql) |
| 36 | Verification section ครบ 4 ส่วน (SQL Test / Constraint / Sample Data / Rollback Dry-Run) | db-impact-change-analyst | Parse IMPACT Part 2 → ครบ 4 subsections |
| **H. Rename (db-rename-reserved-word)** | | | |
| 37 | Pre-Append Validation ผ่านทุก row ใหม่ใน CSV | db-rename-reserved-word | Cross-check CSV rows ใหม่ vs Type-Prefix Convention table (prefix exists, DBMS valid, no duplicate, format `<prefix><original>`) |
| 38 | Renamed name = `<prefix>_<original>` snake_case + lowercase | db-rename-reserved-word | Regex CSV `renamed` column: `^[a-z]_[a-z0-9_]+$` |
| **I. File Convention (Rule 10)** | | | |
| 39 | ไฟล์ครบทั้ง 11 ตาม Rule 10 (หรือ N/A ที่มีเหตุผล) | Rule 10 | Check existence ของแต่ละไฟล์ตาม table; ถ้าไม่มี ต้องตรงกับเงื่อนไข (เช่น STORED_PROCEDURE ไม่บังคับถ้าไม่มี SP) |
| 40 | Naming Convention UPPER_SNAKE prefix + `<Module>` | Rule 10 | Regex filename: `^[A-Z_]+_[A-Za-z_]+\.(md|sql)$` |
| 41 | Cross-Reference 2 ทาง (DB_SPEC ↔ companion) | Rule 10 | DB_SPEC → Related Files section ต้อง link ทุก companion ที่สร้าง; companion → Header ต้อง link กลับ DB_SPEC |
| 42 | DB_SPEC Header Fields ครบ 12 fields | Rule 10 | Parse Header table — มี Module, DBMS, Collation, Mode, Author, Created Date, Last Updated, Current Version, Reviewer(s), Approval Status, Approval Date |
| 43 | Version Consistency (DB_SPEC = CHANGELOG = REVIEW_LOG) | Rule 10 + Rule 3 | Extract version จาก 3 ไฟล์ → ต้องตรงกัน; substantive changes since last approval = 0 หรือมี bump |
| 44 | CHANGELOG Log Ordering (เก่า → ใหม่) | Rule 3 | Parse versions ตามลำดับใน file → ต้อง ascending (v1.0 ก่อน v1.1 ก่อน v2.0) |
| 45 | REVIEW_LOG Compliance Checklist Round ล่าสุดมี AI Auto-Evaluation ไม่มี Pending | Rule 10 | Parse Round ล่าสุด → Status column ต้องไม่มี ⏳ Pending; ทุก ❌ Fail ต้องมี Note (Grandfathered หรือ remediation plan) |

### Step 3: Generate Findings

แต่ละ check ที่ไม่ผ่าน หรือ borderline ต้องสร้าง **Finding entry** ใน Report:

**Finding Structure:**
```markdown
### Finding F-<NNN>

| Field | Value |
|-------|-------|
| **ID** | F-001 |
| **Severity** | 🔴 Blocker / 🟡 Warning / 🟢 Info |
| **Rule Reference** | Rule 4 → Case Style Lock (db-create-spec.md) + db-create-schema.md Naming Rules |
| **File** | `PACK_INSTALL_<Module>.sql` |
| **Location** | Line 47, column `CustomerID` ใน table `customer` |
| **Issue** | ใช้ PascalCase (`CustomerID`) แทน snake_case (`customer_id`) |
| **Evidence** | `customer_id BIGINT IDENTITY(1,1)` → พบ `CustomerID BIGINT IDENTITY(1,1)` |
| **Expected** | `customer_id` (snake_case ตาม Case Style Lock) |
| **Remediation** | Rename column `CustomerID` → `customer_id` ใน 4 ไฟล์ (PACK_INSTALL, INDEX, SAMPLE_DATA, INSERT) + update DB_SPEC Data Dict |
| **Mode Modify Trigger** | Substantive — Breaking (rename column) → bump v2.0 หรือ pre-release patch ตาม Rule 10 |
| **SA Confirmation** | ⏳ Pending |
```

**Severity Definition:**

| Symbol | Meaning | เกณฑ์ |
|:------:|---------|------|
| 🔴 **Blocker** | ต้องแก้ก่อน finalize / deploy | Strict violation ของ Rule 0/4/12, missing required file, version inconsistency, schema-breaking issue |
| 🟡 **Warning** | ควรแก้ — แต่ไม่ block | Borderline case, missing optional section, cross-reference link broken, naming style ที่ Grandfathered ได้ |
| 🟢 **Info** | แนะนำ / improvement | Suggested optimization, missing optional Open Items entry, formatting inconsistency |

### Step 4: Build Remediation Plan

หลัง list findings ครบ → จัด **Remediation Plan** เรียงตาม severity + dependency:

```markdown
## Remediation Plan

### Phase 1 — Blocker (🔴) — ต้องแก้ก่อน finalize
| Order | Finding ID | Action | Affected Files | Estimated Effort |
|-------|-----------|--------|----------------|-------------------|
| 1 | F-001 | Rename column CustomerID → customer_id | 4 files | 15 min |
| 2 | F-003 | เพิ่ม COLLATE clause ใน 23 text columns | PACK_INSTALL | 30 min |

### Phase 2 — Warning (🟡)
| Order | Finding ID | Action | Affected Files | Estimated Effort |
|-------|-----------|--------|----------------|-------------------|
| 3 | F-005 | เพิ่ม Open Items entry สำหรับ TINYINT borderline | DB_SPEC | 5 min |

### Phase 3 — Info (🟢)
| Order | Finding ID | Action | Affected Files | Estimated Effort |
|-------|-----------|--------|----------------|-------------------|
| 4 | F-008 | เพิ่ม Verb Phrase ที่ relationship line 12 | DB_SPEC | 2 min |

### Mode Modify Transition Strategy

ตาม Rule 10 → Post-Approval Substantive Change → Auto Mode Modify Transition:

| Phase | Bumps to | Reason |
|-------|----------|--------|
| Phase 1 (Blocker) | v2.0 (breaking) | Rename column = breaking change |
| Phase 2 (Warning) | v1.x (minor) | ไม่กระทบ schema |
| Phase 3 (Info) | ไม่ bump | Non-substantive |

> ⚠️ **บังคับ:** SA ต้อง AskUserQuestion (ตาม Rule 10) ก่อน execute Phase 1 — Pre-Release Exception อาจ allow v1.x patch แทน v2.0
```

### Step 5: SA Confirmation Per Finding (บังคับ — ห้าม Auto-call)

หลัง present Remediation Plan ให้ SA → ต้อง **AskUserQuestion ทีละ finding** หรือ batch ตาม severity:

```
พบ <N> findings ทั้งหมด:
  🔴 Blocker: <count>
  🟡 Warning: <count>
  🟢 Info: <count>

กรุณาเลือก action สำหรับแต่ละ finding:
  (1) Approve ทั้งหมด → เรียก db-create-spec Mode Modify ตามลำดับใน Plan
  (2) Approve เฉพาะ Blocker (ข้าม Warning/Info)
  (3) Reject เฉพาะบางข้อ (ระบุ Finding ID)
  (4) Defer ทั้งหมด → จบที่ Report (SA ตัดสินใจเอง)
```

**กฎเหล็ก — ห้าม Auto-call Mode Modify:**
- ห้าม trigger `db-create-spec` Mode Modify โดยไม่มี SA confirmation
- ห้าม assume "Blocker = auto-fix" — ทุก finding ต้องผ่าน SA decision
- หาก SA เลือก (4) Defer → output แค่ Report ไม่ทำอะไรต่อ

### Step 6: Handoff to db-create-spec Mode Modify

เมื่อ SA approve findings → เตรียม payload ส่งให้ `db-create-spec` Mode Modify:

```markdown
**Handoff Package:**
- **Mode:** Modify
- **Module:** <Module>
- **Proposed Changes:** (list จาก Approved Findings)
  - F-001: Rename column CustomerID → customer_id
  - F-003: เพิ่ม COLLATE clause ใน 23 text columns
- **Reference Document:** RECHECK_REPORT_<Module>.md (link)
- **Source of Change:** Compliance recheck (not business requirement)
- **Expected Version Bump:** v<current> → v<target> (per Plan)
```

จากนั้น **invoke `db-create-spec` skill** ใน Mode Modify ตาม normal flow (Step 1-7 ของ Mode Modify):
1. Impact Analysis (`db-impact-change-analyst`)
2. Schema Change (`db-create-schema`)
3. Data Migration check
4. Sample Data update (เฉพาะ table ที่กระทบ)
5. SQL Test + Verification
6. Self-Audit Report (Rule 0)
7. Finalize (append CHANGELOG, update DB_SPEC, REVIEW_LOG Round ใหม่)

> **Recheck Skill ไม่ทำ Mode Modify เอง** — แค่ส่ง payload + trigger orchestrator

## Output Format

**ไฟล์เดียว:** `RECHECK_REPORT_<Module>.md`

```markdown
# Recheck Report — <Module>

## Header

| Field | Value |
|-------|-------|
| **Module** | <Module Name> |
| **DBMS** | <DBMS> v<Version> |
| **Recheck Mode** | Pre-Finalize / Post-Delivery / Periodic Sweep |
| **Scope** | All 11 files / DDL-only / Doc-only / Custom |
| **Files Checked** | <N> / 11 |
| **Generated by** | db-recheck-spec |
| **Generated Date** | YYYY-MM-DD |
| **Auditor (SA)** | <name> |
| **Reference Spec** | [DB_SPEC_<Module>.md](./DB_SPEC_<Module>.md) |
| **Compliance Status** | ✅ Pass / ⚠️ Pass with Warnings / ❌ Fail |

---

## Executive Summary

- **Total Checks:** 45
- **Passed:** <N>
- **Failed:** <N>
  - 🔴 Blocker: <N>
  - 🟡 Warning: <N>
  - 🟢 Info: <N>
- **Effective Block Status:** ✅ No block / ❌ Blocked (มี Blocker)
- **Recommendation:** Approve / Approve with Modification / Reject

---

## Compliance Matrix (45 items — ตาม Step 2)

> ใช้ Compliance Checklist format เดียวกับ REVIEW_LOG (Rule 10) — reuse pattern

| # | Check Item | Status | Evidence (AI Findings) | Note |
|---|-----------|:------:|------------------------|------|
| 1 | Self-Audit Report ครบกฎ 0-12 | ✅ | REVIEW_LOG Round 1 มี Self-Audit table ครบ 12 rows | — |
| 2 | Description Preservation (verbatim) | ⚠️ | 3 columns ใน Data Dict description ดูเหมือนถูกเรียบเรียงใหม่ | Open Items #5-7 รอ SA verify vs source |
| 3 | Open Items ครอบคลุม borderline | ✅ | Open Items มี 12 entries รวม Future Reserved + ambiguous prefix | — |
| 4 | Case Style Lock | ❌ | พบ `CustomerID` (PascalCase) ใน PACK_INSTALL line 47 | Finding F-001 |
| ... | ... | ... | ... | ... |

---

## Findings

> เรียงตาม severity → blocker → warning → info → file order

### Finding F-001 (🔴 Blocker)

*(structure ตาม Step 3)*

### Finding F-002 (🔴 Blocker)
...

### Finding F-XXX (🟢 Info)
...

---

## Remediation Plan

*(structure ตาม Step 4)*

---

## SA Decision Log

| Finding ID | Severity | SA Action | Decision Date | Note |
|-----------|---------|-----------|---------------|------|
| F-001 | 🔴 | Approve → Mode Modify | YYYY-MM-DD | bump v2.0 |
| F-005 | 🟡 | Defer | YYYY-MM-DD | จะแก้ใน next release |
| F-008 | 🟢 | Reject (not necessary) | YYYY-MM-DD | accept as-is |

---

## Handoff Status

| Field | Value |
|-------|-------|
| **Approved Findings** | <N> ready for Mode Modify |
| **Deferred Findings** | <N> logged for future |
| **Rejected Findings** | <N> documented in Decision Log |
| **db-create-spec Mode Modify Invoked** | Yes / No (ถ้า Yes → link ไป CHANGELOG entry ใหม่) |

---

## Sign-off

- **Auditor:** _______________ Date: ____________
- **SA Lead:** _______________ Date: ____________
- **(Optional) DBA/Tech Lead:** _______________ Date: ____________
```

## Integration with db-create-spec

### When to Use db-recheck-spec vs db-create-spec Self-Audit

| Scenario | ใช้ Skill ไหน |
|----------|---------------|
| **ระหว่าง generate workflow** (orchestrator ตรวจตัวเอง) | `db-create-spec` Self-Audit Report (Rule 0) |
| **ก่อน SA approve Round 1** (second-pass audit) | `db-recheck-spec` Pre-Finalize Mode |
| **หลัง deploy** (post-delivery audit) | `db-recheck-spec` Post-Delivery Mode |
| **Periodic compliance sweep** | `db-recheck-spec` Periodic Sweep Mode |
| **อ่าน DB เดิม + audit** | `db-summary-spec` → `db-recheck-spec` (สอง step) |

### Flow Diagram

```
Generated Files (จาก db-create-spec)
        │
        ▼
db-recheck-spec (read-only audit)
        │
        ├─ Load 11 files
        ├─ Cross-check Rules 0-12 + sub-skill rules (45 items)
        ├─ Generate Findings + Severity
        ├─ Build Remediation Plan
        │
        ▼
RECHECK_REPORT_<Module>.md
        │
        ▼
SA Review + Confirm (per finding)
        │
        ▼ (Approved findings)
db-create-spec Mode Modify (orchestrator)
        │
        ├─ db-impact-change-analyst
        ├─ db-create-schema (ALTER)
        ├─ db-create-sample-data (affected tables)
        └─ Self-Audit Report (Rule 0)
        │
        ▼
Updated Files + new CHANGELOG entry (v1.x or v2.0)
```

## Anti-patterns (ห้ามทำ)

- ❌ **แก้ไฟล์ output เอง** — Skill นี้ read-only; การแก้ทุกครั้งต้องผ่าน `db-create-spec` Mode Modify
- ❌ **Auto-call Mode Modify โดยไม่มี SA confirmation** — ทุก finding ต้องผ่าน AskUserQuestion
- ❌ **Skip check items** — ถ้าตรวจไม่ได้ ให้ระบุ ⚠️ + เหตุผลใน Note (ห้ามทิ้ง ⏳ Pending)
- ❌ **เดา content ที่ไม่ได้อ่าน** — Rule 1 Data-Driven: ทุก finding ต้องมี Evidence (file + line)
- ❌ **Mark Finding ผิด severity เพื่อหลบ Mode Modify** — Blocker คือ Blocker ห้าม downgrade เป็น Warning เพื่อ skip
- ❌ **Report แค่ Pass/Fail โดยไม่ระบุกฎข้อ** — ทุก Finding ต้องมี Rule Reference ชัดเจน
- ❌ **รวบ findings เป็น batch ใหญ่เกินไป** — แต่ละ finding ควรเป็น atomic issue เพื่อ traceability
- ❌ **ใช้ skill นี้แทน Self-Audit ของ orchestrator** — สองอย่างทำงานคู่กัน ไม่ใช่แทนกัน
- 🚨 ❌ **Skip การถาม SA Confirmation Per Finding** — แม้ severity ทุกตัวเป็น Blocker ก็ต้องถาม (Pre-Release Exception อาจอนุญาต defer ได้)

## Notes

- **Compatibility:** เนื้อหาของ skill นี้ assume layout flat workspace (`db-skills/<skill>.md`). หาก install ผ่าน `install.ps1` paths จะถูก transform เป็น folder-per-skill อัตโนมัติ
- **45 Check Items** ใน Compliance Matrix เป็น **baseline** — หากกฎใน skill อื่น update ต้อง update matrix นี้ตามด้วย
- **False Positive Handling:** หาก AI ตรวจพบสิ่งที่ดูเหมือน violation แต่จริงๆ เป็น Grandfathered → ระบุใน Note + reference CHANGELOG decision ที่ accept exception
- **Severity Calibration:** Severity ควร calibrate ตามผลกระทบจริง — ไม่ใช่แค่ "เคร่งครัด Rule 0"; เช่น typo ใน comment = 🟢 Info, แต่ missing PK = 🔴 Blocker
- **Linkage with REVIEW_LOG:** หาก Recheck Mode = Pre-Finalize → Findings ที่ approved ควร attach เข้า REVIEW_LOG Round ปัจจุบันด้วย (เพื่อ audit trail)
- skill นี้สามารถใช้เป็น input ให้ `db-create-spec` Mode Modify โดยตรง (แทนที่ Business Requirement) — ทำให้ Mode Modify รองรับทั้ง business-driven และ compliance-driven changes

## Changelog

- **v1.0** — Initial release. รองรับ Pre-Finalize / Post-Delivery / Periodic Sweep modes, comprehensive 45-item Compliance Matrix ครอบคลุม Global Rules 0-12 + sub-skill rules, SA Confirmation per finding, Handoff package ไป `db-create-spec` Mode Modify
