---
title: "Team Member Onboarding — Claude Code + Vault"
date: 2026-05-05
tags: [sop, "#tech/sop", "#team/onboarding"]
status: active
owner: "Zayn (ice1@freewillsolutions.com)"
---

# Team Member Onboarding — Claude Code + Vault

## When to use this
ใช้ทุกครั้งที่มีสมาชิกใหม่เข้าทีมและต้องการเข้าถึง knowledge base — ทำให้ทุกคนได้ environment เดียวกัน, ใช้ agents ชุดเดียวกัน, และ commit ลง vault ได้ภายในชั่วโมงแรก

## Prerequisites
- สมาชิกมี **Claude Team Pro seat** อยู่แล้ว (admin เพิ่ม member ก่อน)
- มีสิทธิ์เข้า Git repo ของ vault (ถ้า push ขึ้น GitHub แล้ว)
- เครื่องคอมเป็น **macOS / Linux / Windows + WSL หรือ Git Bash**
- Internet stable
- มีบัญชี GitHub (ถ้า vault ขึ้น GitHub แล้ว)

## Steps

### Step 1 — ติดตั้ง prerequisites (5-10 นาที)

**Node.js (≥ v18):**
```bash
# macOS (Homebrew)
brew install node

# Windows
# ดาวน์โหลด installer จาก https://nodejs.org

# Linux
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
```

ตรวจสอบ:
```bash
node --version   # ควรเป็น v18.x ขึ้นไป
npm --version
```

**Git:**
```bash
git --version    # ถ้าไม่มี ลงจาก https://git-scm.com
```

**(แนะนำ) Obsidian:**
- ดาวน์โหลดจาก https://obsidian.md
- ติดตั้งแต่ยังไม่ต้องเปิด vault

### Step 2 — ติดตั้ง Claude Code (2 นาที)

```bash
npm install -g @anthropic-ai/claude-code
```

ตรวจสอบ:
```bash
claude --version
```

### Step 3 — Login Team Pro (1 นาที)

```bash
claude /login
```

- Browser จะเปิดอัตโนมัติ
- Login ด้วย email ของ Team Pro account
- Authorize → กลับมาที่ terminal

ตรวจสอบ status:
```bash
claude /status
```

ควรเห็น account email + plan = "Team"

### Step 4 — Clone vault (1 นาที)

**ถ้า vault อยู่บน GitHub:**
```bash
cd ~                                          # หรือ folder ที่ต้องการ
git clone <vault-repo-url> team-kb
cd team-kb
```

**ถ้ายังเป็น local-only (ขอจาก team lead):**
- รับ vault zip / shared folder จาก team lead
- Extract เป็น `~/team-kb`
- ทำ git remote init ตามที่ team lead แนะนำ

ตรวจสอบไฟล์:
```bash
ls -la
# ควรเห็น: CLAUDE.md, .claude/, MOC/, Tech/, Templates/, .index/, etc.
```

### Step 5 — เปิด vault ใน Obsidian (2 นาที)

1. เปิด Obsidian app
2. Click **"Open folder as vault"**
3. เลือก folder `~/team-kb`
4. กด **Trust author and enable plugins** (ถ้าถาม)

ทดสอบ: เปิด `MOC/index.md` — ควรเห็น wikilinks render สวยงาม

### Step 6 — เปิด Claude Code ใน vault (1 นาที)

```bash
cd ~/team-kb
claude
```

Claude Code จะอ่าน `CLAUDE.md` อัตโนมัติ → รู้ rules ของ vault

ทดสอบด้วยคำถามแรก:
```
Use the kb-assistant agent: เรามี SOP อะไรบ้างใน vault
```

ถ้าได้คำตอบที่อ้างอิง `[[Tech/SOP/client-onboarding]]` แสดงว่า setup ถูกต้อง

### Step 7 — เรียนรู้ agents (10 นาที)

อ่านรายชื่อ agents และวิธีเรียกใช้:
```bash
ls .claude/agents/
```

**12 agents แบ่งเป็น 4 กลุ่ม:**

| กลุ่ม | Agents |
|---|---|
| Core | kb-assistant, note-writer, researcher, indexer |
| Workflow | daily-summarizer, organizer, meeting-notes-parser |
| Consulting | client-onboarder, proposal-drafter, project-tracker |
| Quality | sop-reviewer, link-checker |

อ่าน 1-2 ตัวที่จะใช้บ่อย เช่น:
```bash
cat .claude/agents/kb-assistant.md
cat .claude/agents/note-writer.md
```

### Step 8 — ทำ first contribution (15 นาที)

**สร้าง daily note แรก:**
```
Use the meeting-notes-parser agent to create today's daily note
[paste raw meeting notes ที่มี]
```

**Commit งาน:**
```bash
git add .
git diff --staged --stat              # ตรวจก่อน commit
git commit -m "daily: 2026-05-05 — first day"
git push                               # ถ้ามี remote
```

### Step 9 — Setup daily routine

**เริ่มวัน:**
```bash
cd ~/team-kb
git pull                               # ดึงงานล่าสุดจากทีม
claude
> Use the project-tracker agent: ดูสถานะโปรเจกต์ทั้งหมด
```

**ระหว่างวัน:**
- เจอข้อมูลสำคัญ → `Use note-writer agent`
- ต้องการสรุป meeting → `Use meeting-notes-parser`
- ค้นข้อมูลใหม่ → `Use researcher agent`

**จบวัน:**
```
Use the indexer agent to refresh index
```
```bash
git add . && git commit -m "daily: $(date +%Y-%m-%d)"
git push
```

## Common pitfalls

- **ลืม `cd ~/team-kb` ก่อนรัน `claude`** — Claude Code จะไม่อ่าน CLAUDE.md ของ vault → ใช้ agents ของ vault ไม่ได้
  - แก้: ตั้ง alias หรือใช้ shell ที่จำ working dir ได้

- **`git pull` แล้ว conflict** — ทีมแก้ไฟล์เดียวกันพร้อมกัน
  - แก้: pull บ่อยๆ ก่อนเริ่มแก้, สื่อสารกันใน Slack เรื่องที่จะแก้

- **ลืม refresh `.index/` หลังเพิ่ม note** — agents ค้นหาไม่เจอ note ใหม่
  - แก้: รัน `Use indexer agent` หลังเพิ่ม/แก้ notes

- **ใช้ Claude Code นอก vault** — agents ของ vault จะไม่โหลด เพราะ `.claude/` อยู่ใน folder อื่น
  - แก้: เช็ค working directory ด้วย `pwd`

- **Commit ไฟล์ที่มี secrets** — เช่น API key, credentials
  - แก้: ตรวจ `git diff --staged` ทุกครั้งก่อน commit, เพิ่ม pattern ลง `.gitignore`

- **สมาชิกใหม่หา agents ไม่เจอ** — ลืมว่ามีอะไรบ้าง
  - แก้: เก็บ cheatsheet ไว้ใน `MOC/agents.md` หรือ pin ใน Slack

## Related
- [[CLAUDE]] — vault rules ที่ Claude Code อ่านอัตโนมัติ
- [[Tech/SOP/client-onboarding]] — SOP ตัวอย่าง
- [[MOC/index]] — Map of Content หลัก
