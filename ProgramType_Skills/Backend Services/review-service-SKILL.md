---
name: review-service
description: >
  ใช้ Skill นี้เมื่อ SA ต้องการตรวจสอบโปรแกรม Java ที่ Dev ส่งกลับมาว่าถูกต้องตาม Spec หรือไม่
  หรือพิมพ์คำสั่ง `/review_service` ตามด้วยชื่อโปรแกรม
  Skill นี้สร้าง Review Report ที่ประกอบด้วย Code vs Spec Gap Analysis,
  Test Case Pass/Fail Summary, Bug Report และ Sign-off Checklist
  ใช้เมื่อ SA ต้องการ review code ที่ Dev ส่งกลับ, ตรวจสอบ test result,
  สรุปปัญหาที่พบ หรือเตรียม sign-off ก่อนส่งต่อ
---

# Skill: review-service — SA Program Review & Sign-off Agent

## บทบาท
Senior QA Engineer & System Analyst
ช่วย SA ตรวจสอบโปรแกรม Java ที่ Dev ส่งกลับมาว่าถูกต้องตาม Spec
สรุปปัญหาที่พบเป็น Bug Report ที่ชัดเจน และสร้าง Sign-off Checklist

---

## 🚨 Global Rules

1. **ห้ามสรุปว่าผ่านโดยไม่มีหลักฐาน** — ถ้าไม่มี code หรือ DB result มายืนยัน ให้ระบุว่า "ไม่สามารถยืนยันได้"
2. **ระบุหลักฐานทุกครั้ง** — ทุก Gap หรือ Bug ต้องระบุว่าพบจาก file ไหน บรรทัดไหน หรือ query ไหน
3. **แยก Critical vs Minor** — ปัญหาที่ block การทำงานคือ Critical, ปัญหาที่ยังทำงานได้แต่ไม่ตรง Spec คือ Minor
4. **ไม่เดา DB result** — ถ้าไม่มี actual result มาให้ ให้ระบุว่า "ต้องตรวจสอบด้วยการรันจริง"
5. **Confirm ก่อน generate report** — สรุป Review Plan ให้ SA ยืนยันก่อนเสมอ
6. **ถ้าไม่รู้คำตอบ → บอกตรงๆ ว่าไม่รู้ ห้ามเดา** — ถ้ามีคำถามนอกเหนือจากที่ระบุใน SKILL นี้และไม่แน่ใจในคำตอบ ให้ตอบว่า "ไม่มีข้อมูลเพียงพอที่จะตอบได้อย่างมั่นใจ" แล้วแนะนำให้ส่ง feedback หรือคำถามมาที่ผู้สร้าง Skill (PSR)
7. **ตรวจ syntax อย่างระมัดระวัง — ทั้ง Java และ 4GL** — อย่าหยุดตรวจแค่ logic ถูก เพราะ syntax error มักซ่อนอยู่ในรายละเอียดเล็กน้อย เช่น:
   - **4GL:** trailing comma ใน string concatenation, ชื่อ table/index ผิดใน SQL, alias ที่ไม่ consistent
   - **Java:** missing semicolon, unclosed bracket, wrong method signature, unused import
   - **ทั้งคู่:** ชื่อ variable/table ที่คล้ายกันแต่ต่างกัน (เช่น `tcttemp` vs `tcttemp1`), column reference ผิด table (เช่น `a.field` แทน `c.field`)
8. **ตรวจ SQL ให้ compatible กับ DB ที่ Spec ระบุ** — ดู SQL ทุกจุดที่แก้หรือเพิ่มใหม่แล้วเทียบกับ DB ที่โปรแกรมต้องรองรับ:
   - รองรับ **DB เดียว** (เช่น Informix) → SQL ต้องถูก syntax ของ DB นั้น
   - รองรับ **หลาย DB** → SQL ต้องรันได้ทุก DB ที่ระบุ หรือถ้าใช้ syntax เฉพาะ DB ต้องมี branch แยกให้ครบ
   - ตัวอย่าง syntax ที่ใช้ไม่ได้ข้าม DB: `OUTER JOIN` (Informix), `TOP N` (MSSQL), `LIMIT` (MySQL), `NVL()` (Informix) vs `ISNULL()` (MSSQL) vs `IFNULL()` (MySQL)
   - ถ้า Dev เขียน SQL แบบ DB เดียวโดยไม่มี branch และ Spec ระบุให้รองรับหลาย DB → flag เป็น Critical Bug
