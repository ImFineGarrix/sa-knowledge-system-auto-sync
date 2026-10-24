---
name: db-create-erd
description: ใช้ skill นี้สำหรับสร้าง ER Diagram (Entity Relationship Diagram) ของฐานข้อมูล โดย AI จะ output เป็น Mermaid `erDiagram` เท่านั้น พร้อมระบุ PK, FK, Data Type และ Cardinality (one-to-one, one-to-many, many-to-many) Trigger ได้แก่ 'ER diagram', 'ERD', 'entity relationship', 'mermaid erDiagram', 'database relationship', 'data model' หรือเมื่อ parent skill (db-create-spec) เรียกใช้เพื่อออกแบบความสัมพันธ์ระหว่าง Entity
---

# db-create-erd

## Role & Goal

Skill นี้สร้าง **ER Diagram** จาก Business Scope หรือ Data Dictionary ที่ SA ให้มา **โดย output เป็น Mermaid `erDiagram` เท่านั้น** ห้ามใช้ Format อื่น

> **🚨 Sub-Skill Trigger Enforcement (Rule 4):** Skill นี้ต้องถูกเรียกจาก parent (`db-create-spec`) เมื่อมีการออกแบบ Entity Relationship — ห้าม orchestrator วาด ERD เอง inline โดยไม่เรียก skill นี้

## Inherited Global Rules

สืบทอดจาก `db-create-spec`:
- **กฎข้อ 9 (ER Diagram Format)** เป็นแกนหลัก
- **กฎข้อ 10 (File Finalization & Delivery)** — ERD **ไม่แยกเป็นไฟล์** แต่ **ฝัง mermaid block ใน `DB_SPEC_<Module>.md` ภายใต้หัวข้อ Entity Relationship** (ดูตาราง Mandatory Companion File Split ใน db-create-spec.md กฎข้อ 10)
- **🏢 Type-Prefix Convention (สืบทอด Rule 4):** Attribute name + Entity name ใน Mermaid `erDiagram` ต้องใช้ **ชื่อสุดท้ายหลัง rename** จาก Reserved Words Check (skill `db-rename-reserved-word`):
  - Column `key` (reserved ใน MSSQL) → ERD แสดง `int n_key PK` ไม่ใช่ `int key PK`
  - Table `index` (reserved ใน MSSQL) → ERD เขียน `S_INDEX { ... }` ไม่ใช่ `INDEX { ... }` (UPPERCASE ของ snake_case)
  - หาก ERD ถูกสร้าง**ก่อน** Reserved Words Check ของ `db-create-schema` → ต้อง update ERD หลังได้ rename map กลับมา (ตรวจ inconsistency ระหว่าง ERD กับ Data Dictionary)

รายละเอียดจากกฎข้อ 9:

