# Agents

> AI ผู้เชี่ยวชาญ **15** ตัว — แต่ละตัวรู้หน้าที่ของตัวเอง รู้ว่าเมื่อไหร่ควรลงมือ

ทีมถูกจัดเป็น 4 ชั้น — *spec orchestrator* ที่กระจายงาน, 7 ตัว *specialist* ที่ลงมือเขียนจริง, *supporting agent* ที่ดูแล memory + search, และ *meta agent* 2 ตัวสำหรับขยายทีม + นำเข้าข้อมูล

## Spec Workflow · 8 agents

<div class="cat-grid" markdown>
<div class="cat-card" markdown>
<div class="cat-card__head">
<div class="cat-card__name">spec-writer</div>
<div class="cat-card__tag">orchestrator</div>
</div>
<div class="cat-card__desc">ตัวกระจายงานหลักของทั้งระบบ — รับโจทย์ spec ทุกชนิด วิเคราะห์ว่าเป็น spec แบบไหน แล้วส่งต่อให้ specialist ที่ใช่</div>
<div class="cat-card__prompt">Use the spec-writer agent: ต้องการ spec API สำหรับ login flow</div>
</div>
<div class="cat-card" markdown>
<div class="cat-card__head">
<div class="cat-card__name">spec-ui-designer</div>
<div class="cat-card__tag">UI · sa-designweb</div>
</div>
<div class="cat-card__desc">ออกแบบ UI mockup สำหรับ enterprise web — form, table, dashboard, wizard, admin panel ส่งออกเป็น HTML + CSS + spec.md ครบชุด</div>
<div class="cat-card__prompt">Use spec-ui-designer: mockup หน้าจัดการ user สำหรับ admin</div>
</div>
<div class="cat-card" markdown>
<div class="cat-card__head">
<div class="cat-card__name">spec-backend-service</div>
<div class="cat-card__tag">Backend · spec-service</div>
</div>
<div class="cat-card__desc">เขียน Program Specification สำหรับ Java backend — Post, Daemon, Import, Export รองรับ multi-DB และ cloud-native</div>
<div class="cat-card__prompt">Use spec-backend-service: TFS สำหรับ daemon process X</div>
</div>
<div class="cat-card" markdown>
<div class="cat-card__head">
<div class="cat-card__name">spec-api-designer</div>
<div class="cat-card__tag">API · sa-api-design</div>
</div>
<div class="cat-card__desc">ออกแบบและรีวิว REST API — endpoint, schema, status code, error format, auth, pagination, OpenAPI skeleton</div>
<div class="cat-card__prompt">Use spec-api-designer: ออกแบบ REST API สำหรับ partner</div>
</div>
<div class="cat-card" markdown>
<div class="cat-card__head">
<div class="cat-card__name">spec-report-designer</div>
<div class="cat-card__tag">Report · spec_report</div>
</div>
<div class="cat-card__desc">เขียน Technical Functional Specification สำหรับ report program — Daily Confirmation, Portfolio Summary, WHT, xdocReport</div>
<div class="cat-card__prompt">Use spec-report-designer: TFS สำหรับ daily trade report</div>
</div>
<div class="cat-card" markdown>
<div class="cat-card__head">
<div class="cat-card__name">spec-tester</div>
<div class="cat-card__tag">QA · test-service</div>
</div>
<div class="cat-card__desc">สร้าง test script และ review checklist สำหรับ Java service ใช้ก่อน Dev ส่งคืน หรือเวลา SA ต้องการ QA checklist</div>
<div class="cat-card__prompt">Use spec-tester: test script โปรแกรม X scenario convert</div>
</div>
<div class="cat-card" markdown>
<div class="cat-card__head">
<div class="cat-card__name">spec-reviewer</div>
<div class="cat-card__tag">Review · review-service</div>
</div>
<div class="cat-card__desc">รีวิว Java code ที่ Dev ส่งคืน เทียบกับ spec ต้นฉบับ — ออก Gap Analysis, Bug Report, และ Sign-off checklist</div>
<div class="cat-card__prompt">Use spec-reviewer: รีวิว code Dev ส่งกลับ โปรแกรม X</div>
</div>
<div class="cat-card" markdown>
<div class="cat-card__head">
<div class="cat-card__name">gateway-thirdparty-api</div>
<div class="cat-card__tag">Handoff · gatewayapi</div>
</div>
<div class="cat-card__desc">ห่อ dev-handoff package ครบชุด — story, requirements, UI prototype, DB schema, API spec, sequence + architecture diagram, test, Postman, GitLab issue</div>
<div class="cat-card__prompt">Use gateway-thirdparty-api: full handoff สำหรับ feature X</div>
</div>
</div>

## Memory · 2 agents

