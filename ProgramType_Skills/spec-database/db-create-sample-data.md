---
name: db-create-sample-data
description: ใช้ skill นี้สำหรับ Generate Sample Data ตัวอย่างในตารางของฐานข้อมูล เพื่อให้ Developer นำไปใช้ Gen ข้อมูลสำหรับทำ Unit Test, Integration Test หรือ Demo Environment โดย AI จะสร้างข้อมูลที่สอดคล้องกับ Data Dictionary, สอดคล้องกับ Business Format (เลขที่บัญชี, รหัสพนักงาน) ของบริษัท และเป็น Relational Set ที่เชื่อมโยงกันผ่าน PK/FK Trigger ได้แก่ 'sample data', 'test data', 'seed data', 'mock data', 'unit test data' หรือเมื่อ parent skill เรียกใช้
---

# db-create-sample-data

> **🚨 Sub-Skill Trigger Enforcement (Rule 4):** Skill นี้ต้องถูกเรียกจาก parent (`db-create-spec`) เมื่อ Module ต้องการ Sample Data — ห้าม orchestrator สร้าง INSERT statements inline โดยไม่เรียก skill นี้

## Role & Goal

Skill นี้ Generate **Sample Data** สำหรับ:
- Unit Test ของ Developer
- Integration Test
- Demo / Sandbox Environment
- Verification ของ Spec

โดยข้อมูลต้องสอดคล้องกับ Data Dictionary, Business Format ของบริษัท และเป็น **Relational Set** ที่เชื่อมโยงกันผ่าน PK/FK

## Inherited Global Rules

สืบทอดจาก `db-create-spec`:
- **กฎข้อ 2 (Standardized Sample Data)** — แกนหลัก
- **กฎข้อ 6 (Description Preservation)** — ห้ามย่อ description ของ table / column / business format pattern จาก Data Dict ใช้ verbatim เป๊ะ
- **กฎข้อ 10 (Mandatory Companion File Split)** — Output split ตาม Rule 10
- **🏢 Type-Prefix Convention (สืบทอด Rule 4):** INSERT INTO statement ต้องใช้ชื่อ column / table ที่ผ่าน rename จาก Reserved Words Check แล้ว — เช่น ถ้า column `key` ถูก rename เป็น `n_key` ผ่าน skill `db-rename-reserved-word` → INSERT statement ต้องอ้างถึง `n_key` (ไม่ใช่ `key` หรือ `[key]`)
  - ตัวอย่าง: `INSERT INTO Sales (n_key, customer_id, ...) VALUES (...)`
  - หาก Sample data มา**ก่อน** Reserved Words Check → AI ต้องรอ rename map จาก `db-create-schema` ก่อน generate INSERT

กฎย่อยที่ skill นี้ใช้:

- **Format Compliance:** ต้องสอบถาม Business Format ของบริษัทก่อน (เช่น Pattern เลขที่บัญชี, รหัสพนักงาน) หากไม่ระบุ ให้ใช้ตัวอย่างสากลและ Note ไว้
- **Request Sample Data:** ขอ Sample Data จริงจาก SA ก่อน เพื่อเลียนแบบ Pattern ที่ใช้จริง
- **Relational Set (บังคับ):** ข้อมูลจากหลายตารางต้องเชื่อมโยงผ่าน PK/FK เน้น Business Flow ที่สมบูรณ์ มากกว่าปริมาณข้อมูล
- **Backward Compatibility:** สำหรับ Mode Modify/Convert ต้องคำนึงถึงข้อมูลเก่า — Default Value สำหรับ NOT NULL ที่เพิ่มใหม่
- **Mandatory File Split (บังคับ):** Output ของ skill นี้ต้องสร้าง **3 ส่วน** เสมอ:
  1. **Preview (2-3 records/table)** — ส่งกลับให้ parent (`db-create-spec`) ฝังในไฟล์ `DB_SPEC_<Module>.md`
  2. **Documentation (`SAMPLE_DATA_<Module>.md`)** — **Markdown documentation only** (ตารางอธิบาย ≥10 records/table) **ไม่มี SQL INSERT** — เน้นให้ SA/Dev อ่านง่าย
  3. **Executable SQL (`INSERT_<Module>.sql`)** 🆕 — **INSERT statements เท่านั้น** สำหรับ deploy/seed — รัน standalone หลัง PACK_INSTALL + INDEX
