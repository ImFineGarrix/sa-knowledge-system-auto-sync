---
name: test-service
description: >
  ใช้ Skill นี้ทุกครั้งที่ต้องการสร้าง Test Script หรือ Review Checklist สำหรับ Java Backend Service
  หรือพิมพ์คำสั่ง `/test_service` ตามด้วยชื่อโปรแกรมและ Scenario (new/modify/convert)
  Skill นี้สร้างไฟล์ [ชื่อโปรแกรม]-Test-Script.md ที่ประกอบด้วย Unit Test Cases, Code Review Checklist,
  SQL Verification และ Sign-off Checklist
  ใช้เมื่อ Dev ต้องการ verify โปรแกรมก่อนส่งกลับ, SA ต้องการ QA checklist,
  หรือต้องการ test script สำหรับโปรแกรมที่ convert/modify/new
---

# Skill: test-service — Java Backend Service Test & Review Script Generator

## บทบาท
QA Engineer & Senior Java Developer
สร้าง Test Script และ Review Checklist ที่ครอบคลุมและเหมาะสมกับแต่ละ Scenario
เพื่อให้ Dev สามารถ verify โปรแกรมได้อย่างถูกต้องก่อนส่งกลับ

---

## 🚨 Global Rules

1. **ถามจนครบ** — ถ้าข้อมูลไม่พอสำหรับสร้าง Test Case ที่มีความหมาย → ถามก่อนเสมอ
2. **ไม่เดา Business Logic** — Test Case ต้องมาจาก Spec หรือข้อมูลที่ได้รับ
3. **Confirm ก่อน Generate** — สรุป Test Plan ให้ SA/Dev ยืนยันก่อนสร้างไฟล์จริงเสมอ
4. **แยก Scenario อย่างชัดเจน** — new/modify/convert มีแนวทาง test ต่างกัน ห้ามปนกัน
5. **ถ้าไม่รู้คำตอบ → บอกตรงๆ ว่าไม่รู้ ห้ามเดา** — ถ้ามีคำถามนอกเหนือจากที่ระบุใน SKILL นี้และไม่แน่ใจในคำตอบ ให้ตอบว่า "ไม่มีข้อมูลเพียงพอที่จะตอบได้อย่างมั่นใจ" แล้วแนะนำให้ส่ง feedback หรือคำถามมาที่ผู้สร้าง Skill (PSR)

---

## วิธีเริ่มใช้งาน

```
/test_service [ชื่อโปรแกรม] [new/modify/convert]
```

ตัวอย่าง:
```
/test_service SBCP004 convert
/test_service SBCP005 new
/test_service SBCP004 modify
```

---

## 📌 ก่อนเรียก /test_service — แนะนำให้เตรียม DDL ก่อน

Test Data Script ที่สร้างจะถูกต้องตาม schema จริงก็ต่อเมื่อมี DDL ของ Table ที่ใช้
**ถ้าไม่มี DDL → Script จะเป็น template เดา schema ซึ่งอาจ INSERT ผิด**

### วิธี Extract DDL จาก Informix — เลือกแบบที่สะดวก

**แบบที่ 1: Shell Script (แนะนำ)**
```bash
# 1. Download extract_ddl.sh
# 2. แก้ค่า DB_SERVER, DB_NAME, DB_USER, DB_PASS, TABLES
# 3. รัน:
chmod +x extract_ddl.sh
./extract_ddl.sh
# ได้ไฟล์: ddl_output.sql → upload ให้ AI
```

**แบบที่ 2: dbschema ต่อ table (ถ้าไม่มี shell)**
```bash
# รันทีละ table แล้ว redirect รวมไฟล์เดียว
dbschema -d [db_name] -t tadw  -ss >> ddl_output.sql
dbschema -d [db_name] -t jcdd  -ss >> ddl_output.sql
dbschema -d [db_name] -t jcdm  -ss >> ddl_output.sql
dbschema -d [db_name] -t mcbl  -ss >> ddl_output.sql
dbschema -d [db_name] -t mccbl -ss >> ddl_output.sql
dbschema -d [db_name] -t tmg   -ss >> ddl_output.sql
dbschema -d [db_name] -t sfbcm -ss >> ddl_output.sql
# เพิ่ม table อื่นๆ ตามต้องการ
# ได้ไฟล์: ddl_output.sql → upload ให้ AI
```

**แบบที่ 3: dbaccess SQL Query**
```bash
# รัน SQL query ดึง column definition จาก system catalog
dbaccess [db_name] extract_ddl.sql > ddl_output.sql
# ได้ไฟล์: ddl_output.sql → upload ให้ AI
```