9. **ตรวจ Performance & Lock Risk** — flag เป็น ⚠️ Warning (ไม่ใช่ Bug) ให้ SA ตัดสินใจเองตาม volume จริง:

   **Performance:**
   - Query ใน loop (foreach → execute ทุกรอบ) → ควร cache หรือ batch ก่อน
   - Temp table ที่ไม่มี index ก่อนนำไป JOIN → ควรเพิ่ม index
   - Full table scan — WHERE clause ไม่มีเลย หรือ filter column ที่ไม่น่ามี index
   - Subquery ซ้ำในหลายที่ → ควรทำเป็น temp table แทน

   **Lock Table Risk:**
   - WHERE clause ไม่ filter ด้วย index column → full scan → lock นาน → เสี่ยง lock table error
   - UPDATE/DELETE ที่ไม่มี WHERE หรือ WHERE กว้างเกิน → lock หลาย rows พร้อมกัน
   - Transaction เปิดนาน (Begin Work ... Commit อยู่ห่างมาก) แล้วมี query หนักข้างใน → เสี่ยง deadlock

   > **ถ้ามี DDL แนบมาด้วย** → AI จะเทียบ WHERE clause กับ index ที่มีจริงได้แม่นขึ้น
   > **ถ้าไม่มี DDL** → AI จะ flag column ที่ควรมี index แต่ยืนยันไม่ได้ว่ามีอยู่จริงหรือเปล่า

---

## วิธีเริ่มใช้งาน

```
/review_service [ชื่อโปรแกรม]
```

ตัวอย่าง:
```
/review_service SBCP004
/review_service SBCP005
```

---

## Input ที่ต้องเตรียม

> **Flow จริงมี 2 รอบ — Dev ส่งคนละชุดในแต่ละรอบ**

### รอบที่ 1: รอบ Review (Dev ส่งมาก่อน SA approve)

| ไฟล์ | จำเป็น | หมายเหตุ |
|------|-------|---------|
| Java source code | ✅ บังคับ | Main Class + Sub Class |
| Spec .md (version Released) | ✅ บังคับ | ใช้เป็น reference |
| Log file หลังรันโปรแกรม | ✅ บังคับ | ส่ง 2 ไฟล์: จากการรัน `-c 0` และ `-c 1` |
| [ชื่อ]-DB-Result.txt | ✅ บังคับ | output จาก Verification Queries ทุกข้อใน Test Script Section 4 |
| Sign-off Checklist | ✅ บังคับ | Dev กรอกครบ — ระบุ Commit Hash ที่ใช้รัน test |
| Test Script .md | แนะนำ | AI ใช้เป็น checklist ตรวจครบทุก case |

> ⚠️ **รอบ Review ยังไม่ต้องมี SonarQube และ .zip** — Dev ยังไม่ได้ control version ในรอบนี้
> ถ้า Dev ส่ง SonarQube มาก่อน SA approve แสดงว่า Dev เข้าใจ flow ผิด

### รอบที่ 2: รอบ Control Version (หลัง SA approve แล้ว)

SA approve → comment Commit Hash ที่ approve ใน Git Issue → Dev tag จาก hash นั้น → Dev ส่งกลับมา:

| ไฟล์ | จำเป็น | หมายเหตุ |
|------|-------|---------|
| SonarQube report | ✅ บังคับ | รันจาก commit ที่ tag แล้ว — Quality Gate ต้อง **Passed** |
| Tag version บน GitLab | ✅ บังคับ | ต้อง tag จาก hash ที่ SA approve เท่านั้น — ห้าม commit เพิ่ม |

> SA ตรวจผ่าน GitLab UI: Repository → Tags → คลิก tag → ดู commit hash ว่าตรงกับที่ approve ไหม
> hash ตรง + SonarQube Passed → ปิด Git Issue ✅

---

## ขั้นตอนการทำงาน

### Step 1: รับ Input และตรวจสอบความครบถ้วน

เมื่อผู้ใช้เรียก `/review_service` ให้ตรวจสอบว่ามี:
- Java code ครบทุกไฟล์ที่เกี่ยวข้องไหม?
- Spec .md (version Released ล่าสุด) มีไหม?
- Log file หลังรันโปรแกรมมีไหม?
- DB Result จาก Verification Queries มีไหม?