- **Minimum Volume (บังคับ):** **อย่างน้อย 10 records ต่อ table** ทั้งใน SAMPLE_DATA.md (markdown table) และ INSERT.sql (executable)
- **🚨 Cross-Link Required:**
  - `SAMPLE_DATA_<Module>.md` Header ต้องระบุ "Executable SQL → [INSERT_<Module>.sql](./INSERT_<Module>.sql)"
  - `INSERT_<Module>.sql` Header ต้องระบุ "Documentation → SAMPLE_DATA_<Module>.md"
- **🚨 Data Consistency:** ค่าใน Markdown tables ของ SAMPLE_DATA.md ต้อง **identical กับ INSERT statements ใน INSERT.sql** — Single Source of Truth: generate ครั้งเดียวแล้วเขียน 2 format
- **INSERT.sql Format:**
  - INSERT statements ใน plain SQL (ไม่ต้อง fenced code block)
  - INSERT order ตาม dependency (Parent → Child → Junction) สอดคล้องกับ FK
  - ใช้ Dialect ของ DBMS ที่เลือก
  - Comment กำกับ section ของแต่ละ table
  - **🚨 No GO statements (MSSQL — บังคับ Rule 10):** ห้ามใช้ `GO` ใน INSERT file — INSERT statements เป็น DML ที่ใช้ `;` terminator ได้ปกติ ไม่ต้องการ batch separator
    - Header ของไฟล์ต้องระบุ comment: `-- 🚨 NO GO statements (MSSQL) — รองรับ sqlcmd / programmatic deploy`
    - **Lint Check ก่อนส่ง (MSSQL only):** Grep INSERT file หา `^\s*GO\s*$` (standalone GO) — Pass = 0 occurrences
- **Reference / Lookup Table Flow (บังคับ):** ก่อนเริ่ม Generate ต้อง **ถาม SA ก่อน** ว่าตารางใดเป็น Reference / Lookup Table
  - ถ้า SA ระบุว่าเป็น Reference Table + ให้ข้อมูล (เช่น status: active/inactive/deleted) → ใส่ตามข้อมูลที่ SA ให้ (ไม่บังคับ 10 records)
  - ถ้า SA **ไม่ได้** ให้ข้อมูล Reference Table → **ไม่ต้องสร้าง Sample Data** สำหรับตารางนั้น (skip) + Note ไว้ใน Output ว่ารอ SA fill
  - ห้าม AI เดาค่า Reference Data เอง
- **Mode Modify — Preview Scope:** เมื่อ Mode = Modify → Preview ใน `DB_SPEC_<Module>.md` ให้ใส่เฉพาะ **table ที่ถูกแก้** (table อื่นที่ไม่กระทบไม่ต้อง regenerate preview)
- **Mode Modify — Full File Update Strategy (บังคับ):** เมื่อ Mode = Modify บนไฟล์ `SAMPLE_DATA_<Module>.md` ที่มีอยู่แล้ว:
  - **Update เฉพาะ section ของ table ที่ถูกแก้** — ไม่ regenerate ทั้งไฟล์
  - **เก็บข้อมูล table อื่นที่ไม่กระทบไว้เป๊ะ** (ห้ามแตะ INSERT script ของ table อื่น)
  - **เพิ่ม version stamp** ที่ section header ของ table ที่ update เช่น `### CUSTOMER (Updated v1.2 — 2026-05-13)`
  - **หาก column ใหม่เป็น NOT NULL ที่ไม่มี default** ที่กระทบ INSERT เดิม → ต้อง regenerate INSERT ของ table นั้นใหม่ (ใส่ค่า column ใหม่ทุก record) + ระบุ note ที่ section header
  - **หากเป็น add nullable column / add index** → ไม่ต้องแก้ INSERT statement เลย แค่ note ที่ section header ว่ามี schema update
