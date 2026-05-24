---
title: "Skill Contribution Workflow — Planning Doc"
date: 2026-05-20
tags: [planning, governance, contribution, skill-management]
status: draft
owner: "Theerapong (admin)"
audience: "admin (Theerapong) · ใช้อ่านเตรียมตัวก่อน implement"
---

# Skill Contribution Workflow — Planning

> Draft planning doc · **ยังไม่ได้ทำ** · ไว้อ่านตอนว่างเพื่อตัดสินใจก่อน implement

---

## ปัญหาที่ต้องการแก้

ตอนนี้ workflow เป็น manual:

1. Lead (1 ใน 7 คน) ส่ง skill ใหม่/อัปเดต skill เดิม
2. Admin (Theerapong) ต้องทำเองทั้งหมด:
   - แปลง skill → wrapper agent ใน `.claude/agents/`
   - Update `ProgramType_Skills/overview.md`
   - Update `docs/skills.md`
   - Update `.index/master-index.md` (run indexer)
   - Update cross-refs ในไฟล์อื่นๆ ที่ refs skill เดิม
   - Update changelog

**Pain:** scale ไม่ออก ถ้า 7 Leads อัปเดต skill บ่อย · admin คอขวด · cross-refs ตกหล่นง่าย → performance แย่ (agent ชี้ path ผิด)

---

## เป้าหมาย

- Lead รัน/commit อะไรสักอย่าง → cascade updates เด้งตามอัตโนมัติ
- Admin (Theerapong) แค่ review PR + merge
- ไม่มี cross-ref ตกหล่น
- Onboarding Lead ใหม่ทำได้ใน 5 นาที (แค่ commit + PR)

---

## Cascade ที่ต้องเกิดทุกครั้งที่ skill เปลี่ยน

```
Skill upgrade ใน ProgramType_Skills/<X>/
        │
        ├─ .claude/agents/<wrapper>.md    ← path refs · description
        ├─ ProgramType_Skills/overview.md ← skill list entry
        ├─ .index/master-index.md         ← indexer regenerate
        ├─ MOC/index.md                   ← ถ้ามี link
        ├─ docs/skills.md                 ← presentation site
        └─ ไฟล์อื่นที่ refs ถึง skill name/path (grep หาทั่ว repo)
```

---

## Access Strategy · Collaborator + Branch Protection

### โมเดล

```
Main branch (protected)
  - Required PR review (admin = Theerapong)
  - Required CI checks pass
  - No direct push · no force push · no deletion

7 Leads = Collaborator (Write/push permission)
  - push branch อะไรก็ได้
  - เปิด PR · comment · review
  - แต่ merge เข้า main ไม่ได้
```

### ทำไม Collaborator > Fork

- Lead ไม่ต้อง sync fork ตลอด
- Bot workflow ใช้ `GITHUB_TOKEN` ได้เลย (มี write บน same repo)
- PR conversation centralized

### ทำไม Branch Protection สำคัญ

- กัน Lead เผลอ push main
- บังคับ admin review ทุก change
- กัน force-push ทำลาย history

---

## 3 ทางเลือก Workflow

| Option | Lead ทำ | Bot ทำ | Admin ทำ | Complexity |
|---|---|---|---|---|
| **A · Local CLI** | รัน `./scripts/submit-skill.sh` → script generate ทุกอย่าง + open PR | — | review + merge | Medium |
| **B · GitHub Action bot** ✓ | แค่ commit skill + PR | Action detect change → regenerate agent + update index + cascade refs → commit เข้า PR | review + merge | High setup · easy ใช้งาน |
| **C · Hybrid (A+B)** | เลือกได้ทั้ง 2 ทาง | ทำเสมอ (กัน Lead skip) | review + merge | Highest |

### ตัดสินใจ · เลือก B

เหตุผล:
1. Lead UX ดีที่สุด — แค่ commit + PR · ไม่ต้องลง `gh` CLI · ไม่ต้องรู้ sed
2. Centralized logic — admin แก้ workflow ที่เดียว · 7 Leads ได้พร้อมกัน
3. Consistent — ไม่มี case ที่ Lead skip step

Trade-off ที่ยอมรับ:
- Setup ครั้งแรกซับซ้อนกว่า A
- Bot ต้อง permission write → ใช้ `GITHUB_TOKEN` ในตัว · พอ

---

## Roadmap · 4 Phases

### Phase 1 · Access + Protection (start here)

**เป้าหมาย:** 7 Leads ส่ง PR ได้ · admin บังคับ review

Tasks:

1. รวบรวม GitHub username ของ 7 Leads
2. Invite เป็น Collaborator (permission `push`)
3. Setup branch protection main:
   - Required PR review = 1
   - Dismiss stale approvals
   - No force push · no deletion
4. เพิ่ม `.github/CODEOWNERS` — admin reviews all (+ optional per-skill owner)
5. เพิ่ม `.github/pull_request_template.md`
6. เพิ่ม `CONTRIBUTING.md` ที่ root

Effort: ~1-2 ชม. (รวบรวม username นานสุด)

### Phase 2 · Skill Validation Workflow

**เป้าหมาย:** PR ที่ skill structure ผิด → fail CI · admin ไม่ต้อง review เอง

File: `.github/workflows/skill-validation.yml`

Checks:

