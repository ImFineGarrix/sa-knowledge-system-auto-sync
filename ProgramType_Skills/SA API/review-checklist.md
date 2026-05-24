# API Review Checklist

ใช้ก่อน handoff spec ให้ dev — ผ่านทุกข้อจึง sign off

---

## Naming & Consistency

- [ ] URL ใช้ plural noun ตลอด ไม่มี verb ใน path
- [ ] URL ใช้ lowercase + hyphen สำหรับ multi-word
- [ ] Field name ใช้ snake_case ตลอดทั้ง API (ไม่ผสม camelCase)
- [ ] Enum value ใช้ lowercase string ตลอด
- [ ] Timestamp field ทุกตัวใช้ ISO 8601 + UTC
- [ ] Boolean field มี prefix `is_`, `has_`, หรือ `can_`
- [ ] ชื่อ field เดียวกัน หมายความเดียวกัน ทุก endpoint (เช่น `customer_id` ไม่ใช่บางที่ใช้ `user_id`)

---

## Completeness

- [ ] ทุก endpoint มี: Method, Path, Description, Auth requirement
- [ ] ทุก request body มี: field name, type, required/optional, validation rule
- [ ] ทุก response มี: success schema + ทุก error case ที่เป็นไปได้
- [ ] ทุก path parameter และ query parameter มี description และ validation
- [ ] Error Catalog ครอบคลุมทุก error code ที่ใช้ใน API นี้
- [ ] Pagination ระบุใน endpoint ที่ return list ทุกตัว

---

## HTTP Semantics

- [ ] GET ไม่มี side effect และไม่มี request body
- [ ] POST 201 มี `Location` header ชี้ไปยัง resource ที่สร้าง
- [ ] DELETE return 204 No Content (ไม่มี body)
- [ ] Status code ถูกต้องทุก case (ไม่ return 200 สำหรับ error)
- [ ] 4xx ใช้สำหรับ client error, 5xx สำหรับ server error เท่านั้น

---

## Security

- [ ] ผ่าน security-checklist.md ทุกข้อแล้ว

---

## Backward Compatibility (กรณีแก้ API เดิม)

- [ ] ไม่ลบ field ที่มีอยู่ใน response (เพิ่มได้ ลบไม่ได้)
- [ ] ไม่เปลี่ยน type ของ field ที่มีอยู่
- [ ] ไม่เปลี่ยน URL หรือ Method ของ endpoint เดิม
- [ ] ถ้าต้องมี breaking change → bump version แล้ว document migration path

---

## Documentation

- [ ] มี example request และ example response ทุก endpoint
- [ ] Business rule และ constraint อธิบายไว้ใน spec ไม่ใช่แค่ในหัว
- [ ] Open questions ทุกข้อได้รับคำตอบหรือ tracked ไว้แล้ว