- **Mermaid Only (บังคับ):** ไม่ใช้ PlantUML, Graphviz/DOT, ASCII Art, Textual List, รูปภาพ หรือ Markdown Table
- **Code Fence Required:** ครอบด้วย ` ```mermaid ` เสมอ
- **Standard Notation:** ใช้สัญลักษณ์ Mermaid:
  - `||--||` — one-to-one
  - `||--o{` — one-to-many
  - `}o--o{` — many-to-many
  - `||--o|` — one-to-zero-or-one
- **Verb Phrase:** ต้องระบุ Verb Phrase ของความสัมพันธ์ (เช่น "places", "contains", "belongs_to")
- **Attribute Detail:** ทุก Entity ต้องระบุ Attribute สำคัญ + Data Type + Key Marker — **`PK` และ `FK` เท่านั้น** (ห้ามใส่ `UK` — UNIQUE info ไปอยู่ใน Index Strategy section ของ DB_SPEC ตาม Rule 9)
- **No Fallback:** ถ้า Environment ไม่รองรับก็ส่ง Mermaid Source Code อยู่ดี — เก็บไว้ใน DB_SPEC เป็น mermaid block ปกติ

## Operation Flow

1. **Input Collection:** รับ Input จาก parent หรือถาม SA โดยตรง:
   - Entity ทั้งหมดในระบบ + Attribute หลัก
   - ความสัมพันธ์ระหว่าง Entity (เป็นข้อความก็ได้ เช่น "Customer สั่ง Order ได้หลายครั้ง")
   - PK / FK ที่ทราบ
2. **Cardinality Analysis:** แปลงคำอธิบายเป็น Cardinality ตามมาตรฐาน Mermaid
3. **Diagram Construction:** เขียน Mermaid `erDiagram` block
4. **SA Review:** แสดง Diagram ให้ SA Review หากมีการแก้ไขให้ Iterate ตามจนพอใจ
5. **Hand-off (ฝังใน DB_SPEC):** ส่ง Mermaid Source กลับ parent (`db-create-spec`) เพื่อ **ฝังใน `DB_SPEC_<Module>.md` ส่วน Entity Relationship** ตามรูปแบบ:

   ````markdown
   ## Entity Relationship

   <ข้อความบรรยายสั้นๆ ของระบบ 1-2 บรรทัด>

   ```mermaid
   erDiagram
       <ENTITY> ||--o{ <ENTITY> : <verb>
       ...
   ```

   ### Relationship Summary
   | From | Verb | To | Cardinality |
   |------|------|-----|-------------|
   | ... | ... | ... | ... |
   ````

   จากนั้นไปต่อ `db-create-schema` (โดยที่ ERD block ใน DB_SPEC จะเป็น single source of truth สำหรับเรื่อง entity / relationship)

## Output Format

ผลลัพธ์ของ skill นี้คือ **block ที่จะถูกฝังใน `DB_SPEC_<Module>.md`** (ไม่ใช่ไฟล์แยก) โดยมีโครงสร้าง 3 ส่วน: Header Block → Mermaid ERD → Relationship Summary

### Header Block (บังคับ — ใส่ก่อน mermaid block)

```
**Module:** <Module>  |  **DBMS:** <DBMS> v<Version>  |  **Generated:** YYYY-MM-DD
**Source:** Input from SA / Parent (db-create-spec)
**Notation:** Mermaid erDiagram (กฎข้อ 9)
```

### Mermaid ERD (ใช้ Mermaid ตรงๆ ไม่ครอบ nested fence)

```mermaid
erDiagram
    CUSTOMER ||--o{ ORDER : places
    CUSTOMER {
        int customer_id PK
        varchar(100) customer_name
        varchar(50) email
        date created_at
    }
    ORDER ||--|{ ORDER_ITEM : contains
    ORDER {
        int order_id PK
        int customer_id FK
        decimal(10,2) total_amount
        date order_date
    }
    PRODUCT ||--o{ ORDER_ITEM : "is ordered as"
    PRODUCT {
        int product_id PK
        varchar(200) product_name
        decimal(10,2) unit_price
    }
    ORDER_ITEM {
        int order_id PK,FK
        int product_id PK,FK
        int quantity
        decimal(10,2) line_total
    }
```

> **Note:** `email` ใน CUSTOMER เป็น UNIQUE — info นี้ไม่ใส่ใน ERD แต่ระบุใน Index Strategy section ของ DB_SPEC แทน (Rule 9 — Key Marker Policy)

### Relationship Summary

| From | Verb | To | Cardinality |
|------|------|-----|-------------|
| CUSTOMER | places | ORDER | one-to-many |
| ORDER | contains | ORDER_ITEM | one-to-many |
| PRODUCT | is ordered as | ORDER_ITEM | one-to-many |

> **เหตุผลที่เก็บ Mermaid:** Dev ดู rendered diagram ใน Markdown preview ได้ทันที + ปรับแก้ source ได้ตรงๆ ไม่ต้องเปิด tool อื่น

## Notes

- **PK Composite:** ใช้ `PK,FK` ในกรณี Composite Key (เช่น ORDER_ITEM)
- **Naming:** Entity name ใน Mermaid ให้ใช้ UPPERCASE เพื่อความชัดเจน (ส่วนชื่อจริงใน DDL ขึ้นกับ Case Style ที่เลือกใน `db-create-schema`)
- **Comment:** ใช้ `%%` สำหรับ comment ใน Mermaid
- **ไม่ครอบ nested code fence:** เมื่อฝังใน DB_SPEC ให้วาง ``` ```mermaid ``` ``` ตรงๆ ไม่ต้องครอบ ` ```markdown ` ทับอีกชั้น (จะทำให้ render ผิด)