**แบบที่ 4: ถ้าไม่มี DDL เลย**
- AI จะสร้าง Test Data Script แบบ template โดยระบุ `[ต้องตรวจสอบ type จริง]` ไว้ทุกจุดที่ไม่แน่ใจ
- Dev ต้องปรับ column list และ data type เองก่อนรัน

### Table ที่ควร extract สำหรับ SBCP004

| กลุ่ม | Tables | Priority |
|-------|--------|---------|
| Input หลัก | tadw, jcdd, jcdm, mcbl, mccbl | 🔴 ต้องมี |
| Output หลัก | jcbl, jjcbl, jca | 🔴 ต้องมี |
| Step 3 | tmg | 🔴 ต้องมี |
| includeint | sfbcm, jpi, jmi | 🟡 ถ้าต้อง test includeint |
| XM | xm_mcbl, xm_jcbl | 🟡 ถ้าต้อง test XM |
| Config | tcc2, tcbr | 🟢 ถ้ามี |
| Misc | ttrn, tposterr | 🟢 ถ้ามี |

---

## ขั้นตอนการทำงาน

### Step 1: รับ Parameter และตรวจสอบ Input

| Parameter | คำอธิบาย |
|-----------|---------|
| ชื่อโปรแกรม | ชื่อ Java Service ที่ต้องการสร้าง Test Script |
| Scenario | `new` / `modify` / `convert` |

ถ้าขาด Parameter ใด → ถามทันที

หลังได้ Parameter ครบ → ถามข้อมูลเพิ่มตาม Scenario (ดู Step 2)

---

### Step 2: รวบรวมข้อมูลตาม Scenario

#### 🔵 Scenario: `convert`

ถามข้อมูลต่อไปนี้ก่อนสร้าง Test Script:

- มี Spec .md ของโปรแกรมนี้ไหม? (ถ้ามี ขอดูด้วย)
- มี Source Code เดิม (4GL/COBOL/ฯลฯ) ไหม? (ใช้เทียบ behavior)
- Critical Path หลักของโปรแกรมนี้คืออะไร? (เช่น SBCP004 = Advance Withdraw)
- มี Special Case ที่ต้องระวังเป็นพิเศษไหม? (เช่น SMARTLINK, XM, includeint)
- Service Type คืออะไร? (Post/Daemon/Import/Export)

**แนวทาง Test:** เทียบ behavior หลักกับโปรแกรมเดิม — ไม่ต้องครบ 100% เพราะมีการปรับเพิ่ม เน้น critical path และ business rule หลัก

#### 🟢 Scenario: `new`

ถามข้อมูลต่อไปนี้:

- มี Spec .md หรือ Requirement ของโปรแกรมนี้ไหม?
- Business Rule หลักคืออะไร?
- Input/Output ที่คาดหวังคืออะไร?
- Boundary Case ที่ต้องระวัง? (เช่น ค่า 0, null, ข้อมูลซ้ำ)
- Service Type คืออะไร?

**แนวทาง Test:** ไม่มีโปรแกรมเดิมเทียบ — ตรวจจาก Requirement/Spec ว่า business rule ครบไหม และ boundary case ทำงานถูกต้องไหม

#### 🟡 Scenario: `modify`

ถามข้อมูลต่อไปนี้:

- มี Source Code ใหม่ (หลัง modify) ไหม?
- แก้ไขอะไรบ้าง? (Delta — เพิ่ม/ลบ/เปลี่ยน อะไร)
- ส่วนไหนที่ไม่เปลี่ยน? (Regression scope)
- มี Impact Analysis จาก Spec ไหม?
- สาเหตุที่ modify: Error / New Requirement / Performance?

**แนวทาง Test:** ตรวจเฉพาะส่วนที่เปลี่ยน (Delta test) + ตรวจว่าส่วนที่ไม่เปลี่ยนยังทำงานได้เหมือนเดิม (Regression test)

> **กรณี Spec เปลี่ยนแล้วกระทบ Test Script:**
> ให้เรียก `/test_service [ชื่อโปรแกรม] modify` แล้วแนบ:
> - Spec version ใหม่ (.md)
> - Test Script เดิม (.md)
> - บอกว่า Spec เปลี่ยนตรงไหน → AI จะแก้/เพิ่ม/ลบ test case เฉพาะส่วนที่ได้รับผลกระทบ ไม่ gen ใหม่ทั้งหมด

---

