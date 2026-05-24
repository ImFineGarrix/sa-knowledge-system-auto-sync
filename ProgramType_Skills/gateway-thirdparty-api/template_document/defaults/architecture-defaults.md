# Architecture Defaults

Use this as the default proposed architecture when the project is a partner-facing REST API with an internal backend.

## Default Components

| Component | Default Technology | Responsibility |
|---|---|---|
| Nginx | Nginx + TLS | Public HTTPS entry, reverse proxy, forwarding headers |
| Gateway service | Spring Boot | Public-facing API, X-API-Key auth, trace headers, proxy |
| Backend service | Spring Boot | Internal business logic, DB access, internal auth |
| Redis | Redis | API key lookup/cache |
| Database | MySQL | Persistent business data |

## Default Flow

```text
Partner
  -> Nginx/TLS
  -> Gateway
  -> Redis API key validation
  -> Backend via Feign
  -> MySQL
  -> Backend response
  -> Gateway response headers/logging
  -> Partner
```

## Default Source Blueprint

Gateway package suggestion:

```text
config/      SecurityConfig, RedisConfig
filter/      ApiKeyAuthFilter, TraceIdFilter, ResponseHeaderFilter
controller/  GatewayController
proxy/       BackendProxy
service/     ApiKeyService
model/       ApiKeyInfo, ErrorResponse
```

Backend package suggestion:

```text
config/       SecurityConfig
filter/       TraceIdFilter
controller/   InternalController
service/      Business services
repository/   JPA repositories
entity/       JPA entities
encryption/   FieldEncryptionService, converters
model/        Request/response/error models
```

## Default Deployment

- Nginx exposes 80/443.
- Gateway runs on internal port 8080.
- Backend runs on internal port 8081.
- Redis runs on internal port 6379.
- MySQL runs on internal port 3306.
- All services run on a private Docker bridge network.

