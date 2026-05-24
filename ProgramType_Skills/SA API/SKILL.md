---
name: sa-api-design
description: >
  ใช้ skill นี้ทุกครั้งที่งานเกี่ยวข้องกับการออกแบบหรือรีวิว API
  เช่น: ออกแบบ REST API endpoint, กำหนด request/response schema,
  เลือก HTTP method และ status code, ออกแบบ error format, วาง versioning strategy,
  เขียน API spec หรือ OpenAPI/Swagger skeleton, รีวิว API ก่อน handoff ให้ dev,
  ออกแบบ pagination / filtering / sorting, กำหนด auth strategy สำหรับ API,
  วิเคราะห์ว่า API ที่มีอยู่มีปัญหาอะไร.
  ใช้ skill นี้แม้ผู้ใช้ไม่ได้พูดว่า "API Design" โดยตรง —
  ถ้า intent คือการกำหนด contract ระหว่าง client กับ server ให้ trigger skill นี้เสมอ
---

# SA API Design Skill

## Quick Reference

| งาน | ไปที่ |
|---|---|
| เริ่มออกแบบ API ใหม่ | [API Design Workflow](#api-design-workflow) |
| กำหนด Resource & Endpoint | [Resource Modeling](#resource-modeling) |
| ออกแบบ Request / Response | [Request & Response Design](#request--response-design) |
| เลือก HTTP Method & Status Code | [references/rest-guidelines.md](references/rest-guidelines.md) |
| ออกแบบ Error Format | [Error Design](#error-design) |
| Pagination / Filter / Sort | [references/request-response-patterns.md](references/request-response-patterns.md) |
| Versioning / Auth / Rate Limit | [Cross-cutting Concerns](#cross-cutting-concerns) |
| เขียน OpenAPI Skeleton | [OpenAPI Output](#openapi-skeleton-output) |
| รีวิว API ก่อน Handoff | [references/review-checklist.md](references/review-checklist.md) |
| Security Checklist | [references/security-checklist.md](references/security-checklist.md) |

---

## กฎที่ต้องทำเสมอ

1. **ระบุ Assumption** ทุกครั้งที่ตั้งสมมติฐานเรื่อง consumer, auth, หรือ data
2. **หา Ambiguity** ก่อน produce output — อะไรที่ไม่ชัดต้องถามก่อน
3. **ระบุ Trade-off** เมื่อมีทางเลือก เช่น REST vs GraphQL, Offset vs Cursor
4. **ครอบคลุม Error Path** ทุก endpoint ต้องมี error case ไม่ใช่แค่ happy path
5. **Naming ต้องสอดคล้อง** ตลอด API — ตรวจก่อน output ทุกครั้ง
6. **Security ต้องระบุ** ทุก endpoint ต้องชัดว่า auth required หรือ public

---

## API Design Workflow

ทำตามลำดับนี้ทุกครั้ง อย่าข้ามขั้น

```
Step 1: Understand Context
  → ใคร call API นี้? (frontend, mobile, 3rd party, internal service)
  → frequency / volume โดยประมาณ?
  → data sensitivity? (มี PII, financial data ไหม?)
  → มี API เดิมที่ต้อง backward compatible ไหม?

Step 2: Clarify & Identify Gaps
  → หา Ambiguity ที่ต้องถามก่อน proceed
  → ระบุ Assumption ถ้า proceed ได้โดยไม่รอคำตอบ

Step 3: Resource Modeling
  → กำหนด Resource (noun) จาก domain
  → กำหนด Relationship ระหว่าง resource
  → ออกแบบ URL hierarchy

Step 4: Endpoint List
  → ระบุทุก endpoint: Method + Path + หน้าที่

Step 5: Request / Response Schema
  → ทุก field: name, type, required, validation, description
  → ทั้ง success และ error response

Step 6: Cross-cutting Concerns
  → Auth, Versioning, Pagination, Rate Limit, CORS

Step 7: Review
  → ใช้ references/review-checklist.md ตรวจก่อน output
```

---

## Resource Modeling

### หลักการตั้งชื่อ Resource

```
✅ ใช้ Noun (ไม่ใช่ Verb)
   /orders          ไม่ใช่  /getOrders
   /users           ไม่ใช่  /createUser

✅ ใช้ Plural เสมอ
   /products        ไม่ใช่  /product

✅ ใช้ lowercase + hyphen สำหรับ multi-word
   /order-items     ไม่ใช่  /orderItems หรือ /order_items

✅ Hierarchy แสดง Relationship
   /orders/{orderId}/items       ← items ของ order นั้น
   /users/{userId}/addresses     ← addresses ของ user นั้น

⚠️ ไม่ควรซ้อนเกิน 2 ระดับ
   /orders/{orderId}/items/{itemId}          ✅ OK
   /orders/{orderId}/items/{itemId}/reviews  ⚠️ พิจารณา flatten
   → แทนด้วย /order-item-reviews/{itemId}
```

### Output: Resource Map

```markdown
## Resource Map

| Resource | Path | Description |
|---|---|---|
| Orders | /orders | คำสั่งซื้อ |
| Order Items | /orders/{orderId}/items | รายการสินค้าในคำสั่งซื้อ |
| Products | /products | สินค้า |
| Users | /users | ผู้ใช้งาน |
```

---

## Endpoint List

### Format

```markdown
## Endpoint List: [Feature / Module Name]

| Method | Path | Description | Auth | Notes |
|---|---|---|---|---|
| GET | /orders | ดึง list ของ order | Required | รองรับ filter, pagination |
| POST | /orders | สร้าง order ใหม่ | Required | Idempotency-Key required |
| GET | /orders/{orderId} | ดึง order เดียว | Required | |
| PATCH | /orders/{orderId} | แก้ไข order | Required | ห้ามแก้เมื่อ status = shipped |
| DELETE | /orders/{orderId} | ยกเลิก order | Required | Soft delete, status → cancelled |
| GET | /orders/{orderId}/items | ดึง items ของ order | Required | |
| POST | /orders/{orderId}/items | เพิ่ม item เข้า order | Required | |
```

---

## Request & Response Design

### Request Schema Format

```markdown
### POST /orders — Request Body

| Field | Type | Required | Validation | Description |
|---|---|---|---|---|
| customer_id | string (UUID) | Yes | valid UUID | ID ของ customer |
| items | array | Yes | min 1 item | รายการสินค้า |
| items[].product_id | string (UUID) | Yes | valid UUID | ID ของสินค้า |
| items[].quantity | integer | Yes | min: 1, max: 999 | จำนวน |
| shipping_address_id | string (UUID) | Yes | valid UUID | ที่อยู่จัดส่ง |
| note | string | No | max: 500 chars | หมายเหตุ |

**Example Request:**
```json
{
  "customer_id": "usr_01HXYZ",
  "items": [
    { "product_id": "prd_ABC", "quantity": 2 }
  ],
  "shipping_address_id": "adr_DEF",
  "note": "กรุณาห่อของขวัญ"
}
```
```

### Response Schema Format

```markdown
### Response: 201 Created

| Field | Type | Description |
|---|---|---|
| id | string (UUID) | Order ID |
| status | string (enum) | สถานะ: pending, confirmed, shipped, delivered, cancelled |
| total_amount | number | ยอดรวม (บาท, 2 decimal) |
| items | array | รายการสินค้า |
| created_at | string (ISO 8601) | วันที่สร้าง |

**Example Response:**
```json
{
  "id": "ord_01HXYZ",
  "status": "pending",
  "total_amount": 1500.00,
  "items": [
    {
      "product_id": "prd_ABC",
      "product_name": "สินค้า A",
      "quantity": 2,
      "unit_price": 750.00,
      "subtotal": 1500.00
    }
  ],
  "created_at": "2025-01-15T10:30:00Z"
}
```
```

### Naming Convention สำหรับ Field

```
✅ ใช้ snake_case สำหรับ field name
   created_at, order_id, total_amount

✅ Timestamp ใช้ ISO 8601 + UTC เสมอ
   "2025-01-15T10:30:00Z"

✅ Boolean ใช้ prefix is_ / has_ / can_
   is_active, has_discount, can_edit

✅ Enum value ใช้ lowercase string
   "status": "pending"  ไม่ใช่  "status": 1 หรือ "PENDING"

✅ Amount / Money ใช้ number (2 decimal) + ระบุ currency แยก
   "amount": 1500.00, "currency": "THB"

⚠️ ไม่ expose internal ID จาก DB โดยตรง
   ใช้ prefixed ID: "ord_01HXYZ" แทน integer auto-increment
```

---

## Error Design

### Standard Error Format

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "ข้อมูลไม่ถูกต้อง",
    "details": [
      {
        "field": "items",
        "code": "MIN_ITEMS",
        "message": "ต้องมีสินค้าอย่างน้อย 1 รายการ"
      }
    ],
    "request_id": "req_01HXYZ"
  }
}
```

**กฎของ Error Response:**
- `code` — machine-readable, SCREAMING_SNAKE_CASE, ใช้ใน frontend logic
- `message` — human-readable, ห้าม expose stack trace หรือ DB error
- `details` — array สำหรับ validation error หลายจุดพร้อมกัน
- `request_id` — ทุก response ต้องมี เพื่อใช้ trace ใน log

### Error Code Catalog Format

```markdown
## Error Catalog

| HTTP Status | Error Code | เกิดเมื่อ |
|---|---|---|
| 400 | VALIDATION_ERROR | Input ไม่ผ่าน validation |
| 400 | INVALID_FORMAT | Format ผิด เช่น UUID, date |
| 400 | BUSINESS_RULE_VIOLATION | ละเมิด business rule เช่น ยกเลิก order ที่ shipped แล้ว |
| 401 | UNAUTHORIZED | ไม่มี token หรือ token invalid |
| 403 | FORBIDDEN | มี token แต่ไม่มีสิทธิ์ |
| 404 | NOT_FOUND | ไม่พบ resource |
| 409 | CONFLICT | ข้อมูลซ้ำ เช่น email ซ้ำ |
| 409 | OPTIMISTIC_LOCK_CONFLICT | มีคนแก้ข้อมูลไปก่อนแล้ว |
| 422 | UNPROCESSABLE_ENTITY | รูปแบบถูกแต่ process ไม่ได้ |
| 429 | RATE_LIMIT_EXCEEDED | เกิน rate limit |
| 500 | INTERNAL_ERROR | Server error (ไม่ expose detail) |
| 503 | SERVICE_UNAVAILABLE | ระบบชั่วคราวไม่พร้อม |
```

---

## Cross-cutting Concerns

### Auth Strategy

| Strategy | ใช้เมื่อ | ข้อควรระวัง |
|---|---|---|
| **JWT Bearer** | User-facing API, microservice | Token expiry, refresh flow |
| **API Key** | Server-to-server, 3rd party | Key rotation, ห้าม hardcode |
| **OAuth2** | User ต้อง delegate permission | Complex flow, ใช้เมื่อจำเป็นจริงๆ |

ระบุให้ชัดทุก endpoint: `Auth: Required / Public / Optional`

---

### Versioning Strategy

```
แนะนำ: URL Path Versioning
  /v1/orders
  /v2/orders

เหตุผล: ชัดเจน, debug ง่าย, cache ง่าย

เมื่อไรต้อง bump version?
  Breaking changes เท่านั้น:
  - ลบ field ออกจาก response
  - เปลี่ยน type ของ field
  - เปลี่ยน URL / Method
  - เปลี่ยน error code ที่ client ใช้อยู่

Non-breaking (ไม่ต้อง bump):
  - เพิ่ม optional field ใน response
  - เพิ่ม optional field ใน request
  - เพิ่ม endpoint ใหม่
```

---

### Pagination

เลือกตาม use case:

| แบบ | เมื่อใช้ | ข้อดี | ข้อเสีย |
|---|---|---|---|
| **Offset** `?page=2&limit=20` | UI มีเลขหน้า, ข้อมูลไม่ real-time | ง่าย, ข้าม page ได้ | ข้อมูลซ้ำ/หายถ้ามีการ insert ระหว่าง query |
| **Cursor** `?after=xyz&limit=20` | Infinite scroll, real-time feed | ถูกต้องเสมอ | ข้าม page ไม่ได้ |

**Response format สำหรับ Pagination:**
```json
{
  "data": [...],
  "pagination": {
    "total": 150,
    "page": 2,
    "limit": 20,
    "has_next": true,
    "has_prev": true
  }
}
```

---

### Rate Limit Headers

ทุก API ควร return headers เหล่านี้:

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 87
X-RateLimit-Reset: 1705312200
```

---

## OpenAPI Skeleton Output

เมื่อ design ครบแล้ว output เป็น OpenAPI YAML skeleton เพื่อ handoff ให้ dev:

```yaml
openapi: 3.0.3
info:
  title: [API Name]
  version: "1.0"
  description: [API Description]

servers:
  - url: https://api.example.com/v1
    description: Production
  - url: https://api-staging.example.com/v1
    description: Staging

security:
  - BearerAuth: []

components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT

  schemas:
    ErrorResponse:
      type: object
      properties:
        error:
          type: object
          properties:
            code:
              type: string
            message:
              type: string
            details:
              type: array
              items:
                type: object
            request_id:
              type: string

paths:
  /orders:
    get:
      summary: ดึง list ของ order
      tags: [Orders]
      parameters:
        - name: page
          in: query
          schema:
            type: integer
            default: 1
        - name: limit
          in: query
          schema:
            type: integer
            default: 20
            maximum: 100
        - name: status
          in: query
          schema:
            type: string
            enum: [pending, confirmed, shipped, delivered, cancelled]
      responses:
        "200":
          description: สำเร็จ
          content:
            application/json:
              schema:
                type: object
                properties:
                  data:
                    type: array
                    items:
                      $ref: "#/components/schemas/Order"
                  pagination:
                    $ref: "#/components/schemas/Pagination"
        "401":
          $ref: "#/components/responses/Unauthorized"

    post:
      summary: สร้าง order ใหม่
      tags: [Orders]
      parameters:
        - name: Idempotency-Key
          in: header
          required: true
          schema:
            type: string
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/CreateOrderRequest"
      responses:
        "201":
          description: สร้างสำเร็จ
        "400":
          $ref: "#/components/responses/ValidationError"
        "401":
          $ref: "#/components/responses/Unauthorized"
```

---

## Reference Files

อ่านเพิ่มเติมตามสถานการณ์:

- **[references/rest-guidelines.md](references/rest-guidelines.md)** — HTTP Method usage, Status Code ที่ถูกต้องแต่ละกรณี, URL naming rules
- **[references/request-response-patterns.md](references/request-response-patterns.md)** — Pagination patterns, Filter/Sort syntax, Bulk operation, File upload/download pattern
- **[references/security-checklist.md](references/security-checklist.md)** — Security checklist ก่อน release: auth, input validation, data exposure, rate limit
- **[references/review-checklist.md](references/review-checklist.md)** — API review checklist ก่อน handoff ให้ dev: naming, consistency, completeness
