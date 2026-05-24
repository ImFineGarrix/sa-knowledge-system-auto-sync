---
name: db-create-procedure
description: ใช้ skill นี้สำหรับช่วย SA สร้าง Stored Procedure ออกมาเป็น Source Code โดย AI จะสัมภาษณ์ Input Parameters, Return / Output Parameters, Flow การทำงานของ Procedure แล้วเรียบเรียงเป็น Source Code ตาม Dialect ของ DBMS (PL/SQL, T-SQL, PL/pgSQL, MySQL Stored Routine) เพื่อให้ Dev review ต่อ Trigger ได้แก่ 'stored procedure', 'create procedure', 'SP', 'procedure', 'PL/SQL', 'T-SQL', 'function', 'database function' หรือเมื่อ parent skill เรียกใช้
---

# db-create-procedure

> **🚨 Sub-Skill Trigger Enforcement (Rule 4):** Skill นี้ต้องถูกเรียกจาก parent (`db-create-spec`) เมื่อ Module มี Stored Procedure / Function — ห้าม orchestrator เขียน SP source code inline โดยไม่เรียก skill นี้

## Role & Goal

Skill นี้ช่วย SA ร่าง **Stored Procedure / Function** ออกมาเป็น Source Code โดย:
1. สัมภาษณ์ Input Parameters
2. สัมภาษณ์ Return / Output Parameters
3. สัมภาษณ์ Flow การทำงาน (Business Logic)
4. เรียบเรียงเป็น Source Code ตาม Dialect ของ DBMS
5. ให้ Dev นำไป Review

> **หมายเหตุ:** Source Code ที่ Generate เป็น **Draft** เสมอ ต้องผ่านการ Review จาก Dev และ Test ผ่าน `db-test-sql` ก่อนใช้งานจริง

## Inherited Global Rules

สืบทอดจาก `db-create-spec`:
- กฎข้อ 5 (Sargable Queries) — หลีกเลี่ยงฟังก์ชันครอบ field ใน WHERE
- กฎข้อ 6 (Comment in Script) — Procedure ต้องมี Comment อธิบาย Input/Output/Flow
- กฎข้อ 7 (Code & SQL Untouched) — Source Code ภาษาอังกฤษล้วน
- กฎข้อ 8 (Database Engine Specification) — Syntax ตาม DBMS Dialect
- **กฎข้อ 10 (File Finalization & Delivery)** — Output ของ skill นี้ **แยกเป็นไฟล์ของตัวเอง `STORED_PROCEDURE_<Module>.sql`** (ไม่รวมใน `PACK_INSTALL_<Module>.sql`) — ดูตาราง Mandatory Companion File Split ใน db-create-spec.md กฎข้อ 10
- **กฎข้อ 11 (Database Conversion)** — Mode Convert ต้อง rewrite SP ตาม Dialect ของ Target DBMS
- **🏢 Type-Prefix Convention เฉพาะตอน rename Reserved Word (สืบทอด Rule 4):** Type-Prefix Convention ใช้กับ SP parameter / variable / temp table column **เฉพาะกรณีที่ชื่อตรงกับ Reserved Word ของ DBMS** เท่านั้น — ชื่อทั่วไปใช้ snake_case ปกติ (เหมือนกฎ column ใน schema)
  - **ตัวอย่างที่ใช้ Type-Prefix (ชื่อชนกับ Reserved Word):**
    - `@key` (MSSQL reserved) → `@n_key` (เพราะเป็น INT)
    - `@condition` (MySQL reserved) → `@s_condition` (เพราะเป็น VARCHAR)
    - `@desc` (MySQL reserved) → `@s_desc`
  - **ตัวอย่างที่ใช้ชื่อปกติ (ไม่ใช่ Reserved Word):**
    - `@customer_id` ไม่ใช่ reserved → ใช้ `@customer_id` ไม่ต้องเติม prefix
    - `@order_date` ไม่ใช่ reserved → ใช้ `@order_date`
    - `@is_priority` ไม่ใช่ reserved → ใช้ `@is_priority`
  - **เมื่อเจอ parameter ชนกับ Reserved Word:** เรียก skill [`db-rename-reserved-word`](./db-rename-reserved-word.md) เพื่อ rename ให้ตรงกับ Type-Prefix Convention
  - **ตัวอย่าง mixed (MSSQL):**
    ```sql
    CREATE PROCEDURE sp_process_order(
        @customer_id      INT,                                          -- ปกติ ไม่ใช่ reserved
        @customer_name    VARCHAR(100) COLLATE Latin1_General_100_BIN2_UTF8,
        @order_date       DATE,
        @n_key            INT,                                          -- key เป็น reserved → n_key
        @is_priority      BIT
    )
    AS BEGIN
        DECLARE @temp_var VARCHAR(255) COLLATE Latin1_General_100_BIN2_UTF8;
        DECLARE @total DECIMAL(10,2);
        ...
    END
    ```
  - **ห้ามใช้ camelCase / PascalCase** กับ parameter เช่น ห้าม `@customerName` — ใช้ `@customer_name`
