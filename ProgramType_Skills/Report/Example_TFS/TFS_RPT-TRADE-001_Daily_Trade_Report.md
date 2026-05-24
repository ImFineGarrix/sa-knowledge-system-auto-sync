# RPT-TRADE-001 — Daily Trade Report
## Technical Functional Specification (TFS)

---

## Report Metadata

| Field             | Detail                                      |
|-------------------|---------------------------------------------|
| Report ID         | RPT-TRADE-001                               |
| Report Name (TH)  | รายงานรายการเทรดประจำวัน                    |
| Report Name (EN)  | Daily Trade Report                          |
| Program Type      | Report                                      |
| Technology        | TBD (ยังไม่ได้กำหนด)                       |
| Output Format     | Excel (.xlsx)                               |
| Version           | 1.0                                         |
| Prepared by       | -                                           |
| Date              | 2025-05-05                                  |

---

## Section 1 — Overview

รายงานนี้ใช้สำหรับแสดงรายการซื้อขายหลักทรัพย์ (Trade) ทั้งหมดในแต่ละวันทำการ  
ผู้ใช้งานหลักคือ **Back Office / เจ้าหน้าที่** ใช้เพื่อติดตาม ตรวจสอบ และสรุปรายการเทรดของลูกค้าในแต่ละวัน  
รองรับทั้งการเรียกดูแบบ On-demand และการสร้างอัตโนมัติแบบ Daily Batch

---

## Section 2 — Input Parameters / Filters

| Parameter    | Type     | Required | Description              | Default       |
|--------------|----------|----------|--------------------------|---------------|
| trade_date   | DATE     | Y        | วันที่ทำรายการ (Trade Date) | วันปัจจุบัน    |
| account_no   | VARCHAR  | N        | รหัสบัญชีลูกค้า           | ALL (ทุกบัญชี) |
| side         | VARCHAR  | N        | ด้านการซื้อขาย BUY / SELL | ALL           |

> **หมายเหตุ:** ถ้า account_no = ALL ให้แสดงรายการของทุกบัญชีในวันที่เลือก

---

## Section 3 — Data Source

### 3.1 Tables / Views

| Table / View       | Alias | Description                              |
|--------------------|-------|------------------------------------------|
| T_TRADE            | t     | ข้อมูลรายการซื้อขายหลักทรัพย์ประจำวัน    |
| T_ACCOUNT          | a     | ข้อมูล Master บัญชีลูกค้า               |
| T_STOCK            | s     | ข้อมูล Master หลักทรัพย์                 |

### 3.2 Stored Procedure / Query (Draft Reference)

```sql
SELECT
    t.TRADE_DATE,
    t.ACCOUNT_NO,
    a.ACCOUNT_NAME,
    t.STOCK_CODE,
    s.STOCK_NAME,
    t.SIDE,
    t.VOLUME,
    t.PRICE,
    t.GROSS_AMOUNT,
    t.COMMISSION,
    t.TRADING_FEE,
    t.CLEARING_FEE,
    t.VAT,
    t.TOTAL_AMOUNT,
    t.WHT,
    t.NET_AMOUNT
FROM T_TRADE t
JOIN T_ACCOUNT a ON t.ACCOUNT_NO = a.ACCOUNT_NO
JOIN T_STOCK   s ON t.STOCK_CODE = s.STOCK_CODE
WHERE t.TRADE_DATE = @trade_date
  AND (@account_no IS NULL OR t.ACCOUNT_NO = @account_no)
  AND (@side       IS NULL OR t.SIDE       = @side)
ORDER BY t.ACCOUNT_NO, t.SIDE DESC, t.STOCK_CODE
```

> *SP / View จริงให้ Dev ปรับตามมาตรฐาน Naming ของโปรเจกต์*

### 3.3 Business Rules / Calculation

**กรณี SIDE = BUY**

| # | สูตร                                                                 | คำอธิบาย                            |
|---|----------------------------------------------------------------------|-------------------------------------|
| 1 | `Gross Amount = Volume × Price`                                      | มูลค่าซื้อขายก่อนรวมค่าธรรมเนียม   |
| 2 | `Total Amount = Gross Amount + Commission + Trading Fee + Clearing Fee` | รวมค่าธรรมเนียมทั้งหมด            |
| 3 | `Net Amount = Total Amount − WHT`                                    | หัก WHT ออก                         |

**กรณี SIDE = SELL**

| # | สูตร                                                                 | คำอธิบาย                            |
|---|----------------------------------------------------------------------|-------------------------------------|
| 1 | `Gross Amount = Volume × Price`                                      | มูลค่าซื้อขายก่อนหักค่าธรรมเนียม   |
| 2 | `Total Amount = Gross Amount − Commission − Trading Fee − Clearing Fee` | หักค่าธรรมเนียมออก               |
| 3 | `Net Amount = Total Amount + WHT`                                    | บวก WHT คืน                         |

> **VAT** คำนวณจาก Commission × อัตรา VAT (กำหนดตามบริษัท)

---

## Section 4 — Report Layout

### 4.1 Report Header

| Field           | Source / Format                            | Remark              |
|-----------------|--------------------------------------------|---------------------|
| ชื่อรายงาน      | "รายงานรายการเทรดประจำวัน"                  | แสดงด้านบนกลาง      |
| Trade Date      | จาก Parameter `trade_date`                 | Format: DD/MM/YYYY  |
| Account No      | จาก Parameter / Session                    | แสดง "ALL" ถ้าไม่กรอง |
| Account Name    | ดึงจาก T_ACCOUNT ตาม account_no            |                     |
| วันที่พิมพ์      | วันที่ระบบ (SYSDATE)                        | Format: DD/MM/YYYY HH:mm |
| Page            | Page X of Y                                | แสดงมุมขวาบน        |

