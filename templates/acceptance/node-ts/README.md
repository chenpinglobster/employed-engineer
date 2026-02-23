# Acceptance Testing (Node.js/TypeScript)

This folder contains the acceptance testing infrastructure for EmployedEngineer workflow.

## Structure

```
acceptance/
├── run_allowed.sh      # Command wrapper (all commands go through here)
├── smoke.sh           # Minimal healthcheck
├── README.md          # This file
└── artifacts/
    └── latest/
        ├── report.json        # Structured test report
        ├── diffstat.txt       # Git diff statistics
        ├── test_summary.txt   # Test output summary
        ├── log_tail.txt       # Last 50 lines of output
        ├── commands.log       # Executed commands log
        └── dom_assertions.json # UI test results (if applicable)
```

## Usage

All commands must go through the wrapper:

```bash
# ✅ Correct - through wrapper
./acceptance/run_allowed.sh test
./acceptance/run_allowed.sh lint
./acceptance/run_allowed.sh build

# ❌ Wrong - direct commands are DENIED
npm test
pnpm lint
```

## Available Tasks

| Task | Description |
|------|-------------|
| `smoke` | Minimal healthcheck (deps installed, config valid) |
| `test` | Run unit tests |
| `lint` | Run linter |
| `typecheck` | Run TypeScript type checker |
| `format` | Run code formatter |
| `build` | Build the project |
| `e2e` | Run E2E tests (Playwright/Cypress) |
| `integration` | Run integration tests |

## Artifacts

After each task, artifacts are written to `artifacts/latest/`:

- **report.json**: Structured report following the schema
- **diffstat.txt**: Files changed (from git diff)
- **test_summary.txt**: Test results summary
- **log_tail.txt**: Last 50 lines of output
- **commands.log**: All commands executed with exit codes

## Test Isolation (IMPORTANT)

**All tests MUST use isolated temp files** to avoid cross-test contamination.

### Setup (vitest)

1. Copy `vitest.setup.ts` to your test directory
2. Import and use:

```typescript
import { getTempFile } from './vitest.setup';

describe('MyManager', () => {
  let manager: MyManager;
  
  beforeEach(() => {
    const testFile = getTempFile(); // Unique per test
    manager = new MyManager(testFile);
  });
  
  // Tests run isolated ✅
});
```

### Why This Matters

❌ **Bad** (shared file):
```typescript
const TEST_FILE = 'test-data.json'; // All tests use this
// Test 1 adds data → Test 2 sees it → FAIL
```

✅ **Good** (isolated):
```typescript
const testFile = getTempFile(); // Unique: test-1708567890-a3f2.json
// Test 1 and Test 2 never interfere
```

## For Claude Code

When implementing tasks:

1. Always use `./acceptance/run_allowed.sh <task>` for commands
2. **Use test isolation** (vitest.setup.ts or similar)
3. Ensure `report.json` is updated with results
4. Include relevant artifacts in acceptance criteria verification
5. If tests fail, provide minimal evidence in the report

## For OpenClaw (Verifier)

When verifying:

1. Check `artifacts/latest/report.json` first (Level 0)
2. Only escalate to patch hunks if report is insufficient (Level 1)
3. Never read full source files unless absolutely necessary (Level 2)
