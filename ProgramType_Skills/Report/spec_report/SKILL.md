---
name: spec_report
description: >
  ใช้ skill นี้ทุกครั้งที่ SA ต้องการสร้าง Technical Functional Specification (TFS) สำหรับ Report Program
  ครอบคลุมงานทุกประเภทที่เกี่ยวกับ Report ไม่ว่าจะเป็นการสร้างรายงานใหม่, แก้ไขรายงานเดิม หรือ convert
  เทคโนโลยี โดยเฉพาะระบบที่ใช้ xdocReport หรือรายงานในกลุ่ม Broker / Trading เช่น Daily Confirmation,
  Portfolio Summary, WHT Report ให้ trigger skill นี้ทันทีเมื่อผู้ใช้พูดถึง /spec_report, "ออก spec report",
  "สร้าง spec รายงาน", "TFS report", หรือบอกว่างานเป็นประเภท Report
---

# spec_report — Report Specification Generator

สร้าง Technical Functional Specification (TFS) สำหรับ Report Program ทุกประเภท
ในรูปแบบไฟล์ `.md` เพื่อให้ Dev นำไปใช้งานต่อได้ทันที

---

## วิธีใช้ Skill นี้

### ขั้นตอนที่ 1 — รวบรวมข้อมูลจาก SA

**ก่อนสร้าง Spec ให้ถามข้อมูลด้านล่าง** หากยังไม่ครบใน context
ข้อมูลที่ไม่มี ให้ใส่ `[TBD]` แล้วระบุไว้ใน Section 8 Pending Items

| # | ข้อมูลที่ต้องการ | จำเป็น | ตัวอย่าง |
|---|---|---|---|
| 1 | ชื่อ Report / Report ID | ✅ | `RPT-001`, `Daily Confirmation` |
| 2 | ประเภทงาน | ✅ | ใหม่ / แก้ไข / Convert Technology |
| 3 | Technology / Report Engine | ✅ | xdocReport, JasperReport, RDLC, SSRS, Excel POI |
| 4 | Output Format | ✅ | PDF / Excel / CSV / On-screen / หลายแบบ |
| 5 | ผู้ใช้งาน (Audience) | ✅ | Back office / ลูกค้า / ผู้บริหาร |
| 6 | Filter / Parameter ที่รับ | ✅ | วันที่, รหัสบัญชี, สาขา ฯลฯ |
| 7 | Layout / Mock-up | ✅ | แนบรูป / ไฟล์ / อธิบายโครงสร้าง Header-Body-Footer |
| 8 | Columns ที่แสดงในรายงาน | ✅ | ชื่อ column, แหล่งข้อมูล, format |
| 9 | Business Rule / Calculation | ⚠️ | สูตรคำนวณ, เงื่อนไขการแสดงผล |
| 10 | Data Source | ⚠️ | Table / View / Stored Procedure / API |
| 11 | Grouping / Sorting | ⚠️ | Group by อะไร, Sort by อะไร |
| 12 | Subtotal / Summary | ⚠️ | มี subtotal ไหม, grand total แสดงอะไร |
| 13 | Output File Naming & Destination | ⚠️ | ชื่อไฟล์, path ปลายทาง |
| 14 | Frequency / Trigger | ⚠️ | Daily batch / On-demand / Scheduled |

> ✅ = จำเป็นต้องมีก่อนสร้าง Spec  
> ⚠️ = ถ้าไม่มีให้ใส่ `[TBD]` และ note ไว้ใน Section 8

---

### ขั้นตอนที่ 2 — สร้าง TFS

**กฎในการ generate:**
- ใช้ข้อมูลที่ SA ให้มาจริง อย่า hard-code ตัวอย่าง
- ถ้า SA แนบ Mock-up หรือรูป ให้ map column จากรูปนั้นโดยตรง
- ถ้า SA แนบ Source Code เดิม ให้ reverse เป็น Spec ก่อน แล้วให้ SA ยืนยัน
- ถ้าข้อมูลไม่ครบ ให้ใส่ `[TBD]` และ list ไว้ใน Section 8 ทุกครั้ง
- Section ที่ไม่เกี่ยวข้องกับ report นั้น ให้ระบุว่า `N/A` พร้อมเหตุผลสั้นๆ

---

## TFS Template (Standard)