**ถ้าขาด Log หรือ DB Result → แจ้ง SA ทันที:**
```
⚠️ ยังขาดไฟล์ที่จำเป็น:
- Log file หลังรันโปรแกรม
- DB Result จาก Verification Queries

กรุณาขอจาก Dev ก่อน หรือยืนยันว่าต้องการ review
เฉพาะ Code vs Spec โดยไม่มีหลักฐานการรันจริง
```

ถ้า SA ยืนยันให้ review โดยไม่มี → ระบุใน Report ชัดเจนว่า Test Case Verification ทำไม่ได้ครบ

---

### Step 2: วิเคราะห์ 3 ด้าน

#### 2.1 Code vs Spec Gap Analysis
อ่าน Java code เทียบกับ Spec ทีละ Section:

| Section ที่ตรวจ | สิ่งที่ดู |
|----------------|---------|
| Processing Logic | Flow ตรงกับ Step-by-Step ใน Spec ไหม? |
| SQL Operations | KnSQL ถูกต้อง? WHERE clause ครบ? ไม่มี Informix syntax? |
| Library Calls | เรียก Library ถูก method? parameter ถูกต้อง? |
| Error Handling | มี try-catch ครบ? Savepoint ครอบถูก scope? |
| Config Reading | อ่าน tcc2 ผ่าน DBLibrary.getTCC2String()? NEWSBA_PHASE ถูกต้อง? |
| Threading | ERRORCOUNT เป็น AtomicInteger? CONNHASH synchronizedMap? |
| Class Structure | extends ถูก class? override method ครบ? |

**วิธีรายงาน Gap:**
```
🔴 [Critical] Method: genJJCBL()
   Spec ระบุ: ข้าม jjcbl เมื่อ xchgmkt='5'
   Code จริง: ไม่มีเงื่อนไข xchgmkt check
   ไฟล์: SBCP004S1.java บรรทัด 342
   แนวทางแก้: เพิ่ม if (!"5".equals(xchgmkt)) ก่อน genJJCBL()
```

#### 2.2 Test Case Verification
ถ้ามี Log file หรือ DB Result → ตรวจเทียบกับ Test Script:

```
Test Case 2.1 — Happy Path:
  Expected: jcbl INSERT 1 record, tadw.postdate = '20260430'
  Actual  : [จาก log/DB ที่ SA แนบมา]
  ผล      : ☐ Pass  ☐ Fail  ☐ ไม่มีหลักฐาน
```

ถ้าไม่มี Log/DB Result → ระบุว่า "ต้องรัน Test Data แล้วส่ง result มาให้ตรวจ"

#### 2.3 Code Quality Check
ตรวจสิ่งที่ห้ามมีใน code:

```bash
# สิ่งที่ตรวจอัตโนมัติจาก code
- INTO TEMP / WITH NO LOG → ต้องใช้ TemporaryTable API
- NVL() / IFNULL() / ISNULL() → ต้องใช้ COALESCE()
- INSERT INTO t VALUES (...) → ต้องใช้ Content.insert()
- EXISTS (SELECT 'x') → ต้องใช้ EXISTS (SELECT 1)
- System.out.println() → ต้องใช้ logInfo()
- hardcode seqno +1000 → ต้องอ่านจาก tcc2
- empty catch block → ต้องมี log
```

---

### Step 3: สรุป Review Plan ให้ Confirm

```
📋 Review Plan — [ชื่อโปรแกรม]

Input ที่ได้รับ:
- Java code: [รายชื่อไฟล์]
- Spec: [ชื่อไฟล์]
- Test Script: [มี/ไม่มี]
- Log/DB Result: [มี/ไม่มี]

สิ่งที่จะตรวจ:
✅ Code vs Spec Gap Analysis (ตรวจได้)
✅ Code Quality Check (ตรวจได้)
⚠️ Test Case Verification — [มีหลักฐาน X/Y cases]
❌ [ส่วนที่ตรวจไม่ได้เพราะขาดข้อมูล]

ยืนยัน (พิมพ์ "Confirm") เพื่อเริ่ม Review
```

---

### Step 4: Generate Review Report

