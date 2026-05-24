# Changelog

> บันทึกการเปลี่ยนแปลงของ SA Knowledge System template · เรียงจากใหม่ไปเก่า · click ที่แต่ละรายการเพื่อดูรายละเอียด

## 2026-05-20

<div class="changelog" markdown>

<details class="changelog__item" markdown>
<summary><span class="changelog__time">15:42</span> Skill v2 + เปลี่ยนชื่อทั้งหมดเป็น <code>gateway-thirdparty-api</code></summary>

เปลี่ยน skill SA Spec Dev Handoff เป็นเวอร์ชันใหม่ที่ NXT ส่งมา · ของเดิม `SKILL.md` ไฟล์เดียวยาว แตกเป็น modular 7 ไฟล์ที่ load on demand · 33 templates ย้ายผ่าน `git mv` · history คงไว้ครบ

**เปลี่ยนชื่อทุก layer ให้เหลือชื่อเดียว:**

- Agent · `spec-dev-handoff` → `gateway-thirdparty-api`
- Skill folder · `gatewayapi_backendapi_by_tnh/` → `gateway-thirdparty-api/`
- Skill identifier · `sa-spec-dev-handoff` → `gateway-thirdparty-api`
- Subfolder · `references/` → `template_document/`

**ปรับ path ของ skill ให้ตรง vault convention:**

- `sa_output_spec/{project}/` → `Projects/{product}/specs/{feature}/`
- root `source_program/` → `reference_data/source_program/`
- root `old_spec_document/` → `reference_data/document_spec/` (merge เข้าด้วยกัน)

**Skill ที่กระทบ** — `gateway-thirdparty-api`
**ต้อง action** — ทีมต้องเรียก agent ด้วยชื่อใหม่ · ชื่อเดิม `spec-dev-handoff` ใช้ไม่ได้แล้ว
**โดย** — พี่ตูน (TNH · NXT)

</details>

<details class="changelog__item" markdown>
<summary><span class="changelog__time">14:55</span> จัดโครงสร้างใหม่ · <code>ProgramType_Skills/</code> + <code>reference_data/</code></summary>

ย้าย SA Skills ขึ้น top-level: `Projects/sa-work-with-ai/` (57 ไฟล์) ขึ้นมาเป็น `ProgramType_Skills/` · เพิ่ม `reference_data/` ที่ root พร้อม 4 subfolders (`db_schema`, `dev_wiki`, `document_spec`, `source_program`) สำหรับเก็บข้อมูล reference ของทีม แยกจาก spec ของ product

Auto-sync workflow ขยาย scope ดึง `ProgramType_Skills/` เพิ่มเข้ามาด้วย → SA Skills flow จาก upstream ไปทีมอัตโนมัติ

**Skills ที่กระทบ** — Backend Services, SA API, Report, gateway-thirdparty-api
**โดย** — พี่ตูน (TNH · NXT)

</details>

<details class="changelog__item" markdown>
<summary><span class="changelog__time">13:22</span> Auto-sync system · <code>sync-skills.yml</code></summary>

ระบบ sync 3 ชั้น · ทีมไม่ต้อง `git pull` เองอีกต่อไป

- **GitHub Action** — cron `30 0 * * *` UTC = 07:30 ICT รายวัน
- **Claude SessionStart hook** — `git pull` ตอนเปิด Claude · throttle 6 ชม.
- **Manual scripts** — `scripts/sync-skills.sh` + `.ps1` สั่งเองได้ทุกเมื่อ

Sync เฉพาะ: `.claude/agents/` + `.claude/skills/` + `ProgramType_Skills/`
ไม่แตะ: `Memory/`, `Projects/`, `reference_data/`, `Tech/`, `MOC/`, `Templates/`

**Skills ที่กระทบ** — ทุก agent และทุก skill (sync เป็น global mechanism)
**โดย** — พี (LOL)

</details>

<details class="changelog__item" markdown>
<summary><span class="changelog__time">13:30 – 14:37</span> แก้บัค render หน้าเว็บ</summary>

Debug 4 รอบกับบัค pymdownx code fence ใน `auto-sync.md`

- Backtick fences (` ```bash `) → silent fail (กลายเป็น inline)
- Tilde fences (`~~~bash`) → ก็ fail
- 4-space indent → crash build (Pygments + Python 3.11 ไม่ compatible)
- Raw HTML `<pre><code>` → ใช้ได้

Convention ใหม่: docs site ที่ต้องการ code block ที่ไม่ใช่ `mermaid` ให้ใช้ raw HTML `<pre><code>` แทน · ไม่กระทบ vault content

**Skills ที่กระทบ** — ไม่มี (docs site bug เท่านั้น)

</details>

</div>

## 2026-05-19

<div class="changelog" markdown>

<details class="changelog__item" markdown>
<summary><span class="changelog__time">—</span> Knowledge system v1 เปิดตัว</summary>

Release แรกของ SA Knowledge System template

**Agents (15 ตัว ใน `.claude/agents/`)** — spec-writer, spec-dev-handoff, spec-ui-designer, spec-api-designer, spec-backend-service, spec-report-designer, spec-reviewer, spec-tester, kb-assistant, indexer, decision-keeper, session-logger, doc-to-vault, db-schema-documenter, skill-to-agent

**Claude skills (13 ตัว ใน `.claude/skills/`)** — PDF, DOCX, XLSX, PPTX, json-canvas, obsidian-bases, obsidian-cli, obsidian-markdown, brand-guidelines, defuddle, doc-coauthoring, frontend-design, skill-creator

**SA Skills (4 ตัว ใน `Projects/sa-work-with-ai/`)** — Backend Services, SA API, Report, gatewayapi_backendapi_by_tnh *(ต่อมาย้ายขึ้น top-level + rename เป็น `gateway-thirdparty-api`)*

**ระบบ** — Memory system, ADR log, Indexer agent, Context7 MCP, Bootstrap scripts (`bootstrap.sh` + `.ps1`), MkDocs site + GitHub Pages auto-deploy, 33 reference templates

**โดย** — Theerapong (vault author)

</details>

</div>
