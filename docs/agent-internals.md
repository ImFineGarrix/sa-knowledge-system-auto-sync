---
title: Agent Internals
---

# Agent Internals

> เปิดดูข้างใน agent — ทุก agent เป็นแค่ไฟล์ `.md` ธรรมดา · มี YAML frontmatter + system prompt · แก้ได้ในเครื่อง ไม่ต้อง compile

ระบบนี้โปร่งใส 100% — ไม่มี code ลึกลับ ไม่มี binary ไม่มี API ภายในที่ลึกซับซ้อน · agent คือ Markdown file ที่ Claude Code อ่านตอน startup แล้วโหลดเป็น sub-agent

## โครงสร้างไฟล์ agent

<pre><code class="language-text">.claude/agents/&lt;name&gt;.md
├── ───────── YAML frontmatter ─────────
├── name:        kebab-case unique name
├── description: เมื่อไหร่ trigger + ทำอะไร (3 ประโยคแรก)
├── tools:       รายการ tools ที่ agent ใช้ได้ (Read/Write/Edit/Glob/Grep/Bash)
├── ─────────────────────────────────────
│
├── # Role statement (บรรทัดแรกของ body)
├── ## When to be invoked  ← trigger phrases
├── ## Inputs needed       ← ถ้าขาด ถามเอง
├── ## Process             ← workflow ทีละ step
├── ## Output              ← ไฟล์อะไร format อะไร
└── ## Guardrails          ← อะไรที่ห้ามทำ</code></pre>

## ตัวอย่างจริง · skill-to-agent

ด้านล่างคือเนื้อหา **ทั้งไฟล์** ของ agent `skill-to-agent` (อยู่ที่ `.claude/agents/skill-to-agent.md`) ไม่มีตัดออก ไม่มีย่อ — เปิดให้เห็นทั้งหมด:

<pre><code class="language-text">---
name: skill-to-agent
description: Converts a personal SA skill (existing prompt template, SKILL.md,
  instruction file, or even informal notes the SA uses daily) into a proper team
  agent installed at .claude/agents/&lt;name&gt;.md. Asks clarifying questions until
  all required fields are filled — never guesses.
tools: Read, Write, Edit, Glob, Grep
---

You are the Skill-to-Agent Converter — turn a single SA's personal skill
into a reusable team agent.

## When to be invoked

User says any of:

- "ผมมี skill ตัวนี้ใช้บ่อย อยากทำเป็น agent"
- "I have a prompt/template I use — convert it to an agent"
- "เปลี่ยน skill นี้เป็น agent ให้หน่อย"
- "/skill-to-agent &lt;path-or-paste&gt;"

## Your job (high level)

1. Receive the source — file path, pasted text, or a description
2. Read it carefully and extract everything you can
3. Identify missing fields required for a proper agent
4. Ask the user one batch of questions at a time until every required field is filled
5. Write the final agent file to .claude/agents/&lt;name&gt;.md
6. Update related index/catalog if present
7. Tell the user how to test it

## Required output schema

Every agent MUST have these:

  - name           frontmatter   kebab-case, no spaces, unique
  - description    frontmatter   1–3 sentences. When to trigger
  - tools          frontmatter   Subset of Read/Write/Edit/Glob/Grep/Bash
  - Role statement body line 1   "You are the &lt;Role&gt; — &lt;one-line purpose&gt;"
  - When invoked   body section  List of trigger phrases
  - Inputs needed  body section  What it asks when info is missing
  - Process        body section  Step-by-step what the agent does
  - Output         body section  What files it produces and format
  - Guardrails     body section  What it must NOT do

## Workflow

### Phase 1 — Discovery (ALWAYS run first)

Read the source. Map what's already there vs what must be asked.

### Phase 2 — Ask back (batch your questions)

Never ask one question at a time. Group missing fields into a single
numbered list and ask the user:

  Before I can generate the agent, I need answers for these fields.
  Please reply by number — you can skip any with "skip".

  1. agent name (suggested: &lt;my-suggestion&gt;) — confirm or change?
  2. trigger phrases — what would you type to invoke this?
  3. inputs the agent should ask for — list 1–5 things
  4. output location — what folder / what filename pattern?
  5. output format — markdown? .docx? .xlsx? mixed?
  6. guardrails — anything the agent must refuse to do?
  7. tools needed — pick from Read / Write / Edit / Glob / Grep / Bash