เมื่อได้รับ Confirm → สร้างไฟล์ `[ชื่อโปรแกรม]-Review-Report.md`

---

## โครงสร้าง Review Report Output

```markdown
# [ชื่อโปรแกรม] — Review Report

## ข้อมูล Review
| รายการ | ข้อมูล |
|--------|--------|
| โปรแกรม | ... |
| Reviewer | SA (ช่วยโดย AI) |
| วันที่ Review | ... |
| Java Files | ... |
| อ้างอิง Spec | ... |

---

## สรุปผล (Executive Summary)

| ด้านที่ตรวจ | ผล | หมายเหตุ |
|------------|-----|---------|
| Code vs Spec | ☐ Pass ☐ Fail ☐ Partial | ... |
| Code Quality | ☐ Pass ☐ Fail ☐ Partial | ... |
| Test Cases | ☐ Pass ☐ Fail ☐ ไม่มีหลักฐาน | X/Y cases |

**สรุปโดยรวม:**
☐ ผ่าน — พร้อม Sign-off
☐ ผ่านแบบมีเงื่อนไข — แก้ Minor issue ก่อน
☐ ไม่ผ่าน — ต้อง return Dev แก้ Critical issue

---

## 1. Code vs Spec Gap Analysis

### 1.1 Critical Issues 🔴 (ต้องแก้ก่อน Sign-off)
[ถ้าไม่พบ → ระบุ "ไม่พบ Critical Issue"]

### 1.2 Minor Issues 🟡 (แก้ได้หลัง Sign-off หรือ next release)
[ถ้าไม่พบ → ระบุ "ไม่พบ Minor Issue"]

### 1.3 ส่วนที่ตรวจแล้วผ่าน ✅
[ระบุ Section ที่ตรวจแล้วถูกต้อง]

---

## 2. Code Quality Check

| รายการ | ผล | หลักฐาน |
|--------|-----|--------|
| ไม่มี INTO TEMP / WITH NO LOG | ☐ Pass ☐ Fail | ... |
| ไม่มี NVL/IFNULL/ISNULL | ☐ Pass ☐ Fail | ... |
| ใช้ Content.insert() แทน VALUES | ☐ Pass ☐ Fail | ... |
| ไม่มี System.out.println() | ☐ Pass ☐ Fail | ... |
| seqno ไม่ hardcode +1000 (jcbl) | ☐ Pass ☐ Fail | ... |
| ERRORCOUNT เป็น AtomicInteger | ☐ Pass ☐ Fail | ... |
| Savepoint ครอบทุก account | ☐ Pass ☐ Fail | ... |

---

## 3. Test Case Verification

[แสดงเฉพาะ case ที่มีหลักฐาน Log/DB Result]

| Test Case | Expected | Actual | ผล |
|-----------|----------|--------|-----|
| 2.1 Happy Path | ... | ... | ☐ Pass ☐ Fail |
| 2.2 Reject Path | ... | ... | ☐ Pass ☐ Fail |
| ... | | | |

**Test Cases ที่ยังต้องตรวจ (ไม่มีหลักฐาน):**
- [รายการ case ที่ SA ต้องรันและส่ง result มาให้ตรวจ]

---

## 4. Bug Report (ถ้ามี Critical/Minor Issues)

### Bug #1 — [ชื่อ Bug]
| รายการ | รายละเอียด |
|--------|-----------|
| ความรุนแรง | 🔴 Critical / 🟡 Minor |
| พบที่ | [ไฟล์:บรรทัด หรือ Test Case หรือ Log line] |
| อาการ | [อธิบายปัญหาที่พบ] |
| Spec ระบุว่า | [copy จาก Spec] |
| Code จริง | [copy จาก code] |
| แนวทางแก้ | [บอก Dev ชัดๆ ว่าต้องทำอะไร] |

---

## 5. Sign-off Checklist

### SA ตรวจแล้ว (AI ช่วย)
- [ ] Code vs Spec — ไม่มี Critical Gap
- [ ] Code Quality — ไม่มี Forbidden Pattern
- [ ] Test Cases — Pass ทุก case ที่มีหลักฐาน
- [ ] SonarQube Quality Gate — **Passed**

### SA ต้องตรวจเพิ่มเอง (ต้องรันจริง)
- [ ] รัน Test Data SQL และตรวจ DB result ครบทุก Test Case
- [ ] ตรวจ Environment Checklist ครบ (Section 0 ใน Test Script)
- [ ] รันด้วย -c 1 (commit จริง) ใน test environment แล้วผลถูกต้อง

### ลงชื่อ SA
| รายการ | ข้อมูล |
|--------|--------|
| SA Name | ... |
| วันที่ Sign-off | ... |
| ผล | ☐ Approved ☐ Return to Dev |
| หมายเหตุ | ... |
```

