---
title: "Sync from team-kb-template"
date: 2026-05-06
tags: [sop, "#tech/sop", "#multi-repo"]
status: active
owner: "Zayn (ice1@freewillsolutions.com)"
audience: "SA Lead in each project repo"
---

# Sync from team-kb-template

## When to use this
ใช้เมื่อ template repo (`team-kb-template`) มี update — agents ใหม่, skills เปลี่ยน, SOP เพิ่ม → project repo ต้อง pull เข้ามา

## Prerequisites
- โปรเจค repo ของคุณ (e.g. `ICE-Gold`) clone จาก template มาแล้ว
- มี Git remote `upstream` ชี้ไป template repo
- คุณคือ SA Lead (มีสิทธิ์ push ใน project repo)

## Steps

### Step 1 — เช็คว่ามี upstream remote
```bash
cd ~/ICE-Gold
git remote -v
```
ควรเห็น:
```
origin    <your-project-repo-url> (fetch)
origin    <your-project-repo-url> (push)
upstream  <template-repo-url>     (fetch)
upstream  <template-repo-url>     (push)
```

ถ้าไม่มี upstream → เพิ่ม:
```bash
git remote add upstream <template-repo-url>
```

### Step 2 — Fetch updates จาก template
```bash
git fetch upstream
git log upstream/main --oneline -10   # ดูว่ามี commit อะไรใหม่
```

### Step 3 — Merge เข้า project repo
```bash
git checkout main
git merge upstream/main
```

ถ้ามี **merge conflict** — ปกติเกิดเฉพาะถ้าแก้ shared files ใน project repo (ไม่ควรทำ)
แก้ conflict → favor upstream version สำหรับ shared files

### Step 4 — Test ก่อน push
```bash
# ทดสอบว่า agents ยังใช้ได้
claude
> Use the kb-assistant agent: vault นี้มีอะไรบ้าง
```

### Step 5 — Push
```bash
git push origin main
```

### Step 6 — แจ้งทีม
- Slack: "Synced template updates ลง ICE-Gold แล้ว — สมาชิก git pull"
- ทีม: `git pull` ก่อนเริ่มงาน

## Common pitfalls

- **Conflict ใน `.claude/agents/`** — ห้ามแก้ในนี้ที่ project repo; ถ้าต้องแก้ → PR ที่ template repo แทน
- **Conflict ใน `ProgramType_Skills/`** — เหมือนข้อบน
- **`.index/` conflict** — ลบ + รัน `Use the indexer agent to refresh index`
- **Memory/sessions/ conflict** — แทบจะไม่เกิด (template มีแค่โครงเปล่า)
- **Forgot to fetch upstream first** → push ไม่ได้

## What stays in your project repo (NOT synced from template)
- `Projects/<your-products>/` (เช่น `Projects/GOLDPORTPLUS/`)
- `Memory/sessions/YYYY-MM-DD.md`
- `Memory/summary.md` (project-specific rolling summary)
- Any project-specific ADRs in `Projects/_meta/architecture-decisions.md`

## Related
- [[CLAUDE]] — vault rules
- [[Tech/SOP/team-onboarding-claude-code]]
- [[Tech/SOP/team-onboarding-claude-desktop]]