ใช้ template นี้ทุกครั้ง ปรับ content ตามข้อมูลของ report นั้นๆ

---

```markdown
# {REPORT_NAME} — Technical Functional Specification

## Report Metadata

| Field          | Detail |
|----------------|--------|
| Report ID      | {REPORT_ID} |
| Report Name (TH) | {ชื่อภาษาไทย} |
| Report Name (EN) | {ชื่อภาษาอังกฤษ} |
| Program Type   | Report |
| Report Sub-type | {Daily Confirmation / Portfolio / WHT / Settlement / Statement / Other} |
| Technology     | {xdocReport / JasperReport / RDLC / SSRS / Excel POI / Other} |
| Output Format  | {PDF / Excel / CSV / On-screen} |
| Trigger        | {On-demand / Daily Batch / Scheduled: เวลา} |
| Audience       | {Back office / ลูกค้า / ผู้บริหาร} |
| Version        | 1.0 |
| Prepared by    | {ชื่อ SA} |
| Date           | {วันที่} |

---

## Section 1 — Overview

{อธิบายวัตถุประสงค์ของรายงาน: ใช้ทำอะไร, ใครใช้, ใช้เมื่อไหร่, ข้อมูลมาจากไหน}

---

## Section 2 — Input Parameters / Filters

| Parameter | Data Type | Required | Description | Default Value |
|-----------|-----------|----------|-------------|---------------|
| {param_1} | {DATE/VARCHAR/INT} | {Y/N} | {คำอธิบาย} | {ค่า default} |
| {param_2} | | | | |

> ถ้าไม่มี parameter ระบุว่า: ไม่มี Input Parameter (report นี้รันโดยไม่รับ parameter)

---

## Section 3 — Data Source

### 3.1 Tables / Views

| Table / View | Alias | Description |
|--------------|-------|-------------|
| {TABLE_NAME} | {alias} | {คำอธิบาย} |

### 3.2 Stored Procedure / Query

```sql
-- {ชื่อ SP หรือ Query หลัก}
-- {ระบุ parameter ที่ส่งเข้า}
{EXEC SP_NAME @param1, @param2}
```

> ถ้ายังไม่มี SP ให้ระบุ logic การดึงข้อมูลเป็น pseudo-code หรืออธิบาย join condition

### 3.3 Business Rules / Calculation

{ถ้าไม่มีการคำนวณ ระบุว่า N/A}

| # | Rule / Condition | Formula | หมายเหตุ |
|---|-----------------|---------|----------|
| 1 | {ชื่อ rule} | {สูตร หรือ เงื่อนไข} | {หมายเหตุเพิ่มเติม} |

---

## Section 4 — Report Layout

### 4.1 Report Header

{ระบุทุก field ที่แสดงในส่วน Header ของรายงาน}

| Field | แหล่งข้อมูล | Format | ตำแหน่ง | หมายเหตุ |
|-------|------------|--------|---------|----------|
| {ชื่อ field} | {Parameter / Master / Static} | {DD/MM/YYYY / Text} | {Left/Center/Right} | |

### 4.2 Report Body / Detail

{ระบุทุก column ที่แสดงในส่วน body เรียงตามลำดับซ้ายไปขวา}

| # | Column Name (TH) | Column Name (EN) | Source Field | Data Type | Format | Alignment | หมายเหตุ |
|---|-----------------|-----------------|-------------|-----------|--------|-----------|----------|
| 1 | {ชื่อไทย} | {ชื่ออังกฤษ} | {FIELD_NAME} | {VARCHAR/INT/DECIMAL/DATE} | {#,##0.00 / DD/MM/YYYY} | {L/C/R} | {สูตร หรือ เงื่อนไข} |

### 4.3 Grouping / Sorting

{ถ้าไม่มี ระบุว่า N/A}

| ประเภท | Field | Order | หมายเหตุ |
|--------|-------|-------|----------|
| Group by | {FIELD} | {ASC/DESC} | {แสดง subtotal / header ของ group} |
| Sort by | {FIELD} | {ASC/DESC} | |

### 4.4 Subtotal / Summary / Footer

{ถ้าไม่มี ระบุว่า N/A}

| Level | แสดงที่ | Columns ที่รวม | หมายเหตุ |
|-------|---------|---------------|----------|
| {Group Total / Page Total / Grand Total} | {ท้าย group / ท้ายหน้า / ท้ายรายงาน} | {ชื่อ column ที่ SUM/COUNT} | |

---

## Section 5 — Output Specification

| Format | File Naming Convention | Destination Path | หมายเหตุ |
|--------|----------------------|------------------|----------|
| {PDF / Excel / CSV} | {REPORT_NAME_YYYYMMDD.pdf} | {/output/path/} | |

> ถ้าเป็น On-screen ระบุว่า: แสดงผลบนหน้าจอ ไม่มีการ export ไฟล์

---

## Section 6 — Error Handling

| Scenario | Expected Behavior |
|----------|------------------|
| ไม่มีข้อมูลตาม filter ที่ระบุ | แสดงรายงานเปล่าพร้อมข้อความ "No Data Found" |
| Database connection error | Log error, แจ้ง user ด้วย message ที่เข้าใจได้ |
| {Scenario เพิ่มเติมที่เฉพาะกับ report นี้} | |

---

## Section 7 — Non-Functional Requirements

| ด้าน | Requirement |
|------|-------------|
| Performance | ประมวลผลเสร็จภายใน {X} วินาที สำหรับข้อมูลสูงสุด {X} แถว |
| Security | {ตรวจสอบสิทธิ์ผู้ใช้ / จำกัดการเข้าถึงตาม role} |
| Printing | {Paper size: A4/A3 / Orientation: Portrait/Landscape} |
| Encoding | {UTF-8 / TIS-620} |

---

## Section 8 — Pending Items / TBD

{รายการข้อมูลที่ยังไม่ครบ ต้องติดตามเพิ่มเติม}

| # | Section ที่เกี่ยวข้อง | รายการที่รอข้อมูล | ผู้รับผิดชอบ | กำหนด |
|---|----------------------|------------------|-------------|-------|
| 1 | | | | |

> ถ้าข้อมูลครบทุก section แล้ว ให้ระบุว่า: ไม่มี Pending Items

---

## Section 9 — Revision History

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| 1.0 | {วันที่} | {ชื่อ SA} | Initial version |
```