- **🚨 กฎข้อ 12 (Collation Enforcement — Critical)** — SP ทุกตัวที่มี text variables / parameters / temp tables / cursors ต้องระบุ `COLLATE` clause explicit:
  - **Text Parameters:** `@name VARCHAR(100) COLLATE Latin1_General_100_BIN2_UTF8` (MSSQL) หรือ equivalent
  - **Text Variables:** `DECLARE @temp VARCHAR(255) COLLATE Latin1_General_100_BIN2_UTF8`
  - **Temp Tables / Table Variables:** text columns ต้องมี `COLLATE` clause
  - **Cross-DB / Cross-Server Joins:** หาก SP join column จาก database ที่ collation ต่างกัน → ใส่ `COLLATE` clause ใน ON / WHERE / COMPARE expression เพื่อป้องกัน error `Cannot resolve the collation conflict between "X" and "Y"`
  - **ตัวอย่างการใส่ COLLATE clause ใน Comparison:**
    ```sql
    -- ถ้าเทียบ string จาก 2 ตารางที่ collation ต่างกัน
    SELECT * FROM table_a a
        INNER JOIN table_b b
            ON a.code COLLATE Latin1_General_100_BIN2_UTF8 = b.code COLLATE Latin1_General_100_BIN2_UTF8;
    ```
  - **Default Inheritance:** ถ้า SP สร้างใน database ที่ collation = baseline แล้ว → text variable inherit ค่า default — แต่ยังต้องระบุ explicit เพื่อ portability เมื่อ deploy ข้าม environment

## Pre-Run Check

ต้องถาม DBMS แบบ Multiple Choice ก่อนเริ่มเสมอ (กฎข้อ 8) เนื่องจาก Stored Procedure Syntax ต่างกันมากระหว่าง engine:
- Oracle: PL/SQL (`CREATE OR REPLACE PROCEDURE ... IS ... BEGIN ... END;`)
- MSSQL: T-SQL (`CREATE PROCEDURE ... AS BEGIN ... END`)
- PostgreSQL: PL/pgSQL (`CREATE FUNCTION ... LANGUAGE plpgsql AS $$ ... $$`)
- MySQL: Stored Routine (`CREATE PROCEDURE ... BEGIN ... END; DELIMITER`)
- DB2: SQL PL (`CREATE PROCEDURE ... BEGIN ATOMIC ... END`)
- Informix: SPL (`CREATE PROCEDURE ... DEFINE ... END PROCEDURE`)

## Operation Flow

### Step 1: Procedure Identity
ถามชื่อ Procedure + Purpose สั้นๆ
```
- ชื่อ Procedure: _______
- หน้าที่: _______
- เรียกจากที่ไหน (Application / Trigger / Job): _______
```

### Step 2: Input Parameters
ถามทีละ parameter:
```
| Param Name | Data Type | Required | Default | Description |
|-----------|-----------|----------|---------|-------------|
```

### Step 3: Output / Return
ถาม Output:
- คืนค่าเป็น scalar (เช่น integer status code)?
- คืนค่าเป็น OUT parameter?
- คืนค่าเป็น Result Set / Cursor?
- ไม่คืนค่า (Procedure ที่ทำ action เท่านั้น)?

### Step 4: Flow / Business Logic
สัมภาษณ์ขั้นตอนการทำงานเป็นข้อๆ เช่น:
```
1. ตรวจสอบว่า customer_id มีอยู่จริงไหม → ถ้าไม่มี return -1
2. คำนวณ total amount จาก order_items
3. update credit_balance ของลูกค้า
4. insert log การทำธุรกรรม
5. return success code 0
```

### Step 5: Error Handling
ถาม Error Handling:
- Exception ที่ต้อง catch (เช่น `NO_DATA_FOUND`, `DUP_VAL_ON_INDEX`)
- จะ rollback transaction อัตโนมัติหรือไม่
- Log error ที่ไหน

### Step 6: Generate Source Code
เรียบเรียงเป็น Source Code ตาม Dialect พร้อม Comment ทุก section

### Step 7: Mode Convert Handling (เฉพาะ Mode Convert)
ถ้า parent ส่งมาในโหมด Convert:
- รับ Source SP จาก SA + Target DBMS Info จาก parent
- **Rewrite SP** ตาม Dialect ของ Target DBMS (PL/SQL → T-SQL → MySQL Stored Routine ฯลฯ)
- ระบุ Feature ที่ไม่ converted ตรงๆ:
  - `PACKAGE` (Oracle) → ต้องแตกเป็นหลาย Procedure ใน Target
  - `BULK COLLECT` (Oracle) → แทนด้วย Cursor Loop ใน MySQL
  - `OUTPUT` clause (MSSQL) → แทนด้วย RETURNING (PostgreSQL) / Trigger (MySQL)
