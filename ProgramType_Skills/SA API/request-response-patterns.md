# Request & Response Patterns Reference

## Table of Contents
- [Pagination Patterns](#pagination-patterns)
- [Filter & Sort Patterns](#filter--sort-patterns)
- [Bulk Operations](#bulk-operations)
- [File Upload Pattern](#file-upload-pattern)
- [File Download Pattern](#file-download-pattern)
- [Async / Long-running Operation](#async--long-running-operation)
- [Partial Update (PATCH) Pattern](#partial-update-patch-pattern)

---

## Pagination Patterns

### Offset Pagination

เหมาะกับ: UI มีเลขหน้า, ข้อมูลค่อนข้าง static

**Request:**
```
GET /orders?page=2&limit=20
```

**Response:**
```json
{
  "data": [...],
  "pagination": {
    "total": 150,
    "page": 2,
    "limit": 20,
    "total_pages": 8,
    "has_next": true,
    "has_prev": true
  }
}
```

**ข้อเสีย:** ถ้ามีการ insert ข้อมูลระหว่าง paginate อาจได้ข้อมูลซ้ำหรือหาย

---

### Cursor Pagination

เหมาะกับ: Infinite scroll, real-time feed, ข้อมูลเปลี่ยนบ่อย

**Request:**
```
GET /feed?limit=20
GET /feed?after=cursor_abc123&limit=20   ← ดูหน้าถัดไป
GET /feed?before=cursor_xyz789&limit=20  ← ดูหน้าก่อนหน้า
```

**Response:**
```json
{
  "data": [...],
  "pagination": {
    "has_next": true,
    "has_prev": false,
    "next_cursor": "cursor_abc123",
    "prev_cursor": null
  }
}
```

**ข้อเสีย:** ข้าม page โดยตรงไม่ได้, ไม่รู้ total count

---

## Filter & Sort Patterns

### Standard Filter

```
GET /orders?status=pending
GET /orders?status=pending,confirmed          ← OR multiple values
GET /orders?min_amount=100&max_amount=500     ← range
GET /orders?created_from=2025-01-01&created_to=2025-01-31
GET /orders?customer_id=usr_ABC              ← by relation
```

### Sort

```
GET /orders?sort=created_at_desc
GET /orders?sort=amount_asc,created_at_desc  ← multi-sort
```

### Combined

```
GET /orders?status=pending&sort=created_at_desc&page=1&limit=20
```

---

## Bulk Operations

### Bulk Create

```
POST /orders/bulk

Request:
{
  "items": [
    { "product_id": "prd_A", "quantity": 2 },
    { "product_id": "prd_B", "quantity": 1 }
  ]
}

Response: 207 Multi-Status
{
  "results": [
    { "index": 0, "status": "created", "id": "ord_001" },
    { "index": 1, "status": "error", "error": { "code": "NOT_FOUND", "message": "Product not found" } }
  ],
  "summary": {
    "total": 2,
    "succeeded": 1,
    "failed": 1
  }
}
```

> ใช้ **207 Multi-Status** เมื่อ result บางส่วนสำเร็จ บางส่วน fail

### Bulk Delete

```
DELETE /orders/bulk

Request body:
{
  "ids": ["ord_001", "ord_002", "ord_003"]
}

Response: 207 Multi-Status (ถ้ามี partial fail)
หรือ 204 No Content (ถ้าสำเร็จทั้งหมด)
```

---

## File Upload Pattern

### Single File Upload (multipart/form-data)

```
POST /documents/upload
Content-Type: multipart/form-data

Form fields:
  file: [binary]
  document_type: "invoice"  (optional metadata)

Response: 201 Created
{
  "id": "doc_01HXYZ",
  "filename": "invoice_2025.pdf",
  "size": 204800,
  "mime_type": "application/pdf",
  "url": "https://...",       ← signed URL ถ้าต้องการ auth
  "expires_at": "2025-01-16T10:30:00Z"
}
```

### Two-step Upload (Presigned URL pattern)

เหมาะกับไฟล์ขนาดใหญ่ — upload ตรงไป Storage โดยไม่ผ่าน API server

```
Step 1: ขอ upload URL
POST /documents/upload-url
{
  "filename": "report.pdf",
  "mime_type": "application/pdf",
  "size": 5242880
}

Response:
{
  "upload_url": "https://storage.example.com/presigned?token=...",
  "upload_id": "upl_01HXYZ",
  "expires_at": "2025-01-15T11:00:00Z"   ← URL หมดอายุใน 15 นาที
}

Step 2: Upload ไฟล์โดยตรงไปยัง upload_url (PUT)

Step 3: แจ้ง API ว่า upload เสร็จแล้ว
POST /documents/upload-url/upl_01HXYZ/complete
→ API ตรวจสอบและ activate document
```

---

## File Download Pattern

### Direct Download (ไฟล์เล็ก หรือ public)

```
GET /documents/{id}/download

Response:
Content-Type: application/pdf
Content-Disposition: attachment; filename="invoice_2025.pdf"
[binary content]
```

### Signed URL Download (ไฟล์ใหญ่ หรือต้องการ auth)

```
GET /documents/{id}/download-url

Response:
{
  "url": "https://storage.example.com/...",
  "expires_at": "2025-01-15T11:15:00Z"
}
```
Client redirect ไปยัง URL โดยตรง

---

## Async / Long-running Operation

ใช้เมื่อ operation ใช้เวลานาน เช่น export รายงาน, batch processing, video processing

### Pattern

```
Step 1: ส่ง request
POST /reports/export
{
  "type": "sales",
  "date_from": "2025-01-01",
  "date_to": "2025-12-31"
}

Response: 202 Accepted
{
  "job_id": "job_01HXYZ",
  "status": "queued",
  "status_url": "/reports/export/jobs/job_01HXYZ"
}

Step 2: Poll status
GET /reports/export/jobs/job_01HXYZ

Response (กำลัง process):
{
  "job_id": "job_01HXYZ",
  "status": "processing",
  "progress": 45,
  "estimated_completion": "2025-01-15T10:45:00Z"
}

Response (เสร็จแล้ว):
{
  "job_id": "job_01HXYZ",
  "status": "completed",
  "result": {
    "download_url": "https://...",
    "expires_at": "2025-01-16T10:30:00Z"
  }
}

Response (ล้มเหลว):
{
  "job_id": "job_01HXYZ",
  "status": "failed",
  "error": { "code": "TIMEOUT", "message": "การสร้างรายงานใช้เวลานานเกินไป" }
}
```

**Job Status Values:** `queued` → `processing` → `completed` / `failed` / `cancelled`

---

## Partial Update (PATCH) Pattern

### JSON Merge Patch (RFC 7396) — แนะนำสำหรับส่วนใหญ่

ส่งเฉพาะ field ที่ต้องการเปลี่ยน:

```
PATCH /users/{userId}
{
  "name": "ชื่อใหม่",
  "phone": "0812345678"
}
```

- field ที่ไม่ส่งมา → ไม่เปลี่ยน
- field ที่ส่งมาเป็น `null` → set เป็น null (ถ้า nullable)

### ข้อควรระวัง PATCH

```
⚠️ ต้องระบุใน spec ว่า field ไหน immutable (ห้ามแก้)
   เช่น: created_at, order_id, customer_id

⚠️ ต้องระบุ business rule ที่ block การแก้
   เช่น: ห้ามแก้ amount หลัง status = confirmed
```
