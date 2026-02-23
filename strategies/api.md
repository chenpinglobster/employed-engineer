# API Project Verification Strategy

**Project Type:** REST/GraphQL API Server

## Detection Criteria

Matched when:
- Has `src/routes/` or `src/controllers/` directory
- OR: `package.json` dependencies include `express`, `fastify`, `koa`, `hapi`
- OR: Has `openapi.yaml` or `swagger.json`

## Verification Approach

**Focus:** HTTP status codes, response schemas, endpoint availability

### Artifacts Required

| File | Content |
|------|---------|
| `api_endpoints.json` | List of tested endpoints |
| `api_responses.json` | Actual responses from test runs |
| `test_summary.txt` | Integration test results |

### Verification Steps

1. **Build & Start**
   ```bash
   ./acceptance/run_allowed.sh build
   npm start &  # Or use test server
   sleep 2  # Wait for server ready
   ```

2. **Health Check**
   ```bash
   curl http://localhost:3000/health
   # Verify: 200 OK, {"status": "ok"}
   ```

3. **Endpoint Tests**
   ```bash
   # POST /api/users
   curl -X POST http://localhost:3000/api/users \
     -H "Content-Type: application/json" \
     -d '{"name": "Test User"}' \
     | tee artifacts/latest/response_post_user.json
   
   # Verify: 201 Created, response has user.id
   ```

4. **Integration Tests**
   ```bash
   ./acceptance/run_allowed.sh integration
   # Verify: all API tests pass
   ```

## Assertion Types

### 1. HTTP Status
```json
{
  "type": "http_status",
  "endpoint": "GET /api/users",
  "expected": 200
}
```

### 2. Response Schema
```json
{
  "type": "response_schema",
  "endpoint": "POST /api/users",
  "schema": {
    "type": "object",
    "required": ["id", "name"],
    "properties": {
      "id": {"type": "string"},
      "name": {"type": "string"}
    }
  }
}
```

### 3. Response Body
```json
{
  "type": "response_body",
  "endpoint": "GET /api/users/123",
  "path": "data.user.name",
  "expected": "Test User"
}
```

### 4. Response Time
```json
{
  "type": "response_time",
  "endpoint": "GET /api/users",
  "max_ms": 500
}
```

### 5. Database Side Effect
```json
{
  "type": "database_record",
  "table": "users",
  "condition": {"name": "Test User"},
  "expected_count": 1
}
```

## Acceptance Criteria

✅ **PASS when:**
- All endpoints return correct status codes
- Response schemas match OpenAPI/Swagger spec
- Integration tests pass
- No 500 errors in logs

❌ **FAIL when:**
- Wrong status codes (404 when expecting 200)
- Schema validation fails
- Integration tests fail
- Server crashes or errors

## Example API Assertions

```json
{
  "version": "1.0",
  "server": "http://localhost:3000",
  "endpoints": [
    {
      "method": "POST",
      "path": "/api/todos",
      "request": {
        "headers": {"Content-Type": "application/json"},
        "body": {"text": "Buy milk"}
      },
      "assertions": [
        {
          "type": "http_status",
          "expected": 201
        },
        {
          "type": "response_schema",
          "schema": {
            "type": "object",
            "required": ["id", "text", "done"],
            "properties": {
              "id": {"type": "number"},
              "text": {"type": "string"},
              "done": {"type": "boolean"}
            }
          }
        }
      ]
    },
    {
      "method": "GET",
      "path": "/api/todos",
      "assertions": [
        {
          "type": "http_status",
          "expected": 200
        },
        {
          "type": "response_body",
          "path": "[0].text",
          "expected": "Buy milk"
        }
      ]
    }
  ]
}
```

## Template Structure

For API projects, bootstrap with:

```
acceptance/
├── run_allowed.sh
├── smoke.sh
├── api_test.sh          # API E2E tests with curl/httpie
└── artifacts/
    └── latest/
        ├── report.json
        ├── api_endpoints.json
        ├── api_responses.json
        └── server_logs.txt
```

## Common Issues

| Issue | Detection | Fix |
|-------|-----------|-----|
| Server not starting | Connection refused | Check port binding, logs |
| Wrong status code | Expected 201, got 400 | Check request body validation |
| Schema mismatch | Extra/missing fields | Update schema or response |
| Timeout | Response > max_ms | Optimize query, add caching |

---

**Token efficiency:** Use API response artifacts. Never read route/controller code unless response analysis fails.
