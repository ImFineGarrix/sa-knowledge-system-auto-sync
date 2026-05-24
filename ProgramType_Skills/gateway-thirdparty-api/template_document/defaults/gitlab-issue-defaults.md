# GitLab Issue Defaults

Use this split when the project is a multi-service API implementation.

## Default Issue Split

| Issue | Title Pattern | Labels | Purpose |
|---|---|---|---|
| #1 | `[SETUP] Initial project setup — {services}` | `setup`, `backend`, `priority::high` | Create project structure, dependencies, Dockerfile, health checks |
| #2 | `[FEAT] Implement X-API-Key authentication — {gateway}` | `feature`, `security`, `backend`, `priority::high` | API key auth, trace filters, response headers |
| #3 | `[FEAT] Implement API endpoints + proxy — {gateway}` | `feature`, `backend`, `priority::high` | Public endpoints, validation, proxy to backend |
| #4 | `[FEAT] Implement business logic + database/security — {backend}` | `feature`, `security`, `backend`, `database`, `priority::high` | Internal auth, DB entities, business logic, encryption |
| #5 | `[INFRA] Docker Compose setup + deployment — {services}` | `infrastructure`, `devops`, `priority::medium` | Compose, Nginx, env, deployment, smoke test |

## Default Issue Sections

Each issue should include:

- Objective
- Dependencies
- Scope / services
- Tasks
- References
- Definition of Done

## Default Dependency Pattern

```text
Issue #1 Setup
  -> Issue #2 Auth
    -> Issue #3 Gateway APIs/proxy
  -> Issue #4 Backend logic
Issue #3 + Issue #4
  -> Issue #5 Infra/deployment
```

## Default Labels

- `setup`
- `feature`
- `security`
- `backend`
- `database`
- `infrastructure`
- `devops`
- `priority::high`
- `priority::medium`
- `priority::low`