- **Back-Link (บังคับ):** ไฟล์ `SAMPLE_DATA_<Module>.md` ต้องมี link กลับ `DB_SPEC_<Module>.md` ใน header

### Mode Modify Update Strategy — ตัวอย่าง

ไฟล์เดิม (v1.0) มี 3 tables: CUSTOMER, PRODUCT, ORDER → Mode Modify เพิ่ม column `customer.phone` (nullable):

```markdown
# Sample Data — <Module>

**Last Updated:** v1.1 (2026-05-13) — affected table: CUSTOMER
**Previous Version:** v1.0 (2026-04-20)

---

### CUSTOMER (Updated v1.1 — 2026-05-13)
> Schema change: added nullable column `phone` — existing INSERT remain valid (NULL for old records)

| customer_id | customer_name | email | phone | created_at |
|---|---|---|---|---|
| CUS-2026-00001 | สมชาย | somchai@example.com | NULL | 2026-01-15 |
| ... (10 records, ค่าเดิม + phone=NULL) | | | | |

### PRODUCT (Unchanged — v1.0)
| product_id | ... |
| ... (ข้อมูลเดิมเป๊ะๆ ห้ามแก้) | |

### ORDER (Unchanged — v1.0)
| order_id | ... |
| ... | |
```

## Operation Flow

### Step 1: Pre-Run Check
ถาม SA:
- **Mode:** New / Modify / Convert? (รับจาก parent หรือถาม)
- **Volume:** ต้องการกี่ record ต่อตาราง?
  - **ขั้นต่ำ 10 records/table** (บังคับ) สำหรับไฟล์ `SAMPLE_DATA_<Module>.md`
  - **Preview ใน DB_SPEC:** 2-3 records/table (ตัดมาจากชุดเต็ม)
  - **Mode Modify:** Preview ใน DB_SPEC เฉพาะ table ที่ถูกแก้
- **Reference / Lookup Tables (บังคับถาม):** ตารางไหนเป็น Reference Table?
  - ถ้ามี: ขอ SA ส่งค่ามาเลย — AI จะใส่ตามนั้น (ไม่บังคับ 10 records)
  - ถ้า SA ไม่ส่งข้อมูล Reference: **skip** ตารางนั้น + Note ใน Output
- **Business Format:** มี Pattern เฉพาะของบริษัทไหม? เช่น
  - รหัสลูกค้า: `CUS-2026-00001`
  - เลขที่ Order: `ORD/2026/05/0001`
  - รหัสพนักงาน: `EMP00123`
- **Locale:** ข้อมูลภาษาไทย / อังกฤษ / ผสม?
- **Data Sensitivity:** มีข้อมูลส่วนตัวที่ต้องเป็น fake เท่านั้นไหม (PII)?

### Step 2: Receive Schema
รับ Schema + Data Dictionary จาก parent / `db-create-schema`

### Step 3: Identify Relationships
แมพ PK / FK เพื่อสร้าง Insert Order ที่ถูกต้อง:
```
1. Insert Parent table (CUSTOMER, PRODUCT) ก่อน
2. Insert Child table (ORDER) — ใช้ FK ที่อ้างถึง record ใน Parent
3. Insert Junction table (ORDER_ITEM) — ใช้ทั้ง 2 FK
```

### Step 4: Generate Relational Set
สร้างข้อมูลที่ครอบคลุม **Business Scenario** สำคัญ เช่น:
- ลูกค้า 1 คนมี Order หลาย Order
- Order 1 ใบมี Order Item หลายรายการ
- มีลูกค้าที่ไม่เคย Order เลย (Edge Case)
- มี Product ที่ขายแล้ว และ Product ที่ยังไม่เคยถูกสั่ง