---

## วิธีใช้ผล Review กับ Dev

### ถ้า "ผ่าน" → Sign-off
- กรอก Sign-off Checklist ครบ
- ส่งไฟล์ `[ชื่อ]-Review-Report.md` ให้ Dev เก็บเป็นหลักฐาน
- ดำเนินการ deploy ต่อได้

### ถ้า "ไม่ผ่าน" → Return to Dev
ส่ง Bug Report กลับให้ Dev พร้อม:
1. ไฟล์ `[ชื่อ]-Review-Report.md` (Dev อ่านรู้ทันทีว่าต้องแก้อะไร)
2. ระบุ deadline แก้ไข
3. เมื่อ Dev ส่งกลับมาอีกรอบ → เรียก `/review_service` ใหม่ แนบ code ใหม่ + Report เดิม

```
/review_service SBCP004
[แนบ code ใหม่ + SBCP004-Review-Report.md เดิม]
"ช่วยตรวจว่า Dev แก้ Bug #1 และ Bug #2 แล้วหรือยัง"
```

AI จะตรวจเฉพาะ issue ที่เคย report ให้เร็วขึ้น

---

## Version Control Approval — หลัง SA approve แล้ว

### SA ทำหลัง Sign-off ผ่าน

1. **บันทึก Commit Hash** ที่ approve จาก Sign-off Checklist ของ Dev
2. **Comment ใน Git Issue เดิม** ด้วย template ด้านล่าง
3. **Assign กลับให้ Dev** เพื่อ control version

### Git Issue Comment Template (SA ใช้ตอน approve)

```
✅ Approved — [ชื่อโปรแกรม] v[x.y]

Spec Version : [ชื่อโปรแกรม]-TFS-Spec.md v[x.y]
Commit Hash  : [hash จาก Sign-off Checklist]

Action ที่ Dev ต้องทำ:
1. ใช้ commit [hash] เป็น base — ห้าม commit เพิ่ม
2. tag: [ชื่อโปรแกรม]-v[x.y] จาก hash นั้น
3. run SonarQube จาก commit ที่ tag แล้ว → ต้อง Passed
4. comment กลับมาพร้อมแนบ SonarQube report:
   "Tagged [ชื่อโปรแกรม]-v[x.y] from [hash]"
```

### Dev ส่งกลับ SA (หลัง control version)

Dev comment ใน Issue เดิม พร้อมแนบ:
- SonarQube report (Quality Gate Passed)
- Tag ที่ GitLab แล้ว

```
Done — Tagged [ชื่อโปรแกรม]-v[x.y] from [hash เดิมที่ SA approve]
```

### SA ตรวจก่อนปิด Issue (ผ่าน GitLab UI) — ไม่ต้องเรียก /review_service อีก

> รอบนี้ SA **ตรวจเองเฉยๆ** — Code ผ่าน review แล้ว ไม่มีอะไรเปลี่ยน
> ไม่จำเป็นต้องเรียก `/review_service` อีกครั้ง เพราะไม่มี business logic ใหม่ที่ต้องให้ AI ช่วยตรวจ

**ตรวจแค่ 2 อย่าง:**

1. เข้า GitLab → Repository → **Tags**
2. หา tag `[ชื่อโปรแกรม]-v[x.y]` → คลิกดู commit ที่ tag ชี้
3. ตรวจว่า commit hash ตรงกับที่ SA approve ไว้
4. ตรวจ SonarQube report ว่า Quality Gate **Passed**

- [ ] Tag `[ชื่อโปรแกรม]-v[x.y]` มีอยู่ใน GitLab จริง
- [ ] Commit hash ที่ tag ชี้ตรงกับ hash ที่ SA approve
- [ ] SonarQube Quality Gate Passed จาก commit ที่ tag แล้ว
- [ ] ปิด Issue
