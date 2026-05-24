# 05 API Specification

## API Summary
| ID | Name | Method | URL | Auth | Purpose |
|---|---|---|---|---|---|
| API-001 |  | GET/POST/PUT/PATCH/DELETE | `/api/...` | Required/None |  |

## Organization Default API Convention

Use this default only when accepted by the SA.

- Auth: `X-API-Key` + `X-Client-Id`
- Tracking: `X-Request-Id`, `X-Correlation-Id`, `X-Timestamp`
- Response headers: `X-Trace-Id`, `X-Request-Id`, `X-Response-Time`, `X-Api-Version`
- Error format: `{"success":false,"error":"...","message":"..."}`

## API Detail: API-001

### Purpose

### Endpoint
- Method:
- URL:

### Headers
| Header | Required | Example | Description |
|---|---|---|---|
| X-API-Key | Conditional | `{apiKey}` | API key credential when using organization default auth |
| X-Client-Id | Conditional | `SYSTEM_ABC` | Client/system identifier when using organization default auth |
| X-Request-ID | Yes | uuid | Request correlation id |
| X-Correlation-Id | No | `TXN-20260505-001` | Business transaction id |
| X-Timestamp | Conditional | `2026-05-05T10:00:00+07:00` | Request timestamp when skew validation is enabled |

### Path Parameters
| Name | Type | Required | Description |
|---|---|---|---|
|  |  | Yes/No |  |

### Query Parameters
| Name | Type | Required | Description |
|---|---|---|---|
|  |  | Yes/No |  |

### Request Body
```json
{}
```

### Response Body
```json
{}
```

### Error Responses
| HTTP Status | Error Code | Message | Cause |
|---|---|---|---|
| 400 | VALIDATION_ERROR | Invalid request data | Required field missing or invalid |
| 401 | UNAUTHORIZED | Unauthorized | Token missing or invalid |
| 403 | FORBIDDEN | Forbidden | User has no permission |
| 404 | NOT_FOUND | Not found | Resource does not exist |
| 500 | INTERNAL_ERROR | Internal server error | Unexpected error |

### Business Rules
- 

### Logging Points
- 

### Response Headers
| Header | Required | Description |
|---|---|---|
| X-Trace-Id | Yes | Trace id for investigation |
| X-Request-Id | Conditional | Echo request id when provided |
| X-Response-Time | Yes | Processing time in milliseconds |
| X-Api-Version | Yes | API version |
