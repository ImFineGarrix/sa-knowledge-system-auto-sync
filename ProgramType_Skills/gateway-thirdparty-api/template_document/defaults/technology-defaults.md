# Technology Defaults

Use these defaults only when the SA accepts the organization default stack.

## Backend

- Framework: Spring Boot 3.x
- Runtime: Java 21
- Build: Maven
- API style: REST/JSON
- Security: Spring Security
- Internal HTTP client: Spring Cloud OpenFeign
- Logging: structured JSON logs with MDC trace id
- Health check: Spring Boot Actuator

## Data / Cache

- Primary relational database: MySQL
- Persistence: Spring Data JPA
- API key lookup/cache: Redis
- Redis client: Lettuce

## Deployment

- Container image: multi-stage Dockerfile
- Runtime image: `eclipse-temurin:21-jre-alpine`
- Reverse proxy/TLS: Nginx
- Deployment baseline: Docker Compose on RHEL 9
- Secret handling: `.env` on server, `.env.example` in Git, never commit real `.env`

## Suggested Dependencies

Gateway:

- `spring-boot-starter-web`
- `spring-boot-starter-security`
- `spring-boot-starter-actuator`
- `spring-boot-starter-data-redis`
- `spring-cloud-starter-openfeign`
- `lombok`

Backend:

- `spring-boot-starter-web`
- `spring-boot-starter-security`
- `spring-boot-starter-actuator`
- `spring-boot-starter-data-jpa`
- `mysql-connector-j`
- `lombok`