### 4.2 Report Detail / Body

| Column Name (TH)      | Source Field    | Format       | Alignment | Remark                    |
|-----------------------|-----------------|--------------|-----------|---------------------------|
| บัญชี                 | ACCOUNT_NO      |              | Left      | แสดงครั้งแรกของกลุ่ม      |
| ชื่อบัญชี             | ACCOUNT_NAME    |              | Left      | แสดงครั้งแรกของกลุ่ม      |
| วันที่เทรด            | TRADE_DATE      | DD/MM/YYYY   | Center    |                           |
| รหัสหลักทรัพย์        | STOCK_CODE      |              | Left      |                           |
| ชื่อหลักทรัพย์        | STOCK_NAME      |              | Left      |                           |
| ด้าน                  | SIDE            |              | Center    | BUY / SELL                |
| จำนวน (หุ้น)          | VOLUME          | #,##0        | Right     |                           |
| ราคา                  | PRICE           | #,##0.0000   | Right     |                           |
| มูลค่า                | GROSS_AMOUNT    | #,##0.00     | Right     | Volume × Price            |
| ค่านายหน้า            | COMMISSION      | #,##0.00     | Right     |                           |
| ค่าธรรมเนียมซื้อขาย   | TRADING_FEE     | #,##0.00     | Right     |                           |
| ค่าธรรมเนียม Clearing | CLEARING_FEE    | #,##0.00     | Right     |                           |
| VAT                   | VAT             | #,##0.00     | Right     | คำนวณจาก Commission        |
| มูลค่ารวม             | TOTAL_AMOUNT    | #,##0.00     | Right     | ตามสูตร BUY / SELL        |
| ภาษีหัก ณ ที่จ่าย     | WHT             | #,##0.00     | Right     |                           |
| มูลค่าสุทธิ           | NET_AMOUNT      | #,##0.00     | Right     | ตามสูตร BUY / SELL        |

### 4.3 Grouping / Sorting

| ประเภท   | Field      | Order              | Remark                              |
|----------|------------|--------------------|-------------------------------------|
| Group by | ACCOUNT_NO |                    | แสดง subtotal ต่อบัญชี              |
| Group by | SIDE       | SELL ก่อน, BUY ทีหลัง | แสดง subtotal แต่ละ side ในบัญชี  |
| Sort by  | STOCK_CODE | ASC                |                                     |

### 4.4 Subtotal / Summary

| Level              | รายละเอียดที่แสดง                                                       |
|--------------------|-------------------------------------------------------------------------|
| Group Total — SELL | รวม Gross Amount, Total Amount, WHT, Net Amount ของรายการ SELL ต่อบัญชี |
| Group Total — BUY  | รวม Gross Amount, Total Amount, WHT, Net Amount ของรายการ BUY ต่อบัญชี  |
| Account Total      | รวมทุกรายการของแต่ละบัญชี                                               |
| Grand Total        | รวมทั้งหมดทุกบัญชี แสดงท้ายรายงาน                                       |

---

## Section 5 — Output Specification

| Format       | File Naming                    | Destination          | Remark                                   |
|--------------|--------------------------------|----------------------|------------------------------------------|
| Excel (.xlsx)| DAILY_TRADE_YYYYMMDD.xlsx      | /output/daily-trade/ | Freeze header row, Auto-filter, ภาษาไทย |

> **Excel Spec เพิ่มเติม:**
> - Header row: สีพื้นหลัง `#1F4E79` (ฟ้าเข้ม), ตัวอักษรสีขาว, Bold
> - Subtotal row: สีพื้นหลัง `#D9E1F2` (ฟ้าอ่อน), Bold
> - Grand Total row: สีพื้นหลัง `#BDD7EE`, Bold
> - ล็อก (Freeze) แถว Header ไว้
> - เปิด Auto-filter ที่แถว Header
> - Encoding: UTF-8 (รองรับภาษาไทย)
> - Sheet name: "Daily Trade"

---

## Section 6 — Trigger / Schedule

| Mode         | รายละเอียด                                                    |
|--------------|---------------------------------------------------------------|
| On-demand    | เจ้าหน้าที่เลือก trade_date และ filter แล้วกด Generate       |
| Daily Batch  | รันอัตโนมัติหลังปิดตลาด (เวลา TBD) สำหรับวันทำการปัจจุบัน   |

---

## Section 7 — Error Handling

| Scenario                             | Behavior                                             |
|--------------------------------------|------------------------------------------------------|
| ไม่มีข้อมูลในวันที่ที่ระบุ            | สร้างไฟล์ Excel พร้อมข้อความ "ไม่พบข้อมูล" ในแถวแรก |
| Account No ที่ระบุไม่มีในระบบ         | แสดง Error Message: "ไม่พบรหัสบัญชีที่ระบุ"          |
| Connection error / Database timeout  | Log error และแจ้ง User พร้อม Error Code              |
| Daily Batch ล้มเหลว                  | ส่ง Alert Email แจ้งทีม Back Office                  |

---

## Section 8 — Non-Functional Requirements

- **Performance:** ประมวลผลข้อมูลสูงสุด 10,000 รายการต่อวัน ให้แล้วเสร็จภายใน 30 วินาที
- **Security:** ตรวจสอบสิทธิ์ผู้ใช้ก่อน Generate (เฉพาะ Back Office เท่านั้น)
- **Encoding:** UTF-8 รองรับภาษาไทยทุก Column

---

## Section 9 — Revision History

| Version | Date       | Author | Description     |
|---------|------------|--------|-----------------|
| 1.0     | 2025-05-05 | -      | Initial version |