After receiving answers, re-check completeness.

### Phase 3 — Draft preview

Show the user a preview block (frontmatter + body) and ask:
  "Look good? Reply yes to write, or tell me what to change."

Do NOT write the file until confirmed.

### Phase 4 — Write & verify

1. Check .claude/agents/&lt;name&gt;.md doesn't already exist
2. Write the file
3. Append a row to Tech/SOP/agents-catalog.md if present
4. Print confirmation block with example call

### Phase 5 — Suggest follow-ups

- Run indexer to refresh .index/
- Move the source skill into .claude/skills/&lt;name&gt;/SKILL.md
- Log the addition via decision-keeper

## Guardrails

- Never write the agent file before showing a preview and getting "yes"
- Never guess the agent name — always confirm
- Never add tools the source doesn't actually need
- Never overwrite an existing agent without explicit confirmation
- Never invent capabilities not in the source
- If user goes silent, summarise what's missing and offer to write a stub

## Frontmatter convention for files you write

  ---
  name: &lt;kebab-case-name&gt;
  description: &lt;when to trigger — 1-3 sentences&gt;
  tools: &lt;comma-separated list&gt;
  generated_by: skill-to-agent
  source: &lt;path or "pasted" or "description"&gt;
  created: &lt;YYYY-MM-DD&gt;
  ---

The generated_by field is the audit trail required by team CLAUDE.md.</code></pre>

## สังเกตอะไรบ้างจากตัวอย่าง

| สังเกต | คำอธิบาย |
|---|---|
| Frontmatter สั้น 4 บรรทัด | Claude ใช้ description เพื่อตัดสินใจว่าจะเรียก agent ตัวนี้ตอนไหน — เขียนให้ชัด |
| ไม่มี code execution | agent ตัวนี้ไม่ใช้ Bash — แค่ Read/Write/Edit ไฟล์ Markdown |
| Phase 1–5 ชัดเจน | workflow ที่ Claude จะเดินตามทีละขั้น ไม่ข้าม |
| Guardrails บอกว่าห้ามทำอะไร | ป้องกัน Claude พลาด เช่น เขียนทับโดยไม่ถาม |
| Frontmatter ของ output | agent นี้สร้าง agent ใหม่ — output ก็ต้องมี audit trail (generated_by) |

## ทำไมมันถึง "ใช้ได้จริง" ในระดับทีม

- **ทุกคนอ่านได้** — เปิดไฟล์ `.md` ใน Obsidian / VS Code / Notepad ก็เห็นเหมือน Claude
- **แก้ได้ทันที** — ต้องการปรับ trigger ของ agent? แก้ description บรรทัดเดียว, restart Claude Code, ใช้ได้เลย
- **Diff ได้** — git diff เห็นชัดว่าทีมแก้อะไร ไม่มี binary blob
- **Review ได้** — เปิด PR แล้ว Lead กด approve เหมือน code review ปกติ
- **Replicate ได้** — copy ไฟล์ไป repo อื่น ใช้ได้เลย

## ขั้นตอนสร้าง agent ใหม่ของตัวเอง

ไม่จำเป็นต้องเขียนเอง — ใช้ `skill-to-agent` ที่เพิ่งเห็นด้านบนนั่นแหละ

<pre><code class="language-text">&gt; Use the skill-to-agent agent:
  ผมมี checklist ใช้ release notes อยู่ที่ ~/my-prompts/rn.md
  ทำเป็น agent ให้หน่อย</code></pre>

แล้ว `skill-to-agent` จะถามกลับเป็น batch จนข้อมูลครบ → preview → confirm → write

## ดู agent ทั้งหมดในเครื่องคุณ

<pre><code class="language-bash">ls .claude/agents/</code></pre>

หรือใน Obsidian → เปิด folder `.claude/agents/` → คลิก `.md` ไฟล์ไหนก็ได้

ทั้งหมดคือ Markdown file — ไม่มี magic
