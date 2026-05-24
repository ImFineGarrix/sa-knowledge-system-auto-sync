---
title: "SA Member Onboarding — Claude Desktop + Vault (read-only)"
date: 2026-05-05
tags: [sop, "#tech/sop", "#team/onboarding", "#claude-desktop"]
status: active
owner: "Zayn (ice1@freewillsolutions.com)"
audience: "SA Members (20+ users, read-only access)"
---

# SA Member Onboarding — Claude Desktop + Vault (Read-only)

## When to use this
ใช้ทุกครั้งที่ SA Member ใหม่ต้องการเข้าถึง vault และใช้ AI agents — ผ่าน **Claude Desktop App + MCP filesystem** (ไม่ใช่ CLI)

**สำหรับ SA Lead:** ใช้ [[Tech/SOP/team-onboarding-claude-code]] แทน (ต้อง CLI สำหรับ maintain agents/skills)

## Prerequisites
- Claude Team Pro seat (admin เพิ่ม member ก่อน)
- GitHub access — Read role on team-kb repo (admin เพิ่มก่อน)
- เครื่องคอมเป็น **macOS / Windows**
- Internet stable

## Steps

### Step 1 — ติดตั้ง Claude Desktop (5 นาที)

1. ไปที่ **https://claude.ai/download**
2. Download installer ตาม OS
3. Install + เปิด app
4. **Login** ด้วย email Team Pro
5. ตรวจสอบ: เห็น avatar + plan = "Team" ที่มุม

### Step 2 — Clone vault repo (read-only) (3 นาที)

ติดตั้ง Git ถ้ายังไม่มี:
- macOS: `brew install git` หรือ Xcode Command Line Tools
- Windows: https://git-scm.com/download/win

```bash
# Clone (ครั้งเดียว)
cd ~                                   # หรือ folder ที่ต้องการ
git clone <vault-repo-url> team-kb
cd team-kb
ls
# ควรเห็น: CLAUDE.md, .claude/, MOC/, Projects/, ...
```

> **หมายเหตุ:** GitHub role ของคุณคือ Read — clone และ pull ได้, push ไม่ได้
> ถ้าอยากเสนอแก้ → ส่ง draft ให้ SA Lead

### Step 3 — Setup MCP filesystem ใน Claude Desktop (5 นาที)

หา config file ตาม OS:

**macOS:**
```
~/Library/Application Support/Claude/claude_desktop_config.json
```

**Windows:**
```
%APPDATA%\Claude\claude_desktop_config.json
```

ถ้าไม่มี — สร้างใหม่ ใส่เนื้อหานี้:

```json
{
  "mcpServers": {
    "team-kb": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/Users/YOUR_USERNAME/team-kb"
      ]
    }
  }
}
```

⚠️ **เปลี่ยน path:**
- **macOS:** `/Users/YOUR_USERNAME/team-kb`
- **Windows:** `C:\\Users\\YOUR_USERNAME\\team-kb` (ใช้ `\\` เป็น separator)

ถ้ายังไม่มี Node.js → ลงก่อน:
- https://nodejs.org → Download LTS

### Step 4 — Restart Claude Desktop + ทดสอบ (2 นาที)

1. **Quit Claude Desktop** ทั้งหมด (ไม่ใช่แค่ปิดหน้าต่าง)
2. เปิดใหม่
3. New chat → พิมพ์:
   ```
   List files in the team-kb folder
   ```
4. Claude ควรตอบโดยใช้ filesystem tool และเห็น CLAUDE.md, MOC/, Projects/, ...
5. ถ้าไม่เห็น filesystem tool icon → config ไม่ถูก ตรวจ path อีกครั้ง

### Step 5 — ทดสอบเรียก agent (3 นาที)

ใน Claude Desktop chat:

```
อ่าน CLAUDE.md และ Projects/_meta/architecture-decisions.md
ก่อน แล้วช่วยสรุปว่า vault นี้ทำอะไร
```