### Step 5: Validate Constraints
- ตรวจ NOT NULL ครบทุก Column
- ตรวจ UNIQUE constraint ไม่ชนกัน
- ตรวจ CHECK constraint (เช่น quantity > 0)
- ตรวจ Foreign Key อ้างอิงถูก

### Step 6: Generate Full INSERT Script (≥10 records/table)
ออกมาเป็น `INSERT INTO` Script ตาม Dialect ของ DBMS ที่เลือก พร้อม Comment ใส่ไว้ในไฟล์ `SAMPLE_DATA_<Module>.md` และรวมเข้าไฟล์ `PACK_INSTALL_<Module>.sql` (ไฟล์เดียวที่รวมทุก SQL)

### Step 7: Generate Spec Preview (2-3 records/table)
ตัดข้อมูล 2-3 records แรกของแต่ละ table จากชุดเต็ม Step 6 → format เป็น Markdown table หรือ short INSERT block → ส่งกลับ parent (`db-create-spec`) เพื่อฝังใน `DB_SPEC_<Module>.md` ภายใต้หัวข้อ **Sample Data Preview** (standalone section รวม preview ของทุก table ในที่เดียว)

- **Mode New / Convert:** Preview ทุก table
- **Mode Modify:** Preview เฉพาะ **table ที่ถูกแก้** เท่านั้น

### Step 8: Hand-off
ส่งให้ Dev / SA review:
- ไฟล์เต็ม → `SAMPLE_DATA_<Module>.md` + รวมใน `PACK_INSTALL_<Module>.sql`
- Preview → ฝังใน `DB_SPEC_<Module>.md`

## Output Format

Output ต้องแยกเป็น **2 ส่วน** เสมอ:

---

### ส่วนที่ A — Full File: `SAMPLE_DATA_<Module>.md` (≥10 records/table)

```markdown
# Sample Data — <Module>

**DBMS:** <DBMS>  |  **Volume:** ≥10 records/table  |  **Locale:** TH / EN
**Related Spec:** [DB_SPEC_<Module>.md](./DB_SPEC_<Module>.md)

### Business Format Applied

| Field | Pattern | Example |
|-------|---------|---------|
| customer_id | `CUS-YYYY-#####` | CUS-2026-00001 |
| order_no | `ORD/YYYY/MM/####` | ORD/2026/05/0001 |
| employee_id | `EMP#####` | EMP00123 |

### Relationship Map

```
CUSTOMER (5 records)
  └── ORDER (8 records, 3 ลูกค้าไม่เคยสั่ง, 2 ลูกค้าสั่งหลายครั้ง)
        └── ORDER_ITEM (15 records)
PRODUCT (10 records, 2 records ไม่เคยถูกสั่ง)
```

### Full INSERT Script (≥10 records/table)

```sql
-- ===================================================
-- Sample Data for <Module>
-- Generated for Unit Test / Demo
-- Minimum 10 records per table
-- ===================================================

-- Step 1: Parent — CUSTOMER (10 records)
INSERT INTO customer (customer_id, customer_name, email, created_at) VALUES
('CUS-2026-00001', 'สมชาย ใจดี',       'somchai@example.com',     '2026-01-15'),
('CUS-2026-00002', 'Mary Johnson',    'mary.j@example.com',      '2026-02-20'),
('CUS-2026-00003', 'สุดารัตน์ แก้วใส',  'sudarat@example.com',     '2026-02-22'),
('CUS-2026-00004', 'John Smith',      'john.smith@example.com',  '2026-03-01'),
('CUS-2026-00005', 'อภิชาติ ทองคำ',    'apichat@example.com',     '2026-03-05'),
('CUS-2026-00006', 'Linda Brown',     'linda.b@example.com',     '2026-03-10'),
('CUS-2026-00007', 'วรรณา ศรีสุข',     'wanna@example.com',       '2026-03-15'),
('CUS-2026-00008', 'David Lee',       'david.lee@example.com',   '2026-04-01'),
('CUS-2026-00009', 'ปิยะ มากมี',       'piya@example.com',        '2026-04-10'),
('CUS-2026-00010', 'Sarah Wilson',    'sarah.w@example.com',     '2026-04-20')
;

-- Step 2: Parent — PRODUCT (10 records)
-- ... (10 rows minimum)

-- Step 3: Child — ORDER (10 records, varied scenarios)
-- ... (10 rows minimum)

-- Step 4: Junction — ORDER_ITEM (≥10 records)
-- ... (10+ rows minimum)
```

