---
title: Skills & MCP Installed (Phase 1)
date: 2026-05-18
owner: Zayn (ice1@freewillsolutions.com)
tags: [sop, claude-code, skills, mcp]
agent_used: manual
---

# Skills & MCP Installed — Phase 1

> ลง skill + MCP ที่จำเป็นสำหรับ SA workflow ของ ICE-Gold KB
> ติดตั้งที่ `team-kb-template/.claude/skills/` และ mirror ไป `ICE-Gold/.claude/skills/`

## When to use this
- เมื่ออยากรู้ว่ามี skill อะไรพร้อมใช้
- เมื่อต้อง onboard SA Lead ใหม่ + บอกว่า KB มี capability อะไรเสริม
- เมื่อต้อง sync skills ระหว่าง template ↔ project repo

## 📦 Skills ที่ติดตั้งแล้ว (13 ตัว)

### Document & Office (จาก official Anthropic) — 4 ตัว
| Skill | Path | ใช้กับงาน |
|---|---|---|
| `pdf` | `.claude/skills/pdf/` | อ่าน/ดึงข้อมูลจาก spec PDF, regulatory docs, vendor specs |
| `xlsx` | `.claude/skills/xlsx/` | data mapping, field dictionary, test matrix ของ GPP |
| `docx` | `.claude/skills/docx/` | ส่ง spec ออกในรูป Word ให้ Dev/QA/Business |
| `pptx` | `.claude/skills/pptx/` | สร้าง slide deck สรุป architecture/handoff |
| `doc-coauthoring` | `.claude/skills/doc-coauthoring/` | collaborative writing แบบ Claude + human |

### Design (จาก official Anthropic) — 2 ตัว
| Skill | Path | ใช้กับงาน |
|---|---|---|
| `frontend-design` | `.claude/skills/frontend-design/` | เสริม `spec-ui-designer` agent — design system, ไม่ "AI slop" |
| `brand-guidelines` | `.claude/skills/brand-guidelines/` | encode ICE-Gold writing style → ทุก agent output สม่ำเสมอ |

### Meta (จาก official Anthropic) — 1 ตัว
| Skill | Path | ใช้กับงาน |
|---|---|---|
| `skill-creator` | `.claude/skills/skill-creator/` | สร้าง custom skill เฉพาะทีม (เช่น "SCB integration template") |

### Obsidian (จาก kepano/obsidian-skills) — 5 ตัว
| Skill | Path | ใช้กับงาน |
|---|---|---|
| `obsidian-markdown` | `.claude/skills/obsidian-markdown/` | จัดการ Markdown + wikilinks + frontmatter ตาม Obsidian convention |
| `obsidian-bases` | `.claude/skills/obsidian-bases/` | จัดการ Obsidian Bases (database-like views) |
| `obsidian-cli` | `.claude/skills/obsidian-cli/` | สั่งงาน Obsidian จาก CLI |
| `json-canvas` | `.claude/skills/json-canvas/` | สร้าง/แก้ JSON Canvas (visual maps ของ MOC) |
| `defuddle` | `.claude/skills/defuddle/` | clean web pages → markdown ใส่ vault |

## 🔗 MCP Servers ที่ติดตั้งแล้ว

### Context7
- **Config**: `.mcp.json` ที่ root ของแต่ละ repo (`team-kb-template/`, `ICE-Gold/`)
- **ใช้กับงาน**: เวลา agent (spec-api-designer, spec-backend-service) อ้างถึง library/API → Context7 inject docs จริง ไม่ hallucinate
- **วิธีใช้**: เติม `use context7` ใน prompt หรือ agent จะเรียกอัตโนมัติเมื่อต้อง resolve library

```json
{
  "mcpServers": {
    "context7": {
      "type": "http",
      "url": "https://mcp.context7.com/mcp"
    }
  }
}
```

## ⚠️ MCP ที่ต้องตั้งค่าเพิ่มเอง (ต้องการ API key)

### Tavily (search engine for AI)
1. สมัครที่ https://tavily.com → get API key (ฟรี 1000 calls/month)
2. เพิ่มใน `.mcp.json`:
```json
"tavily": {
  "command": "npx",
  "args": ["-y", "tavily-mcp@latest"],
  "env": { "TAVILY_API_KEY": "tvly-xxxxx" }
}
```
3. ใช้สำหรับ: research feature/competitor/regulatory เวลาเริ่ม spec product ใหม่ (SBA, IFIS placeholder)

## 🎯 ตัวอย่าง prompt ที่ใช้ skills ใหม่

```
# import spec จาก PDF
> อ่านไฟล์ Projects/GOLDPORTPLUS/references/scb-spec.pdf
  แล้วสรุป endpoint ทั้งหมดเป็น Markdown table

# ส่ง Excel data dictionary
> สร้าง XLSX จาก field mapping ใน
  Projects/GOLDPORTPLUS/front2-scb/export-eod-scb.md

# สร้าง custom skill
> Use skill-creator: ทำ skill ชื่อ "scb-integration-checklist"
  สำหรับ review spec ก่อน handoff

# Context7 ใน spec
> Use the spec-api-designer agent: ออกแบบ REST API
  สำหรับ GPP front1 ตาม Spring Boot 3.x conventions use context7
```

## 🔄 Sync ระหว่าง template ↔ project

Skills ถูก install ที่ template เป็นหลัก แล้ว mirror ไป ICE-Gold

```bash
# จาก template → ICE-Gold (ปกติทำเมื่อ template อัปเดต)
cd ICE-Gold
git fetch upstream
git merge upstream/main
```

## 📁 โครงสร้างปัจจุบัน

```
team-kb-template/
├── .mcp.json                          ← NEW: Context7 config
└── .claude/
    └── skills/                         ← NEW
        ├── pdf/         ├── docx/      ├── xlsx/
        ├── pptx/        ├── doc-coauthoring/
        ├── frontend-design/  ├── brand-guidelines/
        ├── skill-creator/
        ├── obsidian-markdown/  ├── obsidian-bases/
        ├── obsidian-cli/   ├── json-canvas/  └── defuddle/

ICE-Gold/
├── .mcp.json                          ← NEW: mirror
└── .claude/
    └── skills/                         ← NEW: mirror of template
        └── (same 13 skills)
```

## ❓ Troubleshooting

- **Skill ไม่ถูกเรียก** → restart Claude Code session
- **Context7 ไม่ทำงาน** → check internet, ลอง `claude mcp list` เพื่อดูสถานะ
- **อยาก uninstall skill** → ลบ folder นั้นใน `.claude/skills/`
