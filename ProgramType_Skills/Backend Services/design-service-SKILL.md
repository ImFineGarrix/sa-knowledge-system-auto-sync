---
name: sa-designweb
description: Design responsive enterprise/internal web app mockups for System Analysts (SA) producing developer handoffs. AGGRESSIVELY trigger whenever the user asks to design, mock up, sketch, wireframe, prototype, or visualize ANY screen for a business/internal/back-office/admin web app — forms, tables, dashboards, search, detail/edit, wizards, login, admin panels, portals, reports, CRUD tools. Trigger on Thai like "ออกแบบหน้าจอ", "ออกแบบหน้าเว็บ", "ทำ mockup", "ทำ UI", "ออกแบบระบบ", "ทำ wireframe", "วิเคราะห์โปรแกรม", "หน้า admin", "หน้าระบบหลังบ้าน", "ช่วยออกแบบหน้า…". Trigger on English like "design a screen", "mock up a UI", "wireframe", "enterprise UI", "internal tool", "admin panel", "back-office screen". Also trigger on "sa_designweb"/"sa-designweb". Use EVEN IF user doesn't say "SA" or "mockup" — if they want screens for a business app that someone will code, this applies. NOT for marketing/consumer/brand sites or native mobile — use frontend-design. Output is HTML + separated CSS + spec .md under SA_designweb/.
---

# sa-designweb — System Analyst Web Design Helper

