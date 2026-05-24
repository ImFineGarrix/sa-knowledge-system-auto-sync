# Postman Defaults

Use these defaults for generated Postman collections unless the SA chooses another style.

## Collection Variables

- `gateway_url`
- `backend_url` when internal backend tests are included
- `api_key`
- `client_id`
- `basic_user` when internal Basic Auth tests are included
- `basic_pass` when internal Basic Auth tests are included
- `last_trace_id`

For external partner collections, replace real values with placeholders and do not include internal backend URLs unless approved.

## Pre-request Script

Generate:

- `auto_request_id`: UUID v4
- `auto_timestamp`: current ISO timestamp

## Default Folders

1. Health Check
2. Main API happy paths
3. Error Scenarios
4. Internal direct backend tests, only for internal/dev collections

## Default Request Headers

- `X-API-Key: {{api_key}}`
- `X-Client-Id: {{client_id}}`
- `X-Request-Id: {{auto_request_id}}`
- `X-Correlation-Id: {business transaction id}`
- `X-Timestamp: {{auto_timestamp}}`

## Default Tests

- Assert expected HTTP status.
- Assert `success` flag when response uses it.
- Assert key business fields.
- Assert sensitive fields are encrypted/masked when applicable.
- Assert response headers: `X-Trace-Id`, `X-Api-Version`, and optionally `X-Request-Id`, `X-Response-Time`.

## Default Error Scenarios

- Missing `X-API-Key` -> 401
- Invalid `X-API-Key` -> 401
- Revoked `X-API-Key` -> 401 when revocation exists
- Missing `X-Client-Id` -> 400
- Resource not found -> 404
- Missing required query/body field -> 400
- Timestamp out of range -> 400 when timestamp validation exists

