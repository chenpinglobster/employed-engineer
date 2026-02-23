# Library Project Verification Strategy

**Project Type:** Reusable Library/Package

## Detection Criteria

Matched when:
- `package.json` has `main` or `exports` field but NO `bin` field
- OR: `pyproject.toml` has `[build-system]` but no `[project.scripts]`
- OR: `Cargo.toml` has `[lib]` section

## Verification Approach

**Focus:** API contract, type definitions, unit test coverage

### Artifacts Required

| File | Content |
|------|---------|
| `api_surface.json` | Public API exports |
| `test_coverage.json` | Coverage report (from vitest/jest/pytest) |
| `type_check.txt` | TypeScript/mypy output |

### Verification Steps

1. **Build**
   ```bash
   ./acceptance/run_allowed.sh build
   # Verify: dist/ contains compiled output
   ```

2. **Type Check**
   ```bash
   ./acceptance/run_allowed.sh typecheck
   # Verify: no type errors
   ```

3. **Unit Tests**
   ```bash
   ./acceptance/run_allowed.sh test
   # Verify: all tests pass, coverage > threshold
   ```

4. **API Contract**
   ```bash
   # Extract exports from built library
   node -e "console.log(Object.keys(require('./dist')))"
   # Verify: matches expected API surface
   ```

## Assertion Types

### 1. API Exports
```json
{
  "type": "api_exports",
  "expected": ["TodoManager", "Todo", "TodoStore"],
  "all_present": true
}
```

### 2. Type Definitions
```json
{
  "type": "type_definitions",
  "file": "dist/index.d.ts",
  "exports": ["TodoManager", "Todo"],
  "expected": true
}
```

### 3. Test Coverage
```json
{
  "type": "test_coverage",
  "lines": 85,
  "functions": 90,
  "branches": 80,
  "min_threshold": 80
}
```

### 4. Unit Test Results
```json
{
  "type": "unit_tests",
  "total": 42,
  "passed": 42,
  "failed": 0
}
```

### 5. API Compatibility
```json
{
  "type": "api_compatibility",
  "breaking_changes": [],
  "new_exports": ["clearAll"],
  "deprecated": []
}
```

## Acceptance Criteria

✅ **PASS when:**
- All unit tests pass
- Test coverage meets threshold (usually 80%+)
- Type checking passes
- Public API matches contract
- No breaking changes (for existing libs)

❌ **FAIL when:**
- Unit tests fail
- Coverage below threshold
- Type errors exist
- Missing expected exports
- Unexpected breaking changes

## Example Library Assertions

```json
{
  "version": "1.0",
  "library": "todo-manager",
  "assertions": [
    {
      "type": "api_exports",
      "expected": ["TodoManager", "Todo", "TodoStore"],
      "all_present": true
    },
    {
      "type": "test_coverage",
      "lines": 92,
      "functions": 95,
      "branches": 88,
      "min_threshold": 80,
      "pass": true
    },
    {
      "type": "unit_tests",
      "total": 22,
      "passed": 22,
      "failed": 0
    },
    {
      "type": "type_definitions",
      "file": "dist/index.d.ts",
      "exports_found": true
    }
  ]
}
```

## Template Structure

For library projects, bootstrap with:

```
acceptance/
├── run_allowed.sh
├── smoke.sh
├── api_test.sh          # API surface verification
└── artifacts/
    └── latest/
        ├── report.json
        ├── api_surface.json
        ├── test_coverage.json
        └── type_check.txt
```

## Common Issues

| Issue | Detection | Fix |
|-------|-----------|-----|
| Missing export | API surface incomplete | Add to index.ts exports |
| Low coverage | < 80% threshold | Add missing tests |
| Type errors | tsc fails | Fix type definitions |
| Breaking change | API changed | Document or revert |

## Special Considerations

### For npm libraries:
- Verify `package.json` exports are correct
- Check `"types"` field points to .d.ts
- Ensure `"files"` includes all dist assets

### For Python libraries:
- Verify `__init__.py` exports
- Check `py.typed` marker exists
- Ensure type stubs are included

### For Rust crates:
- Verify `pub` exports in `lib.rs`
- Check `Cargo.toml` metadata
- Ensure examples compile

---

**Token efficiency:** Use API surface and coverage artifacts. Never read implementation unless contract verification fails.