→ Claude อ่าน file ผ่าน MCP → ตอบจาก content จริง

ทดสอบเรียก spec-writer:
```
อ่าน .claude/agents/spec-writer.md แล้วทำตาม instructions
ของ agent นั้น — ฉันต้องการออก spec API สำหรับ ...
```

> **หมายเหตุสำคัญ:** Claude Desktop **ไม่ auto-trigger** sub-agents เหมือน Claude Code CLI
> ต้อง prompt ให้อ่าน agent file ก่อน หรือ paste instructions เองก็ได้

### Step 6 — Workflow ประจำวัน

**เริ่มวัน:**
```bash
cd ~/team-kb
git pull              # รับ skills/docs ล่าสุดจาก Lead
```

จากนั้นเปิด Claude Desktop → ทำงานปกติ

**กลางวัน:**
- ออก spec → drag รูป mockup เข้า chat → ขอให้ใช้ spec-writer agent
- ค้นข้อมูล → ขอให้อ่าน `.index/master-index.md` ก่อน
- ดู context project → ขอให้อ่าน `Projects/_meta/architecture-decisions.md`

**จบวัน:**
- ไม่ต้อง commit/push (read-only)
- ถ้ามี draft ใหม่ที่อยากเข้า vault → ส่งให้ SA Lead

## Tips การใช้งาน Claude Desktop กับ vault

### 1. Custom System Prompt (ครั้งเดียว ใน Project)
สร้าง Claude.ai Project ใหม่ ชื่อ "Team KB" → ใส่ Project Instructions:

```
You have access to the team-kb folder via MCP filesystem.

Always:
1. Read .index/master-index.md first to find relevant notes
2. Read Projects/_meta/architecture-decisions.md to know project context
3. Cite source notes by filename in answers (e.g. "From [[Projects/gpp/overview]]...")
4. Never invent information not in the vault
5. When user wants to write a spec, follow .claude/agents/spec-writer.md instructions

Language: ตอบเป็นภาษาไทย ยกเว้น technical term / code / filename
```

→ ทุก chat ใน project นี้จะมี context อัตโนมัติ

### 2. แนบรูป
- Drag & drop ลง chat box ตรงๆ
- หรือ paste จาก clipboard (Cmd/Ctrl+V)
- รองรับ PNG, JPG, PDF, screenshots

### 3. ดูงานเก่า
- Sidebar → เห็น chat history
- Search ทุก chat ใน app
- ใช้ Star/Pin chat ที่สำคัญ

### 4. Mobile
- Download Claude app บน iOS/Android
- Login Team Pro account เดียวกัน
- ดู conversation เก่าได้ + chat ต่อได้
- ❌ ไม่มี filesystem access (Mobile ไม่รองรับ MCP)

## Common pitfalls

- **MCP filesystem ไม่ทำงาน** — เช็ค path ใน config + restart Claude Desktop ทั้งหมด (Quit ไม่ใช่แค่ปิด window)
- **เห็นแค่ folder บางส่วน** — MCP กำหนด root folder ใน config, sub-folder จะเข้าถึงได้อัตโนมัติ
- **Push ไม่ได้** — ปกติ — คุณเป็น Read role; ส่ง draft ให้ SA Lead แทน
- **Agent ไม่ทำงาน** — Claude Desktop ไม่ auto-trigger; ต้อง prompt ให้อ่าน agent file หรือ paste instructions
- **vault outdated** — ลืม `git pull` วันนั้น → ข้อมูลเก่า; รัน pull ก่อนเริ่มงาน
- **แชร์ chat กับทีม** — ผ่าน Cowork (ใน Claude Desktop / Claude.ai)

## Related
- [[Tech/SOP/team-onboarding-claude-code]] — สำหรับ SA Lead (ใช้ CLI)
- [[Projects/_meta/architecture-decisions]] — context ของ vault
- [[CLAUDE]] — vault rules
- [[.claude/agents/spec-writer]] — main agent ของ SA