---

## แนวทางการใช้งานสำหรับ SA

### กรณีงานใหม่
1. แจ้ง `/spec_report` พร้อมข้อมูลตาม Checklist ในขั้นตอนที่ 1
2. AI จะ generate TFS ให้ครบทุก section
3. SA review และแก้ไขส่วนที่ต้องปรับ
4. บันทึกเป็นไฟล์ `.md` ส่งผ่านช่องทางของทีม (Aroma / Git)

### กรณีแก้ไขระบบเดิม หรือ Convert Technology
1. แนบ Source Code เดิมหรือ Spec เก่ามาด้วย
2. AI จะ reverse engineer เป็น Spec `.md` ก่อน
3. SA ยืนยัน/แก้ไข แล้วระบุส่วนที่เปลี่ยนแปลง
4. AI อัปเดต Spec ให้ sync กับสิ่งที่ต้องการ

### กรณี Dev Return งาน
1. ระบุส่วนที่ผิด / พฤติกรรมที่ต้องการ
2. AI อัปเดตเฉพาะ Section ที่เกี่ยวข้อง
3. SA review และ approve ก่อนส่งกลับ Dev
4. เพิ่ม entry ใน Section 9 Revision History ทุกครั้ง

---

## Program Sub-type Reference

| Sub-type | ลักษณะ | ตัวอย่าง Report |
|----------|--------|----------------|
| Daily Confirmation | สรุปรายการซื้อขายรายวันต่อบัญชี | Trade Confirmation |
| Portfolio Summary | ภาพรวม Portfolio ของลูกค้า | Portfolio Report |
| WHT Report | รายงานภาษีหัก ณ ที่จ่าย | WHT Certificate |
| Settlement Report | รายงาน Settle รายการ | T+2 Settlement |
| Statement | Statement บัญชีลูกค้า | Monthly Statement |
| Reconcile | รายงานกระทบยอดระหว่างระบบ | Daily Reconcile |
| Summary / Dashboard | รายงานสรุปสำหรับผู้บริหาร | Management Report |
| Regulatory | รายงานส่งหน่วยงานกำกับ | ก.ล.ต. / SET Report |