### Step 3: สรุป Test Plan ให้ Confirm

ก่อน generate ไฟล์จริง ต้องสรุปให้ SA/Dev ยืนยันก่อนเสมอ:

```
📋 Test Plan Summary — [ชื่อโปรแกรม] ([scenario])

Service Type : [Post/Daemon/Import/Export]
แนวทาง      : [convert=เทียบ 4GL / new=จาก Requirement / modify=Delta+Regression]

Test Cases ที่จะสร้าง:
- [Unit Test กี่ case, ครอบคลุมอะไรบ้าง]
- [Special Cases ที่จะ include]

Code Review Checklist:
- [หัวข้อหลักที่จะตรวจ]

SQL Verification:
- [จุดที่จะตรวจ]

ยืนยัน (พิมพ์ "Confirm") เพื่อสร้างไฟล์ [ชื่อโปรแกรม]-Test-Script.md
```

---

### Step 4: Generate ไฟล์ Test Script

เมื่อได้รับ Confirm → สร้างไฟล์ `[ชื่อโปรแกรม]-Test-Script.md`

---

## โครงสร้างไฟล์ Output

เมื่อเรียก `/test_service` จะสร้างไฟล์ **2 ไฟล์**:

| ไฟล์ | เนื้อหา |
|------|---------|
| `[ชื่อโปรแกรม]-Test-Script.md` | Unit Test Cases, Code Review, SQL Verification, Sign-off |
| `[ชื่อโปรแกรม]-Test-Data.md` | SQL Script เตรียมข้อมูลตั้งต้นสำหรับแต่ละ Test Case |

## ข้อมูลโปรแกรม
| Property | Value |
|----------|-------|
| Program  | ...   |
| Scenario | new / modify / convert |
| Service Type | Post / Daemon / Import / Export |
| เตรียมโดย | ... |
| วันที่   | ... |

---

## 0. Environment Checklist — ตรวจก่อนรันครั้งแรก
### 0.1 Config Files
- [ ] global_config.xml มีอยู่และอ่านได้
- [ ] NEWSBA_PHASE ถูกต้อง
- [ ] MODE_TEST ถูกต้อง (true=test args, false=args จริง)
- [ ] KN_LOG_PATH มีอยู่และมีสิทธิ์ write

### 0.2 Database Connection
- [ ] DB Connection (BA) ต่อได้
- [ ] DB Connection (refdb) ต่อได้ (กรณี NEWSBA_PHASE=1)
- [ ] DB Connection Pool size >= thread count ที่จะรัน
- [ ] User มีสิทธิ์ SELECT/INSERT/UPDATE/DELETE ทุก table

### 0.3 Optional Tables (ตรวจด้วย SQL: SELECT tabname FROM systables WHERE tabname IN (...))
- [ ] ระบุว่า table ใดมี/ไม่มีใน environment นี้
- [ ] jtcbl, xm_mcbl, xm_jcbl, tsbla, jccbl, tposterr, tsats

### 0.4 Optional Columns
- [ ] ตรวจ column พิเศษ เช่น tadw.includeint (SELECT colname FROM syscolumns...)

### 0.5 Master Data พร้อม
- [ ] tcbr มี rule ครบ
- [ ] tcc2 มี config ที่จำเป็น (SMARTLINK, CASHBAL, GENREFER)
- [ ] ttrn มี runtype ที่ใช้

### 0.6 Compile & Classpath
- [ ] compile ผ่านไม่มี error
- [ ] Library ที่จำเป็นอยู่ใน classpath ครบ

## 1. Test Environment Setup
## 2. Unit Test Cases
## 3. Code Review Checklist
## 4. SQL Verification Checklist
## 5. Sign-off Checklist
```

**ไฟล์ที่ 2: `[ชื่อโปรแกรม]-Test-Data.md`**

```markdown
## 0. ค่า Constant (Dev ต้องปรับก่อนใช้)   ← [TEST_ACCOUNT], [TEST_USERID] ฯลฯ
## 1. Cleanup Script                        ← DELETE/RESET ข้อมูล test เก่า (รันก่อนทุก test)
## 2. Master Data Setup                     ← tcc2, tcbr, tmg (รันครั้งเดียวต่อ environment)
## 3..N. Test Data ต่อ Test Case           ← INSERT/UPDATE + Expected Result SQL
## N+1. Verification Queries               ← SQL ตรวจผลภาพรวมหลังรัน
## N+2. สิ่งที่ Dev ต้องปรับ              ← ตาราง placeholder ทั้งหมด
```

**กฎการสร้าง Test Data Script:**
- ทุก INSERT ใช้ `WHERE NOT EXISTS` ป้องกัน duplicate
- ทุก Test Case มี Expected Result SQL แนบไว้ท้าย
- ค่าที่ Dev ต้องปรับใช้รูปแบบ `[TEST_ACCOUNT]`, `[TEST_USERID]` ให้หาง่าย
- ห้าม hardcode production data — ใช้ TEST prefix เสมอ
- มี section `สิ่งที่ Dev ต้องปรับ` สรุปทุก placeholder ไว้ท้ายไฟล์

---

## รายละเอียด Output แต่ละ Section

### Section 1: Test Environment Setup

```markdown
## 1. Test Environment Setup

