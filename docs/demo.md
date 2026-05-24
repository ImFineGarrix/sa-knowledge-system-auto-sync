# Demo Prompts

> Copy. Paste. ดูผล — ทุก prompt ด้านล่างเชื่อมกับ agent จริง สร้าง output จริงได้ทันที

## 1 · ถาม vault เรื่องอะไรก็ได้

<pre><code class="language-text">Use the kb-assistant agent:
GOLDPORTPLUS มี integration อะไรบ้างกับ SCB?</code></pre>
**สิ่งที่เกิดขึ้น** · kb-assistant อ่าน `.index/master-index.md` เปิด note GPP × SCB ที่เกี่ยว สรุปคำตอบ อ้างอิงชื่อไฟล์ทุกแหล่ง ไม่ hallucinate

---

## 2 · ออกแบบ UI mockup จากประโยคเดียว

<pre><code class="language-text">Use the spec-ui-designer agent:
ออกแบบหน้า admin จัดการ user account สำหรับ SCB integration
Filter: name, status, role · bulk action: deactivate, reset password
ฟีลสงบ professional · รองรับไทย + อังกฤษ</code></pre>
**สิ่งที่เกิดขึ้น** · ถามรายละเอียดที่ขาด (breakpoint, mood, constraint), iterate 2–3 sketch แล้วส่งออก:

- `sa_designweb_user-management/index.html` — mockup ระดับ production
- `sa_designweb_user-management/styles.css` — style แยกไฟล์
- `sa_designweb_user-management/spec.md` — brief สำหรับ handoff

---

## 3 · ออกแบบ REST API ใน 30 วินาที

<pre><code class="language-text">Use the spec-api-designer agent:
ออกแบบ REST API สำหรับ partner notification — webhook ส่งพร้อม retry,
HMAC signature, dead-letter queue ตาม Spring Boot 3.x convention
use context7</code></pre>
**สิ่งที่เกิดขึ้น** · trigger `use context7` ดึง docs Spring Boot 3 จริงเข้า context · output: endpoint table, request/response schema, error format, retry policy, OpenAPI skeleton

---

## 4 · Dev handoff ครบชุด ใน prompt เดียว

<pre><code class="language-text">Use the gateway-thirdparty-api agent:
Handoff package ครบชุดสำหรับงาน EOD export — story, requirements,
DB schema, API spec, sequence + architecture diagram, test script,
Postman collection, GitLab issue พร้อม assign</code></pre>
**สิ่งที่เกิดขึ้น** · สร้าง 12+ ไฟล์ใน folder เดียว — Dev เปิดแล้วเริ่ม code ได้ในชั่วโมงนั้น

---

## 5 · ดึง vendor PDF เข้า vault

<pre><code class="language-text">อ่าน Projects/GOLDPORTPLUS/references/scb-spec.pdf
แล้วสรุปทุก endpoint เป็น Markdown table
save ที่ Projects/GOLDPORTPLUS/front2-scb/endpoints-extracted.md
พร้อม frontmatter ที่ถูกต้อง</code></pre>
**สิ่งที่เกิดขึ้น** · skill `pdf` activate ดึง text + table · skill `obsidian-markdown` เขียน frontmatter + wikilink ให้

---

## 6 · สร้าง data dictionary เป็น Excel

<pre><code class="language-text">จาก Projects/GOLDPORTPLUS/front2-scb/export-eod-scb.md
สร้าง data-dictionary.xlsx มี column: field, type, length,
required, description, source, target</code></pre>
**สิ่งที่เกิดขึ้น** · skill `xlsx` สร้าง Excel จริง พร้อม format, freeze pane, column width

---

## 7 · Review code ที่ Dev ส่งคืน

<pre><code class="language-text">Use the spec-reviewer agent:
Dev ส่ง code สำหรับโปรแกรม TRD-CONFIRM-001 กลับมา
รีวิวเทียบกับ Projects/GOLDPORTPLUS/front1-dime/specs/trd-confirm-001.md
ส่ง Gap Analysis, Bug Report, และ Sign-off checklist</code></pre>
**สิ่งที่เกิดขึ้น** · 3 artifact ถูก save ไว้ข้าง spec · ทุก gap มี severity, file, line, expected vs actual

---

## 8 · จด decision ก่อนลืม

<pre><code class="language-text">Use the decision-keeper agent:
บันทึก decision — เลือก JWT แทน session cookie สำหรับ GPP front2
เพราะข้อจำกัดของ mobile SDK · trade-off: ต้องจัดการ token refresh</code></pre>
**สิ่งที่เกิดขึ้น** · เขียน ADR entry ใหม่ · update Quick Status table ที่ด้านบน `architecture-decisions.md` · link ไปยัง product MOC

---

## 9 · Log session

<pre><code class="language-text">Use the session-logger agent: log this session</code></pre>
**สิ่งที่เกิดขึ้น** · เขียน `Memory/sessions/<today>.md` — คุยเรื่องอะไร, ตัดสินใจอะไร, แก้ไฟล์อะไร, ค้างอะไรไว้ · update `Memory/summary.md`

---

## 10 · Document database จาก SQL dump

<pre><code class="language-text">Use the db-schema-documenter agent:
Document Projects/GOLDPORTPLUS/references/scb-export.sql
ที่ Projects/GOLDPORTPLUS/front2-scb/database/</code></pre>
**สิ่งที่เกิดขึ้น** · สร้าง markdown แยกตาราง — DDL, ความหมาย column, sample data, common query, relationship · SA และ Dev ใช้ source เดียวกัน

---

## Pattern

ทุก prompt มีรูปแบบเดียวกัน: **บอกงาน, เรียกชื่อ agent, ชี้ source** —
agent จะจัดการที่เหลือ แล้วอ้างอิงแหล่งที่มาทุกครั้ง
