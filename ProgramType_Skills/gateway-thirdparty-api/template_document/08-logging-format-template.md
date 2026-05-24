# 08 Logging Format

## Logging Objectives
- Trace user transactions end to end.
- Support troubleshooting and audit requirements.
- Avoid storing sensitive data in logs.

## Required Log Fields
| Field | Required | Description | Example |
|---|---|---|---|
| timestamp | Yes | ISO-8601 date/time | 2026-04-30T10:00:00+07:00 |
| level | Yes | DEBUG/INFO/WARN/ERROR | INFO |
| service | Yes | Service name | order-api |
| environment | Yes | Runtime environment | uat |
| request_id | Yes | Request correlation id | uuid |
| user_id | Conditional | Authenticated user id | U001 |
| event | Yes | Event name | order.created |
| message | Yes | Human-readable message | Order created successfully |
| data | No | Safe structured metadata | {} |

## Organization Default Trace Fields
| Field/Header | Purpose |
|---|---|
| X-Trace-Id / traceId | End-to-end trace id |
| X-Request-Id / requestId | Caller request id |
| X-Correlation-Id / correlationId | Business transaction id |
| X-Response-Time / durationMs | API processing time |
| X-Api-Version | API version |
| clientId | Authenticated client/system |

## Event Naming
Use `{domain}.{action}` format.

Examples:
- `auth.login_success`
- `order.created`
- `payment.failed`

For organization default API projects, event names may use uppercase operational names:

- `API_KEY_VALIDATED`
- `API_KEY_MISSING`
- `API_KEY_INVALID`
- `CLIENT_ID_MISSING`
- `PROXY_REQUEST_SENT`
- `PROXY_RESPONSE_OK`
- `PROXY_UPSTREAM_ERROR`
- `PROXY_UNREACHABLE`
- `REQUEST_COMPLETE`
- `DB_QUERY_ERROR`

## Sensitive Data Rule
Never log passwords, tokens, OTP, full card numbers, national ID, or raw personal data unless explicitly approved and masked.

## Example
```json
{
  "timestamp": "2026-04-30T10:00:00+07:00",
  "level": "INFO",
  "service": "sample-api",
  "environment": "uat",
  "request_id": "2cc2b1b8-4f7d-4d91-a4e9-19e4e9a79f99",
  "user_id": "U001",
  "event": "sample.created",
  "message": "Sample record created",
  "data": {
    "sample_id": 123
  }
}
```
