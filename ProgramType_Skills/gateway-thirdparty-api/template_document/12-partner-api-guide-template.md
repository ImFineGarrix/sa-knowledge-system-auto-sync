# 12 Partner API Guide

## Document Control
| Item | Value |
|---|---|
| API name |  |
| Version |  |
| Owner |  |
| Target partner |  |
| Last updated |  |
| Status | Draft/Ready |

## Overview
Describe what this API is for, who should use it, and the business flow it supports.

## Environment
| Environment | Base URL | Purpose |
|---|---|---|
| UAT | `https://uat-api.example.com` | Partner testing |
| Production | `https://api.example.com` | Production use |

## Authentication
Describe the authentication method selected by the SA.

Organization default:

- `X-API-Key`: partner credential
- `X-Client-Id`: partner/client identifier
- `X-Timestamp`: ISO-8601 timestamp, validate skew when enabled

Other options when customized by SA:

- Bearer token / JWT
- OAuth2
- Mutual TLS
- Custom partner credential

## Required Headers
| Header | Required | Example | Description |
|---|---|---|---|
| X-API-Key | Conditional | `{apiKey}` | Partner API key when using organization default auth |
| X-Client-Id | Conditional | `SYSTEM_ABC` | Partner/client identifier |
| X-Request-Id | Yes | uuid | Unique request tracking id |
| X-Correlation-Id | No | `TXN-20260505-001` | Business transaction reference |
| X-Timestamp | Conditional | `2026-05-05T10:00:00+07:00` | Request timestamp when skew validation is enabled |
| Content-Type | Yes | `application/json` | Request content type |

## Endpoint Summary
| API | Method | Path | Purpose |
|---|---|---|---|
|  | GET/POST/PUT/PATCH/DELETE | `/api/...` |  |

## Endpoint Detail

### API-001: {API name}

#### Purpose

#### Request
- Method:
- Path:
- Auth:

#### Headers
| Header | Required | Description |
|---|---|---|
|  | Yes/No |  |

#### Request Body
```json
{}
```

#### Success Response
```json
{}
```

#### Error Responses
| HTTP Status | Error Code | Message | Partner Action |
|---|---|---|---|
| 400 | VALIDATION_ERROR | Invalid request data | Check request payload |
| 401 | UNAUTHORIZED | Unauthorized | Check credential |
| 403 | FORBIDDEN | Forbidden | Contact API owner |
| 429 | RATE_LIMITED | Too many requests | Retry after waiting |
| 500 | INTERNAL_ERROR | Internal server error | Retry or contact support |

## Rate Limit / Usage Constraints
- Request limit:
- Burst limit:
- Payload size limit:
- Attachment/file size limit:

## Timeout and Retry Guidance
- Client timeout:
- Retry count:
- Retry interval:
- Idempotency rule:

Organization default when applicable:

- Connect timeout: 3 seconds
- Read timeout: 10 seconds for upstream calls
- Partner should retry only idempotent requests unless the API explicitly supports idempotency keys

## Webhook / Callback
Complete this section only when the integration uses webhook or callback.

| Item | Detail |
|---|---|
| Callback URL owner | Partner/System owner |
| Method | POST |
| Auth |  |
| Retry rule |  |

## UAT Checklist
- [ ] Partner received base URL.
- [ ] Partner received credential through secure channel.
- [ ] Partner imported Postman collection.
- [ ] Partner configured Postman environment.
- [ ] Partner confirmed required headers.
- [ ] Happy path tested.
- [ ] Error path tested.
- [ ] Request ID/correlation confirmed.
- [ ] `X-Trace-Id` returned and usable for support.
- [ ] Go-live contact confirmed.

## Support Contact
| Topic | Contact | Channel |
|---|---|---|
| Technical support |  |  |
| Business support |  |  |
| Incident escalation |  |  |

## Changelog
| Version | Date | Change | Impact |
|---|---|---|---|
| 1.0.0 |  | Initial version |  |