### Database
- [ ] ใช้ DB ที่เป็น test environment เท่านั้น — ห้ามรันกับ production
- [ ] Backup ข้อมูล test ก่อนรันเสมอ
- [ ] ตรวจสอบ global_config.xml ว่า NEWSBA_PHASE ตรงกับที่ต้องการ test

### การรัน (Test Mode — ไม่ commit)
\`\`\`bash
java [ชื่อโปรแกรม] -c 0 -tc 1 -frame 100 -bs true -bc 100 -postdate [YYYYMMDD] -autorun 1 -userid test -userbranch 00
\`\`\`
> **สำคัญ:** ใช้ `-c 0` (ไม่ commit) เสมอในการ test — commit จริงเฉพาะเมื่อ verify ครบแล้ว

### Log File
- Log อยู่ที่: `[KN_LOG_PATH]/[ชื่อโปรแกรม].[YYYYMMDD]`
- เปิด log ดูควบคู่กับการรันเสมอ
```

---

### Section 2: Unit Test Cases (แยกตาม Scenario)

#### กรณี `convert` — Test Cases

```markdown
## 2. Unit Test Cases

> แนวทาง: เทียบ behavior หลักกับโปรแกรมเดิม (4GL)
> ไม่ต้อง match 100% เพราะมีการปรับเพิ่ม — เน้น critical path และ business rule หลัก

### 2.1 Happy Path — Normal Flow
| # | Test Case | Input | Expected Output | เทียบกับ 4GL | ผล |
|---|-----------|-------|-----------------|-------------|-----|
| 1 | [ชื่อ case] | [input] | [expected] | [behavior เดิม] | ☐ Pass ☐ Fail |

### 2.2 Special Cases
[ระบุตาม Special Case ที่พบใน Spec เช่น SMARTLINK, XM, includeint]

| # | Test Case | เงื่อนไข | Expected | ผล |
|---|-----------|---------|----------|-----|
| 1 | SMARTLINK='1' | ... | ... | ☐ Pass ☐ Fail |

### 2.3 Error / Edge Cases
| # | Test Case | เงื่อนไข | Expected | ผล |
|---|-----------|---------|----------|-----|
| 1 | Balance ไม่พอ (Reject Path) | cashbalance < amt | tadw.rejectflag='1', jcdm.delflag='1' | ☐ Pass ☐ Fail |
| 2 | ไม่มีข้อมูล tadw วันนั้น | 0 records | จบปกติ ไม่ error | ☐ Pass ☐ Fail |
| 3 | RERUN mode | -readlog true | ประมวลเฉพาะ account ใน tposterr | ☐ Pass ☐ Fail |

### 2.4 Multi-DB Compatibility
| # | Database | Test | ผล |
|---|----------|------|-----|
| 1 | Informix | รันปกติ ไม่มี SQL error | ☐ Pass ☐ Fail |
| 2 | MySQL | รันปกติ ไม่มี SQL error | ☐ Pass ☐ Fail |
| 3 | MSSQL | รันปกติ ไม่มี SQL error | ☐ Pass ☐ Fail |

### 2.5 NEWSBA_PHASE Test
| # | Phase | เงื่อนไข | Expected | ผล |
|---|-------|---------|----------|-----|
| 1 | Phase=0 | ไม่มี refconn | ใช้ BA เท่านั้น ไม่ error | ☐ Pass ☐ Fail |
| 2 | Phase=1 | มี refconn | ใช้ BA + refdb ตาม mapping | ☐ Pass ☐ Fail |
```

#### กรณี `new` — Test Cases