(Output deliverables use the prefix `sa_designweb_` — that's the deliverable file convention, distinct from the skill identifier.)

Help a System Analyst (SA) take a program/feature requirement, produce a clean responsive enterprise web mockup, iterate with the SA until they commit, then deliver organized files (HTML mockup, separated CSS, documentation) ready for programmer handoff.

The user is acting as the SA. They will describe a program, screen, or feature. Some requirements come with an existing design system (mood and tone to follow). Others are greenfield — define a new mood and tone for them.

## The Workflow — Five Phases

Always run these phases in order. Don't jump ahead to file delivery before the SA explicitly commits.

### Phase 1 — Capture Requirements

Ask the SA structured questions before designing. If they already gave detail in their initial message, fill what they gave and only ask for the gaps. Do not interrogate them with every question if most are already obvious from context.

Cover at minimum:
1. **Program / feature name and purpose** — what does this screen do, who uses it (clerk, manager, customer-facing internal tool)?
2. **Screen type** — list/table, form, dashboard, detail view, wizard, search, login, report, modal, etc.
3. **Key data fields and actions** — fields to display, filters, buttons, primary CTA, secondary actions.
4. **Mood and tone** — does the SA want a NEW direction (you propose), or follow an EXISTING one? If existing, ask for: brand color hex(es), font family, any reference URL/screenshot.
5. **Language** — Thai, English, or bilingual? Default to matching the language the SA wrote in.
6. **Responsive breakpoints** — desktop primary? must work on tablet/mobile too?
7. **Constraints** — framework target (vanilla HTML/CSS, Bootstrap, Tailwind, etc.), accessibility level, browser support.

When several gaps exist, prefer `ask_user_input_v0` for tappable choices (faster than typing). For a single open-ended gap, plain prose is fine.

### Phase 2 — Define Mood and Tone

If the SA wants a NEW mood and tone, propose it BEFORE drafting any screen. Show the SA:
- A short name for the direction (e.g. "Calm Corporate", "Modern Clean", "Trust Blue", "Warm Neutral")
- Primary / secondary / accent colors with hex codes
- Background and surface colors
- Typography pairing (heading + body fonts)
- Border radius, spacing scale, shadow level

Read `references/mood_and_tone.md` for enterprise-appropriate palettes and font pairings. Enterprise designs lean clean and trustworthy — saturated brand color + neutral grays + plenty of whitespace works far better than the maximalist patterns suitable for marketing sites. Resist the urge to be flashy.

If the SA gives an EXISTING mood and tone, extract the tokens (colors, fonts, radius, spacing) and confirm them back before drafting. Phrase like: "เข้าใจว่าใช้สีหลัก #1A56DB, font Sarabun, มุมโค้ง 6px ครับ ถ้าถูกต้องเริ่มออกแบบเลยนะครับ"

Get explicit SA approval on the mood and tone before moving to Phase 3.

### Phase 3 — Draft the Mockup

Build a single self-contained HTML file as the working mockup. Use `visualize:show_widget` so the SA can see it inline immediately. Read `references/enterprise_patterns.md` for proven layout patterns (sidebar nav, top nav, data tables, form layouts, dashboard cards, breadcrumbs, modals, etc.) before composing.

Mockup requirements:
- Single HTML file with embedded `<style>` (separation comes at commit, not now)
- Use CSS variables for the mood-and-tone tokens (colors, spacing, radius, fonts)
- Mobile responsive — at minimum, layout reflows below ~768px
- Filled with realistic placeholder data (NOT "Lorem ipsum" or "ชื่อ 1, ชื่อ 2") — use plausible Thai/English business data so the SA can judge real density and column widths
- Include all states the requirement implies: empty state, primary action, secondary actions, hover/active where relevant
- Annotate non-obvious interactions in a "Designer Notes" block at the bottom of the mockup (small, muted text — does not interfere with the mockup itself)

After showing the mockup, ask: "ดูแล้วเป็นยังไงบ้างครับ มีจุดไหนอยากให้ปรับ หรือถ้า OK แล้วบอก commit ได้เลย"

### Phase 4 — Iterate

The SA will reply with feedback. Common feedback patterns to expect:
- "เพิ่มฟิลด์ X" → add the field, re-show mockup
- "เปลี่ยนสีหลักเป็น..." → update the CSS variable, re-show
- "ตารางต้อง sort/filter ได้" → add UI affordances for it (visual only — full JS not needed at mockup stage)
- "หน้านี้ต้องมี modal สำหรับ..." → add the modal section
- "OK / commit / ใช้ได้ / เอาตามนี้ / approve" → proceed to Phase 5

Re-show the updated mockup on every iteration. Don't ask if every small change is OK individually — make the change, show the new version, then ask broadly "ปรับตามนี้ครับ ดูเป็นไงบ้าง".

Only move to Phase 5 when the SA explicitly approves with words like "OK", "commit", "ใช้ได้", "เอาตามนี้", "ส่งให้ dev ได้", "approve", or equivalent. Vague replies like "ดูดีนะ" without a clear go-signal are not commits — ask one more time to confirm.

### Phase 5 — Commit and Deliver

Once committed, produce the deliverable file set in `/mnt/user-data/outputs/SA_designweb/`.

#### Step 5.1 — Determine the next sequence number

Before writing any file, check the existing folder for the highest existing sequence number:

```bash
mkdir -p /mnt/user-data/outputs/SA_designweb
ls /mnt/user-data/outputs/SA_designweb/ 2>/dev/null \
  | grep -oE 'sa_designweb_[0-9]{3}' \
  | sort -u \
  | tail -1
```

If the folder already contains `sa_designweb_001_*` and `sa_designweb_002_*`, the next is `003`. If empty or missing, start at `001`. Always pad to 3 digits.

The set name (used as a prefix throughout) is: `sa_designweb_{NNN}_{YYYY-MM-DD}` — e.g. `sa_designweb_003_2026-04-30`.

Use today's date in ISO format (YYYY-MM-DD).

#### Step 5.2 — Files to produce

Produce all of the following inside `/mnt/user-data/outputs/SA_designweb/`:

1. **Documentation** — `{set_name}.md`
   The SA's spec for the dev team. Use the template in `references/deliverable_template.md`. Includes: requirement summary, mood & tone tokens, screen list with descriptions, field/action inventory, responsive behavior notes, and a manifest listing the attached files.

2. **Mockup HTML** — `{set_name}.html`
   The final clean version of the committed mockup. REMOVE the embedded `<style>` block and replace with `<link rel="stylesheet" href="...">` references to the external stylesheets in the `_css/` folder. Add this comment at the very top of the HTML file:
   ```html
   <!-- generated by sa_designweb on YYYY-MM-DD -->
   <!-- spec: ./{set_name}.md -->
   ```

3. **Stylesheets** — in subfolder `{set_name}_css/`, split by concern. Use these filenames:
   - `tokens.css` — CSS variables only (colors, spacing, radius, fonts, shadows). Nothing else.
   - `base.css` — CSS reset, body, default typography
   - `layout.css` — page shell, grid, responsive breakpoints, header/sidebar/main structure
   - `components.css` — buttons, inputs, tables, cards, modals, badges, etc.
   - `utilities.css` — only if utilities are actually needed (margin/padding helpers, text helpers, visibility). Skip the file entirely if not needed.

   Keep each file focused. If `components.css` grows beyond ~300 lines, split further by domain (e.g. `components.forms.css`, `components.tables.css`) and update the link order in the HTML accordingly.

   Link order in the HTML `<head>` must be: `tokens.css → base.css → layout.css → components.css → utilities.css` (utilities last so they override).

#### Step 5.3 — Present the files

After writing all files, call `present_files` with paths in this order:
1. The documentation `.md` FIRST (it's the entry point for the dev team)
2. The HTML mockup
3. Each CSS file in link order

Then give the SA a one-line summary like:
> ส่งให้ dev ได้เลยครับ — set: sa_designweb_003_2026-04-30 (ไฟล์ .md, .html, และ stylesheet ทั้งหมดอยู่ใน SA_designweb/)

Do not over-explain. The SA has already seen the mockup; they don't need a recap.

## Iterating on a previously committed set

If the SA returns later and says something like "แก้ sa_designweb_002 หน่อย" or "อัพเดต design ตัวเก่า", treat it as a NEW iteration — increment the sequence number and produce a new set. Reference the prior set in the documentation under a "Supersedes" line. Do not overwrite earlier sets — they are an audit trail.

## Working with the visualizer during iteration

In Phases 3–4, prefer `visualize:show_widget` with the full HTML+inline-CSS so the SA sees the result immediately in chat. Save to a file ONLY at commit (Phase 5).

If the SA explicitly asks for a file early ("ขอไฟล์ HTML ลองเอาไปเปิดดู"), save a draft to `/home/claude/draft_mockup.html` and `present_files` it, but make clear it's a draft and that the final committed deliverable goes through Phase 5.

## Tone and language

- Match the SA's language. They wrote in Thai → reply in Thai. They wrote in English → English. Bilingual mockups are fine if the SA uses both.
- Be concise. SAs are time-pressed. Don't preamble. Don't over-explain choices unless asked.
- Surface trade-offs briefly when they matter ("ถ้าใส่ filter เพิ่มอีก 3 ตัวแถวบนจะแน่น แนะนำเก็บไว้ใน 'More filters' ครับ") — one sentence, then move on.

## What this skill is NOT for

- Not for marketing landing pages, art-directed sites, or maximalist creative work. For that, use the `frontend-design` skill instead.
- Not for writing actual application logic, backend code, or framework-specific implementations. Output is design-grade HTML/CSS intended as a spec — the programmer writes the real code from it.
- Not for native mobile apps.

## Reference files in this skill

- `references/enterprise_patterns.md` — Common enterprise UI patterns (nav, tables, forms, dashboards, modals). Read this in Phase 3 before drafting.
- `references/mood_and_tone.md` — Enterprise-appropriate color palettes and font pairings. Read this in Phase 2 when proposing a new direction.
- `references/deliverable_template.md` — Markdown template for the handoff documentation. Read this in Phase 5 before writing the `.md`.
