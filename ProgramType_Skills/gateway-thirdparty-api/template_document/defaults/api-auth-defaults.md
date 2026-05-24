# API / Authentication Defaults

Use these defaults as the first recommendation for partner-facing REST APIs when the SA has not selected another approach.

## Public API Auth

- Authentication: `X-API-Key`
- Client identity: `X-Client-Id`
- Request tracking: `X-Request-Id`
- Business transaction tracking: `X-Correlation-Id`
- Replay/skew control: `X-Timestamp`
- API version response header: `X-Api-Version`
- Response trace header: `X-Trace-Id`
- Response timing header: `X-Response-Time`

## Required Request Headers

| Header | Default Requirement | Purpose |
|---|---|---|
| `X-API-Key` | Required | API credential for partner/client |
| `X-Client-Id` | Required | Client/system identifier |
| `X-Request-Id` | Recommended/Required by project | Unique request tracking id |
| `X-Correlation-Id` | Optional | Business transaction reference |
| `X-Timestamp` | Optional/Required by project | ISO-8601 timestamp, validate skew when enabled |
| `Content-Type` | Required for body requests | `application/json` |

## API Key Validation Pattern

Default flow:

```text
Request
  -> validate X-Client-Id
  -> validate X-API-Key
  -> hash raw key with SHA-256
  -> lookup Redis key apikey:{sha256hex}
  -> reject null/revoked key
  -> validate X-Timestamp skew when enabled
  -> set authenticated client context
  -> continue request
```

## Redis Key Convention

```text
Key:   apikey:{SHA-256 hex of raw key}
Value: {"clientId":"SYSTEM_ABC","status":"active","createdAt":"ISO8601"}
TTL:   none unless the project defines expiry
```

## Standard Error Response

```json
{
  "success": false,
  "error": "Unauthorized",
  "message": "Missing or invalid X-API-Key"
}
```

## Internal Service Auth

When a public gateway proxies to an internal backend, the default internal auth is HTTP Basic Auth with a service account.

Forward these headers to backend:

- `X-Trace-Id`
- `X-Authenticated-Client`
- `X-Request-Id`
- `X-Correlation-Id`

Do not forward these external credentials to backend unless explicitly approved:

- `X-API-Key`
- `X-Client-Id`
- `X-Timestamp`

