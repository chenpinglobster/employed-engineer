# CLI Project Verification Strategy

**Project Type:** Command-Line Interface Application

## Detection Criteria

Matched when:
- `package.json` has `bin` field
- OR: Has executable with shebang in `src/index.ts` or `src/cli.ts`
- OR: `README.md` mentions "CLI" or "command-line"

## Verification Approach

**Focus:** stdout/stderr output, exit codes, file side effects

### Artifacts Required

| File | Content |
|------|---------|
| `cli_output.txt` | Captured stdout/stderr from test runs |
| `cli_assertions.json` | Expected vs actual assertions |
| `test_summary.txt` | Unit test results |

### Verification Steps

1. **Build Check**
   ```bash
   ./acceptance/run_allowed.sh build
   # Verify: dist/ or build/ contains executable
   ```

2. **Smoke Test**
   ```bash
   node dist/index.js --version
   # Verify: outputs version string, exit 0
   ```

3. **Functional Test**
   ```bash
   node dist/index.js <command> <args>
   # Verify: stdout matches expected pattern
   # Verify: side effects (files created, modified)
   ```

4. **Unit Tests**
   ```bash
   ./acceptance/run_allowed.sh test
   # Verify: all tests pass
   # Check: test coverage if available
   ```

## Assertion Types

### 1. Stdout Pattern
```json
{
  "type": "stdout_pattern",
  "pattern": "Added: \\d+\\. \\[ \\] .+",
  "expected_match": true
}
```

### 2. Exit Code
```json
{
  "type": "exit_code",
  "expected": 0
}
```

### 3. File Existence
```json
{
  "type": "file_exists",
  "path": "todos.json",
  "expected": true
}
```

### 4. JSON Content
```json
{
  "type": "json_content",
  "path": "todos.json",
  "selector": "todos[0].text",
  "expected": "Buy groceries"
}
```

### 5. File Content Pattern
```json
{
  "type": "file_pattern",
  "path": "output.log",
  "pattern": "SUCCESS.*completed",
  "expected_match": true
}
```

## Acceptance Criteria

✅ **PASS when:**
- All unit tests pass
- CLI commands produce expected output
- Exit codes match expectations
- Side effects (files, logs) are correct

❌ **FAIL when:**
- Unit tests fail
- Output doesn't match patterns
- Unexpected exit codes
- Side effects missing or incorrect

## Example CLI Assertions

```json
{
  "version": "1.0",
  "commands": [
    {
      "command": "node dist/index.js add 'Buy milk'",
      "assertions": [
        {
          "type": "exit_code",
          "expected": 0
        },
        {
          "type": "stdout_pattern",
          "pattern": "Added: 1\\. \\[ \\] Buy milk"
        },
        {
          "type": "file_exists",
          "path": "todos.json"
        }
      ]
    },
    {
      "command": "node dist/index.js list",
      "assertions": [
        {
          "type": "stdout_pattern",
          "pattern": "1\\. \\[ \\] Buy milk"
        }
      ]
    }
  ]
}
```

## Template Structure

For CLI projects, bootstrap with:

```
acceptance/
├── run_allowed.sh
├── smoke.sh
├── cli_test.sh          # CLI-specific E2E tests
└── artifacts/
    └── latest/
        ├── report.json
        ├── cli_output.txt
        └── cli_assertions.json
```

## Common Issues

| Issue | Detection | Fix |
|-------|-----------|-----|
| Missing executable | `dist/index.js` not found | Check build output path |
| Wrong exit code | Expected 0, got 1 | Check error handling |
| Output mismatch | Pattern doesn't match | Update CLI message format |
| File not created | Side effect missing | Check file write logic |

---

**Token efficiency:** Use CLI output directly from artifacts. Never read source code unless output analysis fails.
