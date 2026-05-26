---
name: db-create-index
description: ใช้ skill นี้สำหรับแนะนำและสร้าง Database Index Strategy เพิ่มเติมจาก PK/FK พื้นฐาน โดย AI จะวิเคราะห์จาก Schema, Query Pattern (WHERE, JOIN, ORDER BY, GROUP BY) ที่พบบ่อย และหากมี knowledge ของโปรแกรมจริงจะแนะนำว่าฟิลด์ไหนถูกใช้เป็นเงื่อนไขมากที่สุด Trigger ได้แก่ 'create index', 'index strategy', 'index optimization', 'query performance', 'composite index', 'covering index' หรือเมื่อ parent skill (db-create-spec) เรียกใช้
---

# db-create-index

## Role & Goal

Skill นี้แนะนำและสร้าง **Index Strategy** เพื่อเพิ่ม Performance ของ Query โดย:
1. วิเคราะห์ Schema (จาก `db-create-schema`)
2. รับ Query Pattern จาก SA หรือวิเคราะห์จาก Source Code โปรแกรม (ถ้ามี)
3. แนะนำ Index ที่ควรมี พร้อม Justification
4. Generate `CREATE INDEX` Script

> **🚨 Sub-Skill Trigger Enforcement (Rule 4):** Skill นี้ต้องถูกเรียกจาก parent (`db-create-spec` หรือ `db-create-schema`) เมื่อต้องการ Index Strategy เพิ่มเติม — ห้าม orchestrator แนะนำ Index ขั้นสูง inline โดยไม่เรียก skill นี้

## Inherited Global Rules

สืบทอดจาก `db-create-spec`:
- **กฎข้อ 5 (Performance)** — แกนหลัก
- **กฎข้อ 10 (File Finalization & Delivery)** — Index DDL ของ skill นี้ **แยกเป็นไฟล์ `INDEX_<Module>.sql`** (ไม่รวมใน PACK_INSTALL อีกต่อไป) ส่วน Index Strategy table จะถูกฝังใน `DB_SPEC_<Module>.md` ใต้ Data Dict ของแต่ละ table — run หลัง PACK_INSTALL ใน install order
- **🚨 กฎข้อ 12 (Collation Enforcement)** — Index บน text column ต้อง **inherit collation** จาก column โดยอัตโนมัติ + ห้ามใช้ function ที่เปลี่ยน collation ใน Index expression — ดู Collation Awareness section ด้านล่าง
- **🏢 Type-Prefix Convention (สืบทอด Rule 4):** `CREATE INDEX` statement ต้อง reference ชื่อ column / table ที่ผ่าน rename จาก Reserved Words Check แล้ว:
  - ❌ `CREATE INDEX sales_idx1 ON sales (key)` — ใช้ชื่อ column เก่า ห้าม
  - ✅ `CREATE INDEX sales_idx1 ON sales (n_key)` — ใช้ชื่อ column ใหม่หลัง rename
- **🚨 Index Naming Pattern (บังคับ — Company Standard):** ใช้ `<table>_idx<N>` เป็น naming pattern เดียวกันทั้ง **Non-Unique** และ **Unique** indexes — ห้ามแยก prefix `ux_`, `uk_`, `pk_` ฯลฯ
  - **Format:** `<table_name>_idx<N>` โดย `<N>` เป็น sequential number per table เริ่มที่ 1
  - **Examples:**
    - `customer_idx1` — first index of `customer` table (no matter unique or not)
    - `customer_idx2` — second index
    - `order_idx1`, `order_idx2`, `order_idx3` — indexes ของ `order` table
  - **Unique indexes ใช้ pattern เดียวกัน** — ระบุ uniqueness ผ่าน `CREATE UNIQUE INDEX` keyword ใน DDL, **ไม่ใช่ที่ชื่อ index**:
    ```sql
    CREATE UNIQUE INDEX customer_idx1 ON customer (email);  -- unique
    CREATE INDEX customer_idx2 ON customer (created_at);    -- non-unique
    ```
  - **Per-Table Counter:** numbering reset per table — `customer_idx1` กับ `order_idx1` แยกกันคนละ counter
  - **PK ไม่นับ:** Primary Key index (auto-created) ไม่ใช้ pattern นี้ — ใช้ default ของ DBMS
  - **Case Style:** lowercase ทั้งหมด (`customer_idx1`) — ตาม Rule 4 Case Style Lock
  - ❌ ห้าม: `idx_customer_email`, `uk_customer_email`, `UX_CUSTOMER_BIZKEY`, `IX_customer_idx1`