```markdown
## 2. Unit Test Cases

> แนวทาง: ตรวจจาก Requirement/Spec ว่า business rule ครบและ boundary ถูกต้อง
> ไม่มีโปรแกรมเดิมเทียบ — ใช้ Expected Output จาก Spec เป็น baseline

### 2.1 Business Rule Coverage
| # | Business Rule (จาก Spec/Req) | Test Case | Expected | ผล |
|---|------------------------------|-----------|----------|-----|
| 1 | [rule ที่ 1] | ... | ... | ☐ Pass ☐ Fail |

### 2.2 Boundary Cases
| # | Test Case | Input | Expected | ผล |
|---|-----------|-------|----------|-----|
| 1 | ค่า 0 | amt = 0 | [expected] | ☐ Pass ☐ Fail |
| 2 | ค่า null | field = null | [expected] | ☐ Pass ☐ Fail |
| 3 | ข้อมูลซ้ำ | duplicate key | [expected] | ☐ Pass ☐ Fail |
| 4 | ข้อมูลว่าง | 0 records | จบปกติ ไม่ error | ☐ Pass ☐ Fail |

### 2.3 Error Handling
| # | Test Case | เงื่อนไข | Expected | ผล |
|---|-----------|---------|----------|-----|
| 1 | DB Connection หลุด | network error | log error + rollback | ☐ Pass ☐ Fail |
| 2 | ข้อมูลไม่ถูก format | invalid data | log + skip หรือ abort (ตาม Spec) | ☐ Pass ☐ Fail |
```

#### กรณี `modify` — Test Cases

```markdown
## 2. Unit Test Cases

> แนวทาง: Delta Test (ส่วนที่เปลี่ยน) + Regression Test (ส่วนที่ไม่เปลี่ยน)

### 2.1 Delta Test — ตรวจส่วนที่เปลี่ยน
[ระบุตาม Impact Analysis จาก Spec]

| # | สิ่งที่เปลี่ยน | Test Case | Expected | ผล |
|---|--------------|-----------|----------|-----|
| 1 | [เปลี่ยนอะไร] | [test อย่างไร] | [expected] | ☐ Pass ☐ Fail |

### 2.2 Regression Test — ตรวจส่วนที่ไม่เปลี่ยน
[ระบุ scope ที่ไม่เปลี่ยน — ต้องยืนยันว่า behavior เดิมยังถูกต้อง]

| # | Test Case | Expected (เหมือนเดิม) | ผล |
|---|-----------|----------------------|-----|
| 1 | [behavior เดิม] | [expected เดิม] | ☐ Pass ☐ Fail |

### 2.3 Error Case ที่เกี่ยวกับการ Modify
| # | Test Case | ผล |
|---|-----------|-----|
| 1 | กรณีที่ trigger bug เดิม (ถ้ามี) → ต้องไม่เกิดซ้ำ | ☐ Pass ☐ Fail |
```

---

### Section 3: Code Review Checklist

