# REST Guidelines Reference

## HTTP Method — ใช้อะไรเมื่อไร

| Method | ใช้เมื่อ | Idempotent | Body |
|---|---|---|---|
| **GET** | ดึงข้อมูล ห้ามมี side effect | ✅ | ❌ |
| **POST** | สร้างใหม่, หรือ action ที่ไม่ fit method อื่น | ❌ | ✅ |
| **PUT** | Replace ทั้งหมด (ต้องส่ง full object) | ✅ | ✅ |
| **PATCH** | Update บางส่วน (ส่งเฉพาะ field ที่เปลี่ยน) | ❌* | ✅ |
| **DELETE** | ลบ resource | ✅ | ❌ |

> *PATCH ควรออกแบบให้ idempotent ถ้าเป็นไปได้

### Action ที่ไม่ใช่ CRUD — ใช้ POST + verb เป็น sub-resource

```
POST /orders/{orderId}/cancel       ← ยกเลิก order
POST /orders/{orderId}/confirm      ← ยืนยัน order
POST /users/{userId}/password-reset ← reset password
POST /invoices/{id}/send            ← ส่ง invoice
POST /payments/{id}/refund          ← คืนเงิน
```

ไม่ใช้ verb ใน URL หลัก:
```
❌ POST /cancelOrder
❌ GET  /getUserById?id=123
```

---

## HTTP Status Code — เลือกให้ถูก

### 2xx Success

| Code | ใช้เมื่อ |
|---|---|
| **200 OK** | GET, PATCH, PUT สำเร็จ |
| **201 Created** | POST สร้าง resource ใหม่สำเร็จ — ควร return resource + Location header |
| **202 Accepted** | Request รับแล้ว แต่ process แบบ async ยังไม่เสร็จ |
| **204 No Content** | DELETE สำเร็จ, หรือ action ที่ไม่มี response body |

### 3xx Redirect

| Code | ใช้เมื่อ |
|---|---|
| **301 Moved Permanently** | URL เปลี่ยนถาวร (versioning) |
| **304 Not Modified** | ใช้กับ ETag / conditional request |

### 4xx Client Error

| Code | ใช้เมื่อ | ตัวอย่าง |
|---|---|---|
| **400 Bad Request** | Input ผิด format หรือ validation fail | field required, invalid UUID |
| **401 Unauthorized** | ไม่มี token หรือ token invalid/expired | missing Authorization header |
| **403 Forbidden** | มี token แต่ไม่มีสิทธิ์ | user ทั่วไปเข้า admin endpoint |
| **404 Not Found** | Resource ไม่มีอยู่ | order ID ไม่มีใน DB |
| **405 Method Not Allowed** | Method ไม่รองรับบน path นั้น | PUT /orders (ถ้าไม่รองรับ) |
| **409 Conflict** | ข้อมูลซ้ำ หรือ state conflict | email ซ้ำ, optimistic lock |
| **410 Gone** | Resource เคยมีแต่ถูกลบถาวรแล้ว | ใช้แทน 404 ถ้าต้องการแยก |
| **422 Unprocessable Entity** | Format ถูกแต่ business rule ไม่ผ่าน | วันที่ check-out ก่อน check-in |
| **429 Too Many Requests** | เกิน rate limit | ดู Retry-After header |

### 5xx Server Error

| Code | ใช้เมื่อ |
|---|---|
| **500 Internal Server Error** | Unexpected error — log detail ไว้ใน server ห้าม expose |
| **502 Bad Gateway** | Upstream service ตอบกลับผิดพลาด |
| **503 Service Unavailable** | ระบบปิดชั่วคราว maintenance, ดู Retry-After header |
| **504 Gateway Timeout** | Upstream service timeout |

### ข้อผิดพลาดที่พบบ่อย

```
❌ Return 200 แล้วใส่ error ใน body
   { "status": "error", "message": "not found" }  + HTTP 200

✅ ใช้ HTTP status code ที่ถูกต้อง
   HTTP 404 + error body

❌ Return 500 ทุก error เพื่อความง่าย
✅ แยก 4xx (client error) กับ 5xx (server error) ให้ชัด

❌ Return 403 เมื่อ resource ไม่มี (เพื่อซ่อน existence)
✅ อาจ return 404 เสมอสำหรับ resource ที่ sensitive (security by obscurity)
```

---

## URL Design Rules

### Path Parameter vs Query Parameter

```
Path Parameter → ระบุตัวตนของ resource (required)
  /orders/{orderId}
  /users/{userId}/addresses/{addressId}

Query Parameter → filter, sort, pagination, optional behavior
  /orders?status=pending&page=2&limit=20
  /products?sort=price_asc&min_price=100
```

### Sorting Convention

```
?sort=price_asc          ← ง่าย, อ่านง่าย
?sort=price_desc
?sort=created_at_desc,name_asc    ← multi-sort

หรือแบบ explicit:
?sort_by=price&sort_order=asc
```

### Filtering Convention

```
?status=pending                    ← single value
?status=pending,confirmed          ← multiple values (OR)
?min_price=100&max_price=500       ← range
?created_from=2025-01-01&created_to=2025-01-31   ← date range
```

### Headers ที่ควร Return เสมอ

```
Content-Type: application/json
X-Request-ID: req_01HXYZ          ← trace ID ทุก response
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 87
X-RateLimit-Reset: 1705312200     ← Unix timestamp

สำหรับ POST 201:
Location: /v1/orders/ord_01HXYZ   ← URL ของ resource ที่สร้าง
```