- รายงาน Unsupported Feature + Workaround ใน Output (ส่งกลับ parent → ใส่ใน `CONVERT_<Module>.md`)
- **Side-by-side Diff:** ใส่ comment ใน Source Code เปรียบเทียบ Source vs Target ทุก section ที่ rewrite

### Step 8: Hand-off (เขียนไฟล์แยก `STORED_PROCEDURE_<Module>.sql`)
- Output SP ทั้งหมดของ Module **รวมเป็นไฟล์เดียว** `STORED_PROCEDURE_<Module>.sql` (UPPER_SNAKE consistent กับกฎข้อ 10)
- แบ่ง Section ในไฟล์ด้วย Comment:
  ```sql
  -- ==========================================================
  -- STORED_PROCEDURE_<Module>.sql
  -- DBMS: <DBMS> v<Version>   Module: <Module>   Generated: YYYY-MM-DD
  -- ==========================================================

  -- =========== SP 1: sp_process_order ===========
  CREATE PROCEDURE sp_process_order ... ;

  -- =========== SP 2: fn_calc_credit ===========
  CREATE FUNCTION fn_calc_credit ... ;
  ```
- ส่ง path ของไฟล์กลับ parent (`db-create-spec`) เพื่อ link ใน DB_SPEC ส่วน Related Files
- ส่ง summary table ของ SP ทั้งหมดให้ orchestrator ฝังใน DB_SPEC ส่วน Stored Procedures (ไม่ใส่ Source Code เต็มใน DB_SPEC)
- หาก Dev แก้กลับมา → AI update ไฟล์ `STORED_PROCEDURE_<Module>.sql` + บันทึก entry ใน CHANGELOG

## Output Format

```markdown
## Stored Procedure — <Procedure Name>

**DBMS:** <DBMS> v<Version>  |  **Type:** Procedure / Function

### Purpose
<หน้าที่หลักของ Procedure>

### Input Parameters

> **Naming Convention:** ใช้ snake_case ตามปกติ — Type-Prefix Convention (`s_`, `n_`, `d_`, `t_`, `f_`) ใช้ **เฉพาะ** กรณีชื่อชนกับ Reserved Word ของ DBMS

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| customer_id | INT | Yes | - | รหัสลูกค้า |
| order_date | DATE | No | CURRENT_DATE | วันที่ Order |

### Output / Return

| Name | Type | Description |
|------|------|-------------|
| RETURN | INT | Status code: 0=success, -1=customer not found, -2=insufficient credit |

### Business Flow

1. ตรวจสอบ customer_id
2. คำนวณ total
3. update credit_balance
4. insert transaction log
5. return code

### Error Handling

- NO_DATA_FOUND → return -1
- ใดๆ → ROLLBACK + return -99 + log error

### Source Code (Draft)

```sql
-- ตัวอย่าง MySQL Stored Procedure
-- ใช้ชื่อปกติ (snake_case) — Type-Prefix ใช้เฉพาะตอนชื่อชนกับ Reserved Word
DELIMITER $$

CREATE PROCEDURE sp_process_order(
    IN  p_customer_id INT,
    IN  p_order_date  DATE,
    OUT p_status_code INT
)
BEGIN
    DECLARE v_total DECIMAL(10,2);

    -- Step 1: Validate customer
    IF NOT EXISTS (SELECT 1 FROM customer WHERE customer_id = p_customer_id) THEN
        SET p_status_code = -1;
        LEAVE;
    END IF;

    -- Step 2-4: process order (simplified)
    -- ...

    SET p_status_code = 0;
END $$

DELIMITER ;
```

### ⚠️ Reviewer Notes (สำหรับ Dev)

- Logic Step 3 ต้องมั่นใจว่า credit_balance ไม่ติดลบ
- Error handling ตอนนี้ครอบเฉพาะ customer not found — ขอ Dev เพิ่มกรณีอื่น
- ต้องผ่าน `db-test-sql` ก่อน deploy production
```

## Notes

- AI ต้อง **ไม่กล้าตัดสินใจ Business Logic เอง** — ทุกขั้นตอนต้องมาจากคำสัมภาษณ์ SA
- Source Code เป็น **Draft** ทุกครั้ง ห้ามใส่ message ว่า "ใช้ได้ทันที"
- หาก Procedure มี Logic ซับซ้อนมาก ให้แตกเป็นหลาย Procedure ย่อย