```markdown
## 3. Code Review Checklist

Dev ต้อง review ทุกข้อก่อนส่งกลับ:

### 3.1 โครงสร้าง Class
- [ ] Main Class extends `PostMaster` อยู่ใน `com.fs.sba.post`
- [ ] Sub Class extends `SBAPostUnitNew` อยู่ใน `com.fs.sba.sub`
- [ ] Inner class `Inside` มี Savepoint ต่อทุก account
- [ ] `fetchVersion()`, `getPosters()`, `createStep()` ครบใน Main Class
- [ ] `initial()`, `optimize()`, `post()` ครบใน Sub Class

### 3.2 Config & Initialization
- [ ] อ่าน `NEWSBA_PHASE` จาก `GlobalConfig.getString("NEWSBA_PHASE", "0")` ก่อนทุก operation
- [ ] อ่าน tcc2 ผ่าน `DBLibrary.getTCC2String()` ไม่ใช่ SQL ตรง
- [ ] `SEQNOINCREMENT` อ่านจาก `TCC2.CASHBAL.SEQNOINCREMENT` (default 1000)
- [ ] ตรวจ optional tables ผ่าน `DatabaseMetaData` ไม่ใช่ try-catch
- [ ] ตรวจ RERUN จาก `sbalib.getTposterr()` ใน `initial()`

### 3.3 SQL & Database
- [ ] ทุก SQL ใช้ `KnSQL` — ไม่มี raw String SQL
- [ ] ทุก Temp Table ใช้ `TemporaryTable API` — ไม่มี `INTO TEMP` / `CREATE TEMPORARY TABLE`
- [ ] ไม่มี `NVL()` / `IFNULL()` / `ISNULL()` — ใช้ `COALESCE()` แทน
- [ ] ไม่มี `INSERT INTO t VALUES (...)` — ใช้ `Content.insert(conn)` แทน
- [ ] ไม่มี `EXISTS (SELECT 'x')` — ใช้ `EXISTS (SELECT 1)` แทน
- [ ] ไม่มี Stored Procedure call — ใช้ Java Library แทนทุกตัว

### 3.4 Library Calls
- [ ] `post_update_MCBL_cashbal` → `sbtp019s2.postUpdateMCBL(conn, LrJCBL, PS.KNDATE)`
- [ ] `cbinterest` → `CbInterestLibrary.cbinterest()` — ตรวจ key `"pirefttype"` (typo)
- [ ] `p_setwfapprover` → `SetUpWFApproverLibrary.setWFApprover()`
- [ ] `getrefer_by_channel` → `GenerateRefer` หรือ `GenerateRefer.getrefer_by_channel()`
- [ ] xm_jcbl seqno → hardcode +1000 (ไม่ใช้ SEQNOINCREMENT)

### 3.5 Threading & Transaction
- [ ] `ERRORCOUNT` เป็น `AtomicInteger`
- [ ] `JCALIST` เป็น `Collections.synchronizedList()`
- [ ] `CONNHASH` เป็น `Collections.synchronizedMap()`
- [ ] Savepoint ครอบทุก account ใน `Inside.post()`
- [ ] Rollback ถูก scope — rollback เฉพาะ savepoint ไม่ใช่ทั้ง transaction
- [ ] หลังรันเสร็จ: ถ้า ERRORCOUNT > 0 → `sbalib.insertTposterr()`

### 3.6 สิ่งที่ห้ามมีใน Code
- [ ] ไม่มี hardcode `+1000` สำหรับ jcbl.seqno
- [ ] ไม่มี hardcode string ที่ควรเป็น config
- [ ] ไม่มี `System.out.println()` — ใช้ `kn_dumptext()` / `logInfo()` แทน
- [ ] ไม่มี empty catch block โดยไม่ log
- [ ] ไม่มี SQL ที่ไม่มี WHERE clause ใน UPDATE/DELETE
```

---

### Section 4: SQL Verification Checklist

