# คู่มือการติดตั้งและใช้งาน SA Skill

## ภาพรวม

SA Skill คือชุดคำสั่งที่ช่วย SA ในการทำงาน 4 ด้านหลัก:

| คำสั่ง | หน้าที่ |
|--------|--------|
| `/spec_service` | gen Spec โปรแกรม Java หรือ 4GL |
| `/release` | promote Spec จาก Draft → v1.0 |
| `/test_service` | gen Test Script + Test Data |
| `/review_service` | ตรวจ Code vs Spec + Bug Report |

---

## ก่อนเริ่ม — สิ่งที่ต้องมี

- [ ] บัญชี **Claude.ai** (แนะนำ Pro หรือสูงกว่า)
- [ ] ไฟล์ SKILL.md ทั้ง 3 ไฟล์ที่ได้รับมา:
  - `spec-service-SKILL.md`
  - `test-service-SKILL.md`
  - `review-service-SKILL.md`

---

## วิธีที่ 1: Claude.ai Projects (แนะนำ)

วิธีนี้ upload ไฟล์ครั้งเดียว ใช้ได้ทุก conversation ใน Project นั้น

### ขั้นตอน

**ขั้นที่ 1: เตรียมไฟล์**

ใช้ชื่อไฟล์ตามที่ได้รับมาได้เลย ไม่ต้องเปลี่ยนชื่อ:
```
spec-service-SKILL.md
test-service-SKILL.md
review-service-SKILL.md
```

> ⚠️ ห้ามเปลี่ยนชื่อทั้ง 3 ไฟล์เป็น `SKILL.md` เหมือนกัน — Claude.ai จะแยกไม่ออกว่าไฟล์ไหนคือ skill ไหน

**ขั้นที่ 2: สร้าง Project ใน Claude.ai**