- README.md exists with required frontmatter (`name`, `description`)
- File naming convention (numbered files หรือ flat structure)
- `template_document/` exists ถ้า skill refs templates
- No broken internal links ใน skill files
- Path patterns ใน skill ใช้ vault convention (Projects/, reference_data/)

Triggers:
- On PR · paths: `ProgramType_Skills/**`

Effort: 1-2 วัน implement + test

### Phase 3 · Cascade Bot

**เป้าหมาย:** Lead commit skill เปลี่ยน → bot regenerate ทุก downstream อัตโนมัติ

File: `.github/workflows/skill-cascade.yml`

Steps:

1. Detect changed skill folders (git diff)
2. For each changed skill:
   - Read `README.md` frontmatter
   - Regenerate/update wrapper agent in `.claude/agents/<name>.md`
   - Update `ProgramType_Skills/overview.md` entry
   - Update `docs/skills.md` entry (if applicable)
3. Run indexer (CI mode) → regenerate `.index/master-index.md`
4. Update cross-refs (grep + sed if path/name changed)
5. Commit back to PR branch with message: `bot: cascade updates`
6. Comment summary on PR

Permissions ต้องการ:
- `contents: write` (commit back)
- `pull-requests: write` (comment)

Effort: 3-5 วัน implement · ต้องเขียน skill metadata parser + agent generator

### Phase 4 · Polish

- `CHANGELOG.md` auto-update จาก PR title + labels
- Slack/Teams webhook notify on merge to main
- Issue templates: "request new skill" + "report skill bug"
- Release tags (`v1.0`, `v1.1`) ผ่าน semantic-release หรือ manual
- Skill version pinning (ทีมเลือก version skill ที่จะใช้)

Effort: 2-3 วัน

---

## Architecture Diagram · End-to-End

```
┌──────────┐     branch     ┌─────┐
│   Lead   │ ────push────▶ │  PR │
└──────────┘                 └──┬──┘
                                │
                    ┌───────────┼───────────┐
                    │           │           │
                    ▼           ▼           ▼
              Phase 2:     Phase 3:    Standard
              Validate    Cascade bot   GitHub
                    │           │       checks
                    │           │           │
                    └───────────┼───────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │  Admin reviews   │
                       │  (Theerapong)    │
                       └────────┬─────────┘
                                │
                                │ approve + merge
                                ▼
                       ┌──────────────────┐
                       │   main branch    │
                       └────────┬─────────┘
                                │
                       ┌────────┴─────────┐
                       │                  │
                       ▼                  ▼
                Phase 4:           Auto-sync to
                CHANGELOG +        all team vaults
                Slack notify       (07:30 ICT daily)
```

---

## Open Questions ต้องตัดสินใจก่อน Phase 1

1. **7 GitHub usernames** ของ Leads — รวบรวมจากใคร?
2. **CODEOWNERS scope** — ใส่ Lead เป็น owner ของ skill ตัวเองด้วยไหม (= Lead ต้อง self-review ก่อน admin)? หรือ admin คนเดียว review พอ?
3. **CI required checks** — Phase 2 validation workflow ใช้บังคับใน branch protection ก่อนไหม (= fail = ห้าม merge)? หรือ informational เฉยๆ?
4. **Bot commit identity** — ใช้ `github-actions[bot]` หรือ create deploy user?

---

## Open Questions สำหรับ Phase 3 (design ลึก)

5. **Skill convention strict ขนาดไหน** — ต้อง README + numbered files ทุก skill? หรือยอมรับ legacy flat structure ด้วย?
6. **Wrapper agent template** — generate จาก skill metadata อย่างไร? ใช้ template file + variable substitution?
7. **Cross-ref update** — grep + sed (เร็ว · เสี่ยง false positive) หรือ AST/markdown parser (ช้า · แม่นยำ)?
8. **Indexer in CI** — pure script ไม่ต้องเรียก Claude หรือ ต้อง headless Claude Code session?

---

## ไม่ scope ใน plan นี้

- Skill testing framework (ทดสอบ agent ตอบถูกไหม)
- Skill versioning + rollback
- Lead RBAC (เช่น Lead A แก้เฉพาะ skill ของตัวเอง)
- Multi-org (ถ้า skill share ข้าม org)

ของพวกนี้เป็น enterprise-grade ที่เคยคุยกันใน scoring 79/100

---

## ขั้นตอนต่อจากนี้ (เมื่อพร้อม implement)

1. **อ่าน doc นี้รอบคัด** → ตัดสินใจ open questions ข้างบน
2. **เริ่ม Phase 1** — รวบรวม usernames · invite · setup protection
3. **Phase 2** — validation workflow (PR-blocking)
4. **Phase 3** — cascade bot (game changer)
5. **Phase 4** — polish

แต่ละ Phase ทำเสร็จได้แยกกัน · ไม่ต้องทำหมดในรอบเดียว

---

## ตัวเลขประมาณการ

- Phase 1: 1-2 ชม.
- Phase 2: 1-2 วัน
- Phase 3: 3-5 วัน
- Phase 4: 2-3 วัน

**รวม:** ~2 อาทิตย์ ถ้าทำ part-time · ~1 อาทิตย์ ถ้าจริงจัง

ROI: หลังจบ Phase 3 = admin time ต่อ skill upgrade ลดจาก ~30 นาที (manual cross-refs) เหลือ ~5 นาที (review PR เท่านั้น)
