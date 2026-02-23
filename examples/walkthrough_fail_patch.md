# Walkthrough: Failure → Patch → Success

This example shows how EmployedEngineer handles a failing implementation and guides Claude Code to fix it.

## Scenario

**Task**: Add input validation to a form
**Initial Result**: Tests fail due to missing edge case handling

---

## Phase 1: Initial Implementation

Claude Code implements form validation but misses an edge case.

### VERIFY Phase

```bash
cat acceptance/artifacts/latest/report.json
```

```json
{
  "version": "1.0",
  "timestamp": "2026-02-20T14:00:00+08:00",
  "task": {
    "id": "form-validation",
    "description": "Add input validation to registration form",
    "acceptance_criteria": [
      {"criterion": "Email format validated", "met": true},
      {"criterion": "Password strength checked", "met": true},
      {"criterion": "Empty fields rejected", "met": false, "evidence": "Test 'empty username shows error' failed"},
      {"criterion": "Error messages displayed", "met": true}
    ]
  },
  "status": "fail",
  "tests": {
    "total": 12,
    "passed": 11,
    "failed": 1,
    "skipped": 0,
    "failures": [
      {
        "name": "empty username shows error",
        "error": "Expected: 'Username is required' / Actual: undefined",
        "file": "src/components/Form.test.tsx",
        "line": 45
      }
    ]
  },
  "files_changed": {
    "added": [],
    "modified": ["src/components/Form.tsx", "src/utils/validation.ts"],
    "deleted": []
  }
}
```

---

## Phase 2: ACCEPT → FAIL

### 2.1 OpenClaw Reviews (Level 0)

```
Checking artifacts:
❌ status: "fail"
❌ 1 test failure: "empty username shows error"
❌ Acceptance criterion "Empty fields rejected" not met

Verdict: FAIL
Proceeding to PATCH phase
```

### 2.2 Evidence Collection

OpenClaw collects minimal evidence for the patch request:

```
From report.json:
- Failing test: "empty username shows error"
- Expected: 'Username is required'
- Actual: undefined
- File: src/components/Form.test.tsx:45
```

---

## Phase 3: PATCH

### 3.1 Generate Minimal Fix Request

OpenClaw sends to Claude Code:

```
🔧 修補請求

測試失敗: "empty username shows error"
- 預期: 'Username is required'
- 實際: undefined
- 位置: src/components/Form.test.tsx:45

問題: username 空值時沒有顯示錯誤訊息

請修復後重新執行 ./acceptance/run_allowed.sh test
```

### 3.2 Claude Code Responds

```
Claude Code: "I see the issue. The validation function isn't checking for empty username. Let me fix that."

"Do you want to run ./acceptance/run_allowed.sh test? (y/N)"
```

OpenClaw: `submit "y"` (AUTO-APPROVE)

---

## Phase 4: Re-VERIFY

### 4.1 Check Updated Artifacts

```bash
cat acceptance/artifacts/latest/report.json
```

```json
{
  "version": "1.0",
  "timestamp": "2026-02-20T14:05:00+08:00",
  "task": {
    "id": "form-validation",
    "description": "Add input validation to registration form",
    "acceptance_criteria": [
      {"criterion": "Email format validated", "met": true},
      {"criterion": "Password strength checked", "met": true},
      {"criterion": "Empty fields rejected", "met": true, "evidence": "All empty field tests pass"},
      {"criterion": "Error messages displayed", "met": true}
    ]
  },
  "status": "pass",
  "tests": {
    "total": 12,
    "passed": 12,
    "failed": 0,
    "skipped": 0,
    "duration_ms": 2800
  },
  "files_changed": {
    "added": [],
    "modified": ["src/utils/validation.ts"],
    "deleted": [],
    "total_lines_added": 5,
    "total_lines_removed": 1
  }
}
```

---

## Phase 5: Re-ACCEPT → PASS

### 5.1 Evidence Check (Level 0 Only)

```
OpenClaw reviews:
✅ status: "pass"
✅ tests: 12/12 passed
✅ All acceptance criteria met
✅ Minimal change: 5 lines added, 1 removed

Verdict: PASS
```

**No need to escalate to Level 1 (patch hunks) or Level 2 (excerpts).**

---

## Fail Counter Management

| Round | Status | fail_count |
|-------|--------|------------|
| 1 | FAIL | 1 |
| 2 (after patch) | PASS | reset to 0 |

If fail_count reached 3, would have escalated to supervisor.

---

## Key Principles Demonstrated

1. **Minimal evidence**: Only extracted what was needed from report.json
2. **No full file reads**: Didn't read Form.tsx or validation.ts
3. **Clear fix request**: Specific, actionable, with context
4. **Fast iteration**: One PATCH cycle resolved the issue
5. **Circuit breaker ready**: Would escalate at 3 failures

---

## Alternative: Consecutive Failures → ESCALATE

If Claude Code failed 3 times:

```
🚨 ESCALATE to Supervisor

任務: form-validation
失敗次數: 3

失敗歷史:
1. "empty username shows error" - undefined error message
2. "empty username shows error" - wrong error message
3. "empty username shows error" - error not displayed in DOM

已收集證據:
- report.json (3 versions)
- test_summary.txt
- diffstat.txt showing 3 patch attempts

建議:
- 可能需要重新理解需求
- 考慮檢查 DOM rendering 問題
- 可能需要人工 debug

請指示下一步。
```