รายละเอียดจากกฎข้อ 5:

- **Index Strategy:** ทุกตารางมี PK และต้องแนะนำ Index ใน Field ที่ใช้ `WHERE`, `JOIN`, `ORDER BY`, `GROUP BY` บ่อย
- **Sargable Queries:** หลีกเลี่ยง Query ที่ทำให้ Index ใช้ไม่ได้ (ฟังก์ชันครอบ field ใน WHERE)
- **DBMS Dialect:** Index Syntax ต่างกันบ้างระหว่าง DBMS (เช่น `INCLUDE` ใน MSSQL/PostgreSQL, `WHERE` partial index ใน PostgreSQL)

### Collation Awareness (บังคับ — Rule 12)

Index บน text column มีพฤติกรรมที่ขึ้นกับ collation — ต้องระวัง:

1. **Inherit Collation:** Index ที่สร้างบน text column ใช้ collation ของ column นั้นโดยอัตโนมัติ — **ไม่ต้องระบุ `COLLATE` ใน `CREATE INDEX`** (ยกเว้น MSSQL filtered index ที่มี literal ใน WHERE)
2. **Sargability Warning:** หาก query มี `WHERE col COLLATE Other = 'value'` → query optimizer จะ **ไม่ใช้ index** เพราะ collation ของ predicate ต่างจาก column → ต้องเตือน SA ว่า query ที่จะใช้ index นี้ห้ามมี `COLLATE` clause override
3. **Composite Index — Consistent Collation:** Composite index ที่รวมหลาย text column → ทุก column ต้องใช้ collation เดียวกัน (ถ้าตาม Rule 12 = baseline ทั้งหมด อยู่แล้ว) — ถ้ามี column ที่ exception collation ต้อง flag ใน Trade-off Notes
4. **Case-Sensitive Index Behavior:** เพราะ baseline = `Latin1_General_100_BIN2_UTF8` (case-sensitive) → search `WHERE email = 'admin@x.com'` กับ `'Admin@X.com'` จะให้ผลต่างกัน + ใช้ index ต่างวิธี — กระทบ application logic ที่เคย assume case-insensitive
5. **Function-Based / Computed Column Index:** หากต้องการ case-insensitive search → สร้าง computed column `LOWER(email)` แล้ว index บน computed column นั้น (ห้ามใช้ `LOWER()` ใน WHERE โดยตรงเพราะ break sargability)

## Operation Flow

1. **Receive Schema:** รับ Schema จาก parent หรือ `db-create-schema`
2. **Query Pattern Collection:** ถาม SA:
   - Field ไหนถูกใช้ใน WHERE บ่อย?
   - มี JOIN ระหว่างตารางไหนบ้าง?
   - มี ORDER BY / GROUP BY ที่ต้องเร็วเป็นพิเศษไหม?
   - ความถี่ของ Read vs Write (Read-heavy ใส่ Index ได้เยอะ, Write-heavy ต้องระวัง)
3. **Source Code Analysis** *(ถ้ามี)***:** หาก SA แนบ Source Code หรือ Query Log → AI วิเคราะห์ pattern อัตโนมัติ
4. **Index Recommendation:** เสนอ Index ในรูปแบบ:
   - **Single-Column Index:** สำหรับ Filter พื้นฐาน
   - **Composite Index:** สำหรับ Filter หลาย Column พร้อมกัน (เรียงตาม Selectivity)
   - **Covering Index:** สำหรับ Query ที่ Select เฉพาะ Column ที่อยู่ใน Index
   - **Unique Index:** สำหรับ Business Unique Constraint (ที่ไม่ใช่ PK)
   - **Partial Index** *(PostgreSQL)***:** เฉพาะ row ที่ตรงเงื่อนไข
5. **Justification:** ทุก Index ที่เสนอต้องมี **เหตุผล** (Query ไหนใช้ + ลด Latency ได้ประมาณเท่าไหร่)
6. **Trade-off Warning:** เตือน trade-off เช่น
   - Index มากเกิน → Slow INSERT/UPDATE/DELETE
   - Index Composite ที่ไม่เรียง column ถูก → ไม่ถูกใช้
   - **Collation Sargability (Rule 12):** Index บน text column ใช้ collation ของ column — Query ที่มี `COLLATE` override จะไม่ใช้ index
   - **Case-Sensitivity Behavior:** Baseline collation BIN2 = case-sensitive — `WHERE name = 'X'` จะไม่ match `'x'` — ถ้าต้องการ case-insensitive ใช้ computed column + index
