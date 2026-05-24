# API Security Checklist

ตรวจก่อน handoff ทุกครั้ง — ผ่านทุกข้อจึง approve

---

## Authentication & Authorization

- [ ] ทุก endpoint ระบุชัดว่า `Auth: Required` หรือ `Public`
- [ ] ไม่มี endpoint ที่ตั้งใจให้ auth required แต่หลุดเป็น public โดยบังเอิญ
- [ ] JWT: กำหนด expiry เหมาะสม (access token สั้น, refresh token ยาว)
- [ ] API Key: มี rotation policy และห้าม return ค่า key ใน response
- [ ] Permission check ระดับ resource ไม่ใช่แค่ระดับ endpoint
  - เช่น user A ต้องไม่เห็น order ของ user B แม้ path จะถูกต้อง

---

## Input Validation

- [ ] ทุก field ที่รับจาก client มี validation rule ชัดเจน (type, length, format, range)
- [ ] ไม่ trust ข้อมูลจาก client โดยไม่ validate แม้จะเป็น internal service
- [ ] UUID / ID parameter validate ก่อน query DB — ไม่ส่ง raw input เข้า SQL
- [ ] String field มี max length กำกับทุกตัว
- [ ] Enum field validate ว่าอยู่ใน allowed values
- [ ] File upload: validate type โดย MIME type + magic bytes ไม่ใช่แค่ extension

---

## Data Exposure

- [ ] Response ไม่รั่ว sensitive field เช่น password hash, internal token, secret key
- [ ] Error message ไม่เปิดเผย stack trace, SQL query, table name, internal path
- [ ] Log ไม่บันทึก sensitive data ทั้งใน request log และ error log
- [ ] PII (ชื่อ, เบอร์โทร, email, เลขบัตร) mask ในที่ที่ไม่จำเป็นต้องแสดงเต็ม
- [ ] Response ส่ง field เฉพาะที่ consumer ต้องการ — ไม่ return ทั้ง row จาก DB

---

## Rate Limiting

- [ ] ทุก public endpoint มี rate limit
- [ ] Auth endpoint (login, OTP) มี rate limit เข้มงวดกว่าปกติ
- [ ] Return `429 Too Many Requests` พร้อม `Retry-After` header
- [ ] Rate limit per user / per IP / per API Key ชัดเจน

---

## Idempotency

- [ ] POST endpoint ที่มี side effect (สร้าง order, ชำระเงิน) รองรับ `Idempotency-Key` header
- [ ] Duplicate request ด้วย Idempotency-Key เดิม → return response เดิม ไม่สร้างซ้ำ
- [ ] Idempotency-Key เก็บไว้นานพอ (เช่น 24 ชั่วโมง)

---

## Transport & Headers

- [ ] บังคับ HTTPS ทุก endpoint — redirect หรือ reject HTTP
- [ ] CORS: ระบุ allowed origin ชัดเจน ไม่ใช้ `*` ใน production สำหรับ authenticated endpoint
- [ ] Security headers ใน response:
  - `X-Content-Type-Options: nosniff`
  - `X-Frame-Options: DENY`
  - `Strict-Transport-Security` (HSTS)

---

## Logging & Traceability

- [ ] ทุก request มี unique `Request-ID` (generate ที่ server หรือ accept จาก client)
- [ ] Log บันทึก: timestamp, method, path, status code, response time, request_id
- [ ] Log ไม่บันทึก request body ทั้งก้อนถ้ามี sensitive field — mask ก่อน log
- [ ] Error 5xx ต้อง alert ทีม ไม่ใช่แค่ log เงียบๆ
