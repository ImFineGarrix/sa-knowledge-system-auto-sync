# Logging Defaults

Use structured logs and trace every request across gateway and backend.

## Trace Headers

- `X-Trace-Id`: generated or accepted by gateway, returned to caller.
- `X-Request-Id`: echoed from caller when provided.
- `X-Correlation-Id`: business transaction id when provided.
- `X-Response-Time`: processing time in milliseconds.
- `X-Api-Version`: API version that handled the request.

## MDC / Context

Add these to log context when available:

- `traceId`
- `requestId`
- `correlationId`
- `clientId`
- `service`
- `path`
- `method`
- `status`
- `durationMs`

Always clear MDC/context in a `finally` block.

## Default Event Names

Authentication:

- `API_KEY_VALIDATED`
- `API_KEY_MISSING`
- `API_KEY_INVALID`
- `CLIENT_ID_MISSING`
- `BASIC_AUTH_OK`
- `BASIC_AUTH_FAILED`

Proxy / integration:

- `PROXY_REQUEST_SENT`
- `PROXY_RESPONSE_OK`
- `PROXY_UPSTREAM_ERROR`
- `PROXY_UNREACHABLE`

Business/data:

- `PROFILE_QUERY_START`
- `PROFILE_FETCHED`
- `PROFILE_NOT_FOUND`
- `CREDIT_QUERY_START`
- `CREDIT_FETCHED`
- `CREDIT_NOT_FOUND`
- `DB_QUERY_ERROR`

Security/encryption:

- `FIELD_ENCRYPT_OK`
- `FIELD_ENCRYPT_FAILED`

Request lifecycle:

- `REQUEST_COMPLETE`

## Sensitive Data Rule

Never log raw API keys, passwords, tokens, full personal data, raw encrypted secrets, or production credentials. Log only masked values or safe identifiers.

