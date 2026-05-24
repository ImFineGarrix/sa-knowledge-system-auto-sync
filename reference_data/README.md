# reference_data/

> ข้อมูล reference ของทีม · ไม่ใช่ specs/decisions (ไปที่ `Projects/`) · ไม่ใช่ SA Skills (ไปที่ `ProgramType_Skills/`)

ทุก subfolder เก็บ "ข้อมูล" ตามชื่อ — ใช้เป็น source-of-truth ที่ agent + คนในทีมอ้างถึงได้

| Subfolder | เก็บอะไร | ตัวอย่าง |
|---|---|---|
| `db_schema/` | DB schema ของ product แต่ละตัว | `<product>-tables.sql`, ER diagrams, data dictionary |
| `dev_wiki/` | wiki internal ของทีม dev | onboarding, conventions, runbooks, troubleshooting |
| `document_spec/` | spec document กลาง + spec เดิมที่จะ revise (`gateway-thirdparty-api` อ่านตอน revise/modify) | API contract templates, message schemas, OpenAPI base, PDFs/old design docs ของระบบที่จะแก้ |
| `source_program/` | reference source code (`gateway-thirdparty-api` อ่านตอน revise/modify) | sample programs, code patterns, code เก่าที่จะแก้ |

## ไม่ sync จาก upstream

ทั้งหมดเป็น **ของทีม** · auto-sync workflow ไม่แตะ folder นี้