1. เปิด [claude.ai](https://claude.ai)
2. คลิก **"Projects"** ในแถบซ้าย
3. คลิก **"New Project"**
4. ตั้งชื่อ Project เช่น `SA Skill — BackOffice`

**ขั้นที่ 3: Upload SKILL.md ทั้ง 3 ไฟล์**

1. เข้า Project ที่สร้างไว้
2. คลิก **"Add content"** หรือ **"Upload files"**
3. Upload ไฟล์ SKILL.md ทั้ง 3 ไฟล์
4. รอจน upload เสร็จทั้งหมด

**ขั้นที่ 4: ทดสอบว่าใช้งานได้**

เปิด conversation ใหม่ใน Project แล้วพิมพ์:
```
/spec_service SBCP001 new Post
```
AI ควรเริ่มถามข้อมูลโปรแกรมทันที — ถ้าไม่ตอบอะไรแสดงว่า SKILL ยังโหลดไม่ถูกต้อง

---

## วิธีที่ 2: แนบไฟล์ทุกครั้ง (ไม่มี Projects)

ถ้าไม่มี Projects ให้แนบ SKILL.md ที่ต้องการใช้เข้า conversation ทุกครั้ง

**ตัวอย่าง — ต้องการ gen Spec:**
1. เปิด conversation ใหม่
2. แนบ `spec-service-SKILL.md` เข้ามา
3. พิมพ์คำสั่ง `/spec_service SBCP001 new Post`

**ข้อเสีย:** ต้องแนบทุกครั้ง และถ้า conversation ยาวมาก AI อาจลืม SKILL ได้

---

## วิธีการใช้งานแต่ละคำสั่ง

### `/spec_service` — gen Spec

```
/spec_service [ชื่อโปรแกรม] [scenario] [type]
```

| Argument | ค่าที่ใช้ได้ |
|----------|------------|
| scenario | `new` / `modify` / `convert` |
| type | `Post` / `Import` / `Export` / `Daemon` |

**ตัวอย่าง:**
```
/spec_service SBCP005 new Post
/spec_service SCMS02 convert Daemon
/spec_service BCP005 modify Post
```

**สิ่งที่ต้องแนบ:**
- `new` → Requirement doc (.docx / .pdf)
- `modify` → Source Code เดิม (.java / .4gl)
- `convert` → Source Code เดิม (.java / .4gl)

> AI จะถามข้อมูลเพิ่มเติมไปเรื่อยๆ จนครบ แล้ว confirm ก่อน generate

---

### `/release` — promote Spec เป็น v1.0

```
/release
```

- พิมพ์ใน **conversation เดิม** กับ `/spec_service`
- AI จะตรวจว่ามี TBD ค้างอยู่ไหม → ถ้าไม่มี promote เป็น v1.0

---

### `/test_service` — gen Test Script

```
/test_service [ชื่อโปรแกรม] [scenario]
```

**สิ่งที่ต้องแนบ:**
- Spec .md (version Released)
- DDL .sql (ถ้ามี)
- CSV test files (เฉพาะ Import)

**ไฟล์ที่ได้:**
- `[ชื่อ]-Test-Script.md`
- `[ชื่อ]-Test-Data.md`

---

### `/review_service` — ตรวจ Code vs Spec

```
/review_service [ชื่อโปรแกรม]
```

**สิ่งที่ต้องแนบ (บังคับ):**

| ไฟล์ | Java | 4GL |
|------|------|-----|
| Source code | ✅ | ✅ |
| Spec .md (Released) | ✅ | ✅ |
| Log file | `_c0.log` + `_c1.log` | `_abort.log` + `_commit.log` |
| DB-Result.txt | ✅ | ✅ |
| Sign-off Checklist | ✅ | ✅ |
| DDL .sql | แนะนำ (ช่วย review index) | แนะนำ |

> ⚠️ **ยังไม่ต้องมี SonarQube** — ส่งหลังจาก SA approve แล้วเท่านั้น

**ไฟล์ที่ได้:** `[ชื่อ]-Review-Report.md`

---

## format ไฟล์ที่ Dev ต้องส่ง

### Log file

**Java — rename ก่อนส่ง:**
```
[ชื่อโปรแกรม]_c0.log   ← จากการรันด้วย -c 0 (rollback)
[ชื่อโปรแกรม]_c1.log   ← จากการรันด้วย -c 1 (commit จริง)
```

**4GL — rename ก่อนส่ง:**
```
[ชื่อโปรแกรม]_abort.log    ← รัน abort รอบไหนก็ได้
[ชื่อโปรแกรม]_commit.log   ← รัน happy path (commit จริง)
                               ต้องตรงกับ DB Result ที่ส่งมา
```

### DB-Result.txt

Copy output จาก dbaccess มาวางตาม format นี้:
```
=== Query 1: [ชื่อ query] ===
[column headers]
[ข้อมูลผลลัพธ์]
N rows returned.

=== Query 2: [ชื่อ query] ===
No rows returned.
```

> ⚠️ Date format ใน WHERE clause ต้องเป็น **YYYYMMDD** เสมอ

### Sign-off Checklist

เปิดไฟล์ .md ด้วย Text Editor (Notepad, VS Code)
เปลี่ยน `[ ]` เป็น `[x]` เมื่อผ่านแต่ละข้อ:
```
- [ ]  = ยังไม่ผ่าน
- [x]  = ผ่านแล้ว
```

---

## ลำดับการทำงาน (ภาพรวม)

```
SA รับ Requirement
    ↓
/spec_service → review draft (d1, d2...)
    ↓
/release → Spec v1.0
    ↓
/test_service → Test Script + Test Data
    ↓
ส่ง Dev — เปิด Git Issue
    ↓
Dev code + test → ส่ง code + log + DB Result + Sign-off
    ↓
/review_service → SA ตรวจ → Bug Report
    ↓
[ถ้าไม่ผ่าน] Return ให้ Dev แก้ → วนซ้ำ
[ถ้าผ่าน] SA comment Commit Hash ใน Git Issue
    ↓
Dev tag version + SonarQube
    ↓
SA ตรวจ GitLab Tags + SonarQube → ปิด Issue ✅
```

---

## Tips

**ถ้าข้อมูลยังไม่ครบ:**
พิมพ์ "TBD" — AI จะระบุใน Spec และแนะนำให้ถาม BA

**ถ้า AI ตอบไม่ได้:**
AI จะบอกตรงๆ และแนะนำให้ถาม PSR — ไม่เดา

**Daemon ที่มี folder ซับซ้อน (func/, bean/, util/):**
Claude.ai แนบ folder ไม่ได้ — AI จะ gen PowerShell script ให้ merge source เป็นไฟล์เดียวก่อน

**Version Spec:**
- ระหว่างคุยกับ AI: `d1, d2, d3...`
- พร้อมส่ง Dev: `/release` → `v1.0`
- แก้หลัง release: `d4` → `v1.1`

---

## ถ้าพบปัญหา

| ปัญหา | วิธีแก้ |
|-------|--------|
| AI ไม่รับคำสั่ง `/spec_service` | ตรวจว่า SKILL.md ถูก upload ใน Project แล้ว |
| AI ถามซ้ำหรือลืม context | conversation ยาวเกินไป — เปิด conversation ใหม่แล้วแนบ SKILL + Spec เดิม |
| ต้องการ feedback หรือพบ bug ใน SKILL | แจ้ง PSR (qpsr) |