7. **DDL Generation:** Generate `CREATE INDEX` ตาม Dialect
8. **Hand-off:** สร้างไฟล์ `INDEX_<Module>.sql` (separate file — **ไม่รวมใน PACK_INSTALL อีกต่อไป**) — Header ระบุ install order: "Run AFTER PACK_INSTALL". ส่ง Index Strategy table ให้ orchestrator ฝังใน `DB_SPEC_<Module>.md` (ใต้ Data Dictionary ของแต่ละ Table — ดูกฎ "Per-Table Index Detail" ด้านล่าง):

   ```sql
   -- ============================================================
   -- INDEX_<Module>.sql — CREATE INDEX statements
   -- DBMS: <DBMS> v<Version>   Module: <Module>   Generated: YYYY-MM-DD
   -- Install Order: Run AFTER PACK_INSTALL_<Module>.sql
   -- ============================================================
   USE <db_name>;

   -- ทุก index ใช้ <table>_idx<N> pattern (รวม unique)
   CREATE INDEX customer_idx1 ON customer (customer_id, created_at DESC);
   CREATE UNIQUE INDEX customer_idx2 ON customer (email);
   -- ...
   ```

### Per-Table Index Detail (บังคับ)

ใน `DB_SPEC_<Module>.md` ใต้ Data Dictionary ของแต่ละ Table ต้องมี subsection ระบุชัดว่า **Table นี้สร้าง Index อะไรบ้าง** เพื่อ traceability:

```markdown
#### Table: `order`
*(Data Dictionary table here)*

**Indexes on this table:**
| Index Name | Columns | Type | Purpose |
|------------|---------|------|---------|
| (PK auto) | (order_id) | Primary Clustered | Primary Key |
| order_idx1 | (customer_id, order_date DESC) | Composite (Non-Unique) | Query "ดู Order ล่าสุดของลูกค้า" |
| order_idx2 | (customer_id) | Single (FK Index) | JOIN กับ customer |
| order_idx3 | (order_no) | Single (Unique) | Business Unique Key |
```

หลักการ: SA/Dev เปิด DB_SPEC แล้ว **เลื่อนลงดู Table ไหน → เห็น Index ของ Table นั้นทันที** ไม่ต้องวิ่งหา Index list รวมที่อื่น

## Output Format

```markdown
## Index Strategy — <Module>

**DBMS:** <DBMS> v<Version>

### Recommended Indexes

| # | Index Name | Table | Columns | Type | Justification |
|---|-----------|-------|---------|------|---------------|
| 1 | order_idx1 | order | (customer_id, order_date DESC) | Composite (Non-Unique) | Query "ดู Order ล่าสุดของลูกค้า" ใช้บ่อย |
| 2 | product_idx1 | product | (product_name) | Single (Non-Unique) | Search Product ด้วยชื่อ |
| 3 | customer_idx1 | customer | (email) | Single (Unique) | Business: email ห้ามซ้ำ |

### CREATE INDEX Script

```sql
-- Composite index for customer's recent orders (non-unique)
CREATE INDEX order_idx1
    ON order (customer_id, order_date DESC);

-- Search product by name (non-unique)
CREATE INDEX product_idx1
    ON product (product_name);

-- Unique constraint on customer email (UNIQUE keyword, ชื่อยังคง pattern <table>_idx<N>)
CREATE UNIQUE INDEX customer_idx1
    ON customer (email);
```

### Trade-off Notes

- ⚠️ ORDER table มี Index 3 ตัวแล้ว (PK + FK + composite) — Write operation อาจช้าลง 5-10%
- 💡 ถ้า Query "search product" ไม่บ่อย ให้พิจารณาตัด idx_product_name ออก

### Future Enhancement

- หากมี Query Log จริง → AI สามารถวิเคราะห์ Hot Query อัตโนมัติและเสนอ Index เพิ่ม
- หากมี Source Code → วิเคราะห์ ORM / SQL Builder เพื่อหา Pattern
```

## Notes

- Index ที่มากับ PK / FK พื้นฐาน ให้ `db-create-schema` ดูแล — skill นี้รับผิดชอบเฉพาะ **Index เพิ่มเติม** เพื่อ Performance
- หาก Mode Modify ที่มี Schema เดิม ให้ตรวจ Index เดิมก่อน เพื่อไม่สร้างซ้ำ
