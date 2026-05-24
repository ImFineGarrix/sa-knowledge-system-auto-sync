# Skills

> ความสามารถระดับ production **13** ตัว จาก Anthropic + CEO ของ Obsidian — Claude ตัดสินใจเรียกเองอัตโนมัติ คุณแค่บอกว่าอยากได้อะไร

## Document & Office · 5 skills

<div class="cat-grid" markdown>
<div class="cat-card" markdown>
<div class="cat-card__head">
<div class="cat-card__name">pdf</div>
<div class="cat-card__tag">Anthropic</div>
</div>
<div class="cat-card__desc">อ่าน, ดึง text + table, เติมฟอร์ม, merge, split, rotate, watermark, OCR — skill ที่ใช้บ่อยที่สุดของงาน SA (vendor spec, regulatory doc)</div>
</div>
<div class="cat-card" markdown>
<div class="cat-card__head">
<div class="cat-card__name">docx</div>
<div class="cat-card__tag">Anthropic</div>
</div>
<div class="cat-card__desc">สร้าง / แก้ Word document — tracked changes, comment, format, TOC, page number, letterhead เหมาะกับงาน handoff ให้ Dev/QA</div>
</div>
<div class="cat-card" markdown>
<div class="cat-card__head">
<div class="cat-card__name">xlsx</div>
<div class="cat-card__tag">Anthropic</div>
</div>
<div class="cat-card__desc">เปิด อ่าน แก้ .xlsx / .xlsm / .csv — เพิ่ม column, ใส่ formula, format, chart, clean messy data ใช้กับงาน field mapping และ test matrix</div>
</div>
<div class="cat-card" markdown>
<div class="cat-card__head">
<div class="cat-card__name">pptx</div>
<div class="cat-card__tag">Anthropic</div>
</div>
<div class="cat-card__desc">สร้าง slide deck จากภาษาธรรมชาติ — layout, chart, speaker note, template ใช้สำหรับ architecture summary และ handoff briefing</div>
</div>
<div class="cat-card" markdown>
<div class="cat-card__head">
<div class="cat-card__name">doc-coauthoring</div>
<div class="cat-card__tag">Anthropic</div>
</div>
<div class="cat-card__desc">workflow สำหรับ collaborative writing — context transfer, iteration, verification ใช้ตอนร่าง proposal หรือ decision doc</div>
</div>
</div>

## Design · 2 skills

<div class="cat-grid" markdown>
<div class="cat-card" markdown>
<div class="cat-card__head">
<div class="cat-card__name">frontend-design</div>
<div class="cat-card__tag">Anthropic</div>
</div>
<div class="cat-card__desc">สร้าง frontend ระดับ production จริง — design system, bold typography, หนีรูปลักษณ์ AI generic เป็นพลังเบื้องหลัง spec-ui-designer</div>
</div>
<div class="cat-card" markdown>
<div class="cat-card__head">
<div class="cat-card__name">brand-guidelines</div>
<div class="cat-card__tag">Anthropic</div>
</div>
<div class="cat-card__desc">encode brand ของทีมไว้ครั้งเดียว — color, typography, voice — ทุก agent จะใช้ตามนี้อัตโนมัติ ทำให้ output สม่ำเสมอ</div>
</div>
</div>

## Meta · 1 skill

<div class="cat-grid" markdown>
<div class="cat-card" markdown>
<div class="cat-card__head">
<div class="cat-card__name">skill-creator</div>
<div class="cat-card__tag">Anthropic</div>
</div>
<div class="cat-card__desc">สร้าง skill ใหม่ แก้ skill เดิม รัน eval ทดสอบ optimize description ให้ trigger แม่นขึ้น — skill ที่สร้าง skill ได้เอง</div>
</div>
</div>

## Obsidian-native · 5 skills

<div class="cat-grid" markdown>
<div class="cat-card" markdown>
<div class="cat-card__head">
<div class="cat-card__name">obsidian-markdown</div>
<div class="cat-card__tag">kepano</div>
</div>
<div class="cat-card__desc">wikilink, embed, callout, frontmatter, tag — ทำให้ Claude เขียน Markdown แบบ Obsidian-native จริง ไม่ใช่แค่ Markdown ปกติ</div>
</div>
<div class="cat-card" markdown>
<div class="cat-card__head">
<div class="cat-card__name">obsidian-bases</div>
<div class="cat-card__tag">kepano</div>
</div>
<div class="cat-card__desc">สร้าง view แบบ database สำหรับ note — table view, card view, filter, formula เหมาะกับ product tracker และ ADR dashboard</div>
</div>
<div class="cat-card" markdown>
<div class="cat-card__head">
<div class="cat-card__name">obsidian-cli</div>
<div class="cat-card__tag">kepano</div>
</div>
<div class="cat-card__desc">สั่งงาน Obsidian จาก command line — search, create note, manage property, รัน JavaScript, develop plugin</div>
</div>
<div class="cat-card" markdown>
<div class="cat-card__head">
<div class="cat-card__name">json-canvas</div>
<div class="cat-card__tag">kepano</div>
</div>
<div class="cat-card__desc">สร้างและแก้ไฟล์ .canvas — mind map ภาพ, architecture diagram, MOC overlay เป็นด้าน visual ของ Obsidian</div>
</div>
<div class="cat-card" markdown>
<div class="cat-card__head">
<div class="cat-card__name">defuddle</div>
<div class="cat-card__tag">kepano</div>
</div>
<div class="cat-card__desc">ดึง markdown สะอาดๆ จากเว็บ — ตัดสิ่งรกๆ ออก ประหยัด token ใช้ดึง vendor doc เข้า vault</div>
</div>
</div>

## วิธีทำงานของ skill

ไม่ต้องเรียก skill ด้วยชื่อ — บอกความต้องการเป็นภาษาธรรมชาติ Claude จะเลือก skill เอง

| ถ้าคุณบอก… | Skill ที่ทำงาน |
|---|---|
| "อ่าน PDF spec ที่ Projects/GPP/references/scb.pdf" | `pdf` |
| "ทำ data dictionary เป็น spreadsheet" | `xlsx` |
| "แปลง draft นี้เป็น Word ส่งให้ Dev" | `docx` |
| "ออกแบบ landing page แบบ cinematic" | `frontend-design` |
| "ดึงเว็บนี้เข้า vault" | `defuddle` |

## MCP — Context7

Vault ต่อ **Context7 MCP** ไว้ด้วย — เวลา agent อ้างถึง framework (Spring, React, OAS) Context7 จะ inject docs ล่าสุดเข้ามา ทำให้ API ไม่ถูก hallucinate
<pre><code class="language-json title=".mcp.json"">{
  &quot;mcpServers&quot;: {
    &quot;context7&quot;: {
      &quot;type&quot;: &quot;http&quot;,
      &quot;url&quot;: &quot;https://mcp.context7.com/mcp&quot;
    }
  }
}</code></pre>