<div class="cat-grid" markdown>
<div class="cat-card" markdown>
<div class="cat-card__head">
<div class="cat-card__name">decision-keeper</div>
<div class="cat-card__tag">ADR log</div>
</div>
<div class="cat-card__desc">ดูแล Architecture Decisions Log ที่ <code>Projects/_meta/architecture-decisions.md</code> — เป็น "ความทรงจำเชิงโครงสร้าง" ของทีมข้าม session</div>
<div class="cat-card__prompt">Use decision-keeper: บันทึก decision — เลือก approach Y</div>
</div>
<div class="cat-card" markdown>
<div class="cat-card__head">
<div class="cat-card__name">session-logger</div>
<div class="cat-card__tag">Session memory</div>
</div>
<div class="cat-card__desc">บันทึกทุก session ที่มีความหมายไว้ใน <code>Memory/sessions/</code> และอ่าน session ก่อนหน้าตอนเปิดงานใหม่ — ทำให้ทีมต่อเนื่องข้ามคน ข้ามเวลา</div>
<div class="cat-card__prompt">Use session-logger: read at session start</div>
</div>
</div>

## Supporting · 3 agents

<div class="cat-grid" markdown>
<div class="cat-card" markdown>
<div class="cat-card__head">
<div class="cat-card__name">kb-assistant</div>
<div class="cat-card__tag">Q&A</div>
</div>
<div class="cat-card__desc">ตอบคำถามทุกอย่างเกี่ยวกับ vault — ค้นหาก่อนเสมอ, อ้างอิงไฟล์เสมอ, ถ้าไม่มีก็บอกว่าไม่มี ไม่ hallucinate</div>
<div class="cat-card__prompt">Use kb-assistant: ทีมเรามี integration อะไรบ้าง</div>
</div>
<div class="cat-card" markdown>
<div class="cat-card__head">
<div class="cat-card__name">indexer</div>
<div class="cat-card__tag">Index refresh</div>
</div>
<div class="cat-card__desc">สร้างและ refresh ไฟล์ index ใน <code>.index/</code> เพื่อให้ kb-assistant และ agent อื่นค้นหาเร็วโดยไม่ต้องสแกน vault ทั้งหมด</div>
<div class="cat-card__prompt">Use indexer: refresh the index</div>
</div>
<div class="cat-card" markdown>
<div class="cat-card__head">
<div class="cat-card__name">db-schema-documenter</div>
<div class="cat-card__tag">SQL → docs</div>
</div>
<div class="cat-card__desc">แปลง <code>.sql</code> dump (mysqldump / pg_dump) เป็น markdown — DDL, ความหมายของแต่ละ column, sample data, relationship</div>
<div class="cat-card__prompt">Use db-schema-documenter: document dump.sql ที่ Projects/X</div>
</div>
</div>

## Meta · 2 agents

<div class="cat-grid" markdown>
<div class="cat-card" markdown>
<div class="cat-card__head">
<div class="cat-card__name">skill-to-agent</div>
<div class="cat-card__tag"> agent builder</div>
</div>
<div class="cat-card__desc">แปลง <em>personal skill</em> ของ SA แต่ละคนเป็น team agent ที่ใช้ได้ทั้งทีม — อ่าน prompt/template/SOP ที่คุณใช้อยู่เดิม แล้ว <strong>ถามกลับเป็น batch จนข้อมูลครบ</strong> ก่อนเขียนเป็น agent file ไม่เดาเอง</div>
<div class="cat-card__prompt">Use skill-to-agent: convert ~/my-prompts/release-notes.md</div>
</div>
<div class="cat-card" markdown>
<div class="cat-card__head">
<div class="cat-card__name">doc-to-vault</div>
<div class="cat-card__tag"> NEW · doc importer</div>
</div>
<div class="cat-card__desc">นำ doc เก่า (PDF, Word, Excel, slides, MD, ทั้ง folder) เข้า vault เป็น Markdown ที่มี frontmatter + wikilink + tag ถูกต้อง — สแกน, classify, <strong>ถามกลับเรื่อง target folder + taxonomy</strong>, preview, แล้วค่อยเขียน</div>
<div class="cat-card__prompt">Use doc-to-vault: import ทั้ง folder ~/old-specs/ProductA/</div>
</div>
</div>

## วิธีเรียก agent

ภายใน Claude Code ให้พิมพ์:
<pre><code class="language-text">
&gt; Use the &lt;agent-name&gt; agent: &lt;ความต้องการ&gt;
</code></pre>
ถ้าไม่แน่ใจว่าเลือก specialist ตัวไหน — ใช้ `spec-writer` เป็น entry point มันจะ route ให้

## ขยายทีม agent ของคุณเอง

SA แต่ละคนมี skill ส่วนตัวที่ใช้บ่อย — prompt template, SOP, checklist เฉพาะตัว
ใช้ `skill-to-agent` แปลงของส่วนตัวเหล่านั้นเป็น agent ที่ทั้งทีมใช้ได้
<pre><code class="language-text">
&gt; Use skill-to-agent: ผมมี prompt ใช้ทำ release notes อยู่ที่ ~/notes/rn.md
  ทำเป็น agent ให้หน่อย</code></pre>
agent จะ:

1. อ่านไฟล์ของคุณ
2. ดึงทุกอย่างที่หาได้
3. **ถามกลับเป็น batch** เฉพาะส่วนที่ขาด (name, trigger, input, output, guardrails)
4. โชว์ preview ให้ confirm
5. เขียนไฟล์ที่ `.claude/agents/<name>.md`
6. แนะนำให้รัน `indexer` refresh