### Constraint Check Result

- ✅ NOT NULL ครบทุก Column
- ✅ UNIQUE (email) ไม่ชน
- ✅ FK customer_id, product_id อ้างอิงถูก
- ✅ CHECK quantity > 0 ผ่าน
- ✅ ≥10 records ต่อ table

### Notes for Dev

- ข้อมูล PII (email, ชื่อ) เป็น fake ทั้งหมด — ปลอดภัยสำหรับ Test Environment
- ขนาด dataset เล็ก ออกแบบเพื่อ test logic ไม่ใช่ load test
- หากต้องการ Load Test → แนะนำใช้ tool generator (faker, mockaroo) ต่อ
```

---

### ส่วนที่ B — Preview ใส่ใน `DB_SPEC_<Module>.md` (2-3 records/table)

```markdown
## Sample Data Preview

> ตัวอย่างย่อ — ดูข้อมูลเต็ม (≥10 records/table) ใน [SAMPLE_DATA_<Module>.md](./SAMPLE_DATA_<Module>.md)

### CUSTOMER (preview 2 of 10)

| customer_id     | customer_name | email                | created_at  |
|-----------------|---------------|----------------------|-------------|
| CUS-2026-00001  | สมชาย ใจดี      | somchai@example.com  | 2026-01-15  |
| CUS-2026-00002  | Mary Johnson  | mary.j@example.com   | 2026-02-20  |

### PRODUCT (preview 3 of 10)

| product_id | product_name        | unit_price |
|------------|---------------------|------------|
| 1          | Coffee Beans 250g   | 180.00     |
| 2          | Espresso Machine    | 25000.00   |
| 3          | Milk Frother        | 1200.00    |

### ORDER (preview 2 of 10)

| order_id | customer_id    | order_date | total_amount |
|----------|----------------|------------|--------------|
| 1001     | CUS-2026-00001 | 2026-03-01 | 540.00       |
| 1002     | CUS-2026-00004 | 2026-03-12 | 26200.00     |
```

## Notes

- หาก SA ไม่ระบุ Business Format → ใช้สากล (เช่น `customer_id` เป็น integer 1,2,3) และใส่ Note ว่าต้องปรับเป็น Format จริงก่อน production test
- หาก Schema มี Encrypted / Hashed field → ระบุว่าค่าใน Sample เป็น placeholder
- **บังคับ:** Preview ใน DB_SPEC ต้องเป็น subset ของ Full File เพื่อให้ค่าตรงกัน (ห้ามสร้างคนละชุด)
- **บังคับ:** Reference / Lookup Table ต้องถาม SA ก่อนเสมอ ห้าม AI เดาค่า — ถ้า SA ไม่ส่งข้อมูลให้ skip ตารางนั้น + Note ใน Output
- **บังคับ (Critical):** ไฟล์ `SAMPLE_DATA_<Module>.md` ต้องมี `INSERT INTO` SQL statement ครบทุก record ใน fenced ` ```sql ` block — ห้าม output เป็น Markdown table อย่างเดียว (Markdown table ใช้แค่ใน Preview ของ DB_SPEC) Dev ต้อง copy SQL ไป run ได้ทันที