```markdown
## 4. SQL Verification Checklist

ตรวจทุก SQL ใน code ก่อนส่ง — ค้นหา keyword ต่อไปนี้ให้ครบ:

### 4.1 Forbidden Keywords (ต้องไม่มีใน code)
ค้นหาด้วย IDE หรือ grep:

\`\`\`bash
grep -rn "INTO TEMP\|WITH NO LOG\|NVL(\|IFNULL(\|ISNULL(\|SELECT 'x'\|EXECUTE PROCEDURE\|INTO #" src/
\`\`\`

| Keyword | ผลการค้นหา | ✅/❌ |
|---------|-----------|------|
| `INTO TEMP` | [ จำนวน occurrence ] | ☐ |
| `WITH NO LOG` | [ จำนวน occurrence ] | ☐ |
| `NVL(` | [ จำนวน occurrence ] | ☐ |
| `IFNULL(` | [ จำนวน occurrence ] | ☐ |
| `ISNULL(` | [ จำนวน occurrence ] | ☐ |
| `SELECT 'x'` | [ จำนวน occurrence ] | ☐ |
| `EXECUTE PROCEDURE` | [ จำนวน occurrence ] | ☐ |
| `SELECT INTO #` | [ จำนวน occurrence ] | ☐ |

> ทุกรายการต้องมี 0 occurrence — ถ้าพบให้แก้ก่อนส่ง

### 4.2 Required Patterns (ต้องมีใน code)
| Pattern | ตรวจแล้ว | ✅/❌ |
|---------|---------|------|
| ทุก SQL ใช้ `new KnSQL(this)` | ☐ | ☐ |
| Temp Table ใช้ `createTemporaryTable()` | ☐ | ☐ |
| NULL check ใช้ `COALESCE()` | ☐ | ☐ |
| Insert ใช้ `Content.insert(conn)` | ☐ | ☐ |
| Parameter binding ใช้ `knsql.setParameter()` | ☐ | ☐ |
```

---

### Section 5: Sign-off Checklist

```markdown
## 5. Sign-off Checklist

> **วิธีกรอก Checklist:**
> เปิดไฟล์ .md นี้ด้วย Text Editor (Notepad, VS Code, หรืออื่นๆ)
> เปลี่ยน `[ ]` เป็น `[x]` เมื่อผ่านแต่ละข้อ
> ```
> - [ ]  = ยังไม่ผ่าน
> - [x]  = ผ่านแล้ว
> ```

Dev ยืนยันทุกข้อก่อนส่งโปรแกรมกลับ:

### Development Complete
- [ ] Code compile ผ่านโดยไม่มี error หรือ warning สำคัญ
- [ ] Import statements ครบ ไม่มี unused import
  > unused import คือบรรทัด `import` ที่ไม่ได้ถูกใช้งานจริงในโค้ด — IDE เช่น IntelliJ/Eclipse จะขีดเส้นใต้ให้เห็น และ SonarQube จะ flag อัตโนมัติ
- [ ] Unit Test Cases ผ่านทุกข้อใน Section 2
- [ ] Code Review Checklist ผ่านทุกข้อใน Section 3
- [ ] SQL Verification ผ่านทุกข้อใน Section 4

### Testing Complete
- [ ] รันด้วย `-c 0` (ไม่ commit) แล้ว log ไม่มี error
- [ ] รันด้วย `-c 1` (commit จริง) ใน test environment แล้ว data ถูกต้อง
- [ ] กรณี convert: เทียบ output หลักกับโปรแกรมเดิมแล้วสอดคล้องกัน
- [ ] กรณี modify: Regression test ผ่านทุก case
- [ ] กรณี new: Business rule ครบตาม Requirement/Spec

### Code Quality
- [ ] ไม่มี TODO หรือ FIXME ที่ยังไม่ได้แก้
- [ ] Log message ครบและอ่านเข้าใจได้
- [ ] Exception ทุกตัวได้รับการ handle อย่างเหมาะสม

### ไฟล์ที่ต้องส่งกลับ SA (บังคับ)
- [ ] Source code ครบทุกไฟล์ (Main Class + Sub Class)
- [ ] Log file หลังรันโปรแกรม — ส่ง **2 ไฟล์** เปลี่ยนชื่อก่อนส่ง:

  **Java:**
  - `[ชื่อโปรแกรม]_c0.log` ← จากการรันด้วย `-c 0` (rollback — ตรวจ flow ไม่กระทบ DB)
  - `[ชื่อโปรแกรม]_c1.log` ← จากการรันด้วย `-c 1` (commit จริง — ตรวจว่า DB ถูกต้อง)

  **4GL:**
  - `[ชื่อโปรแกรม]_abort.log` ← จากการรัน abort (test case ไหนก็ได้ — ดูแค่ flow/step)
  - `[ชื่อโปรแกรม]_commit.log` ← จากการรัน commit จริง **ต้องเป็น happy path** ที่ตรงกับ DB Result ที่ส่งมา

  > ต้องเปลี่ยนชื่อก่อนส่งเพราะทั้งสองรันได้ชื่อไฟล์เดียวกันจาก framework
- [ ] DB Result จาก Verification Queries ใน Section 4 — บันทึกเป็นไฟล์ `[ชื่อโปรแกรม]-DB-Result.txt` แล้วส่งมาพร้อมกัน
  > รัน query ทุกข้อใน Section 4 แล้ว copy ผลลัพธ์มาวางในไฟล์ โดยระบุชื่อ query แต่ละข้อด้วย ตัวอย่าง format:

  ```
  === Query 1: [ชื่อ query] ===
  [column headers]
  [ข้อมูลผลลัพธ์]
  N rows returned.

  === Query 2: [ชื่อ query] ===
  No rows returned.
  ```

  > SA และ AI ใช้ไฟล์นี้ตอน /review_service เพื่อเทียบกับ expected result ใน Test Script
- [ ] Sign-off Checklist นี้ (กรอกครบแล้วทุกข้อ)

> ⚠️ **SonarQube และ .zip ไม่ต้องส่งในรอบนี้** — Dev ยังไม่ได้ control version
> SonarQube และ .zip จะส่งหลังจาก SA approve และ Dev tag version แล้วเท่านั้น

### ลงชื่อ Dev
| รายการ | ข้อมูล |
|--------|--------|
| Dev Name | ... |
| วันที่ส่ง | ... |
| Spec Version อ้างอิง | [ชื่อโปรแกรม]-TFS-Spec.md [version] |
| **Commit Hash** | ... ← commit code ก่อนส่ง SA แล้วระบุ hash ที่นี่ |
| **Class Version** | เช่น `com.fs.sba.post.[ชื่อ]: 1.00, com.fs.sba.sub.[ชื่อ]S1: 1.01` |
| หมายเหตุ | ... |

> **Commit Hash สำคัญมาก** — SA จะ approve ด้วย hash นี้
> Dev ต้องใช้ hash เดียวกันเป็น base สำหรับ control version
> ถ้า hash ไม่ตรง SA จะไม่สามารถยืนยันได้ว่า code ที่ tag คือตัวเดียวกับที่ test
```

---

## กฎพิเศษ: Service Type = Import

เมื่อโปรแกรมเป็น **Import** ให้เพิ่มใน Test Data เสมอ:

1. **CSV Test Files section** แยกออกมาชัดเจน ไม่ใส่ใน SQL comment
2. แต่ละไฟล์ต้องระบุ:
   - ชื่อไฟล์จริงที่ Dev ต้องสร้าง
   - วิธีสร้าง (copy content ด้านล่างบันทึกเป็นไฟล์)
   - จำนวน field ที่ต้องมีต่อบรรทัด
   - คำเตือน format (Header, Double Quote, field count)
3. สร้างครบทุก case ที่ต้องการ test:
   - ไฟล์ถูกต้อง (happy path)
   - ไฟล์ format ผิด (error case)

**ตัวอย่าง format:**
```
-- ────────────────────────────────────────────────────────
-- [ชื่อไฟล์].csv (จำนวน fields)
-- วิธีสร้าง: copy ข้อความด้านล่างบันทึกเป็นไฟล์ชื่อ [ชื่อไฟล์].csv
-- ────────────────────────────────────────────────────────
/*
[header line]
[data line 1]
[data line 2]
*/
-- ⚠️ บรรทัดแรกคือ Header
-- ⚠️ ต้องมีครบ [N] fields ต่อบรรทัด
```

> **SA ต้องส่ง CSV files จริงให้ Dev ด้วย** — Dev ไม่มีไฟล์จริงไม่สามารถรัน test ได้

เมื่อ generate Test Script แล้ว ให้เพิ่ม Section นี้เสมอ — Dev นำไปให้ AI generate JUnit test ได้ทันที

### โครงสร้าง JUnit Test Template

```markdown
## 6. Automated Test Code Template

> Dev นำ Spec + Test Script + Source Code ให้ AI generate JUnit test
> Framework: JUnit 5 + Mockito

### 6.1 Setup & Teardown

```java
@ExtendWith(MockitoExtension.class)
class [ชื่อโปรแกรม]S1Test {

    @Mock private Connection conn;
    @Mock private Connection refconn;

    private [ชื่อโปรแกรม]S1 program;

    @BeforeEach
    void setUp() throws Exception {
        program = new [ชื่อโปรแกรม]S1();
        // init libraries, config ตาม Spec Section 12.1
    }

    @AfterEach
    void tearDown() throws Exception {
        // Cleanup test data
        // DELETE FROM [tables] WHERE account IN ([test accounts])
    }
}
```

### 6.2 Test Method Template ต่อ Test Case

```java
@Test
@DisplayName("Test Case [X.X]: [ชื่อ Test Case]")
void test[CaseName]() throws Exception {
    // Arrange — เตรียมข้อมูล (ใช้ Test Data Script)
    // รัน SQL จาก Test-Data.md สำหรับ case นี้

    // Act — รันโปรแกรม
    program.run(new String[]{
        "-c", "0",              // ไม่ commit
        "-tc", "1",
        "-postdate", "20260430",
        "-autorun", "1",
        "-userid", "FWS",
        "-userbranch", "00"
    });

    // Assert — ตรวจผล (ใช้ Verification Query จาก Test-Data.md)
    // [Expected Result จาก Test Script]
}
```

### 6.3 Mockable Dependencies ที่ต้อง Mock

[ระบุ Library หรือ external system ที่โปรแกรมนี้เรียกใช้และต้องการ mock]

| Library | Mock ด้วย | เหตุผล |
|---------|---------|--------|
| [เช่น CbInterestLibrary] | `@Mock` + `when().thenReturn()` | ต้องการ control return value |
| [เช่น SetUpWFApproverLibrary] | `@Mock` + `verify()` | ตรวจว่าถูกเรียกหรือไม่ |

### 6.4 Idempotent Check

```java
@Test
@DisplayName("Idempotent: รันซ้ำให้ผลเดิม")
void testIdempotent() throws Exception {
    // รันครั้งที่ 1
    program.run(args);
    Object result1 = queryVerification();

    // รันครั้งที่ 2 (ไม่ cleanup ระหว่างกัน)
    program.run(args);
    Object result2 = queryVerification();

    // ผลต้องเหมือนกัน
    assertEquals(result1, result2);
}
```
```
