# Walkthrough: Successful Task Completion

This example shows a complete EmployedEngineer workflow from task receipt to acceptance.

## Scenario

**Task**: Add a dark mode toggle to a React app
**Repo**: Node.js/TypeScript project with React

---

## Phase 1: INIT (First-time setup)

### 1.1 Detect Repo Type

```
OpenClaw checks for project files:
- ✅ package.json exists
- ✅ pnpm-lock.yaml exists
- ✅ tsconfig.json exists
→ Detected: Node.js/TypeScript project
```

### 1.2 Bootstrap Acceptance Infrastructure

```bash
# OpenClaw copies templates to repo
mkdir -p acceptance/artifacts/latest
cp {skillDir}/templates/run_allowed.sh acceptance/
cp {skillDir}/templates/acceptance/node-ts/smoke.sh acceptance/
cp {skillDir}/templates/acceptance/node-ts/README.md acceptance/
chmod +x acceptance/run_allowed.sh acceptance/smoke.sh
```

### 1.3 Verify INIT

```bash
./acceptance/run_allowed.sh smoke
# Output:
# 🔥 Smoke Test - Node.js/TypeScript
# ==================================
# 📦 Node.js version: v20.10.0
# 📦 Package manager: pnpm
# ✅ Smoke test passed!
```

**INIT → PLAN** ✅

---

## Phase 2: PLAN

### 2.1 Task Package

```yaml
task:
  id: dark-mode-toggle
  description: Add dark mode toggle to React app
  
acceptance_criteria:
  - Toggle button visible in header
  - Clicking toggle switches theme
  - Theme persists across page reload
  - No console errors
  
slice_scope:
  in:
    - src/components/ThemeToggle.tsx (new)
    - src/contexts/ThemeContext.tsx (new)
    - src/components/Header.tsx (modify)
    - src/App.tsx (modify)
  out:
    - Backend changes
    - Database changes
    - Third-party integrations

estimated_complexity: medium
```

**PLAN → IMPLEMENT** ✅

---

## Phase 3: IMPLEMENT

### 3.1 Start Claude Code

```bash
bash pty:true workdir:/path/to/project background:true \
  command:"claude 'Implement dark mode toggle for this React app.

Requirements:
1. Create ThemeToggle component with sun/moon icon
2. Create ThemeContext for state management  
3. Add toggle to Header component
4. Persist theme in localStorage

IMPORTANT: Use ./acceptance/run_allowed.sh for all commands.
After implementation, run: ./acceptance/run_allowed.sh test

Produce artifacts in acceptance/artifacts/latest/:
- report.json with task status
- diffstat.txt with changes'"
```

Returns: `sessionId: abc123`

### 3.2 Monitor Progress

```bash
process action:log sessionId:abc123
```

---

## Phase 4: COMMAND APPROVAL

### 4.1 AUTO-APPROVE (Wrapper Command)

```
Claude Code prompt:
"Do you want to run ./acceptance/run_allowed.sh test? (y/N)"

OpenClaw action:
→ Pattern matches: ./acceptance/run_allowed.sh test
→ Classification: AUTO-APPROVE
→ process action:submit sessionId:abc123 data:"y"

Log: "AUTO-APPROVED: wrapper task 'test'"
```

### 4.2 DENY (Non-Wrapper Command)

```
Claude Code prompt:
"Run pnpm test? [y/N]"

OpenClaw action:
→ Pattern matches: pnpm test
→ Classification: DENY (non-wrapper)
→ process action:submit sessionId:abc123 data:"n"
→ Reply: "請改用 ./acceptance/run_allowed.sh test"

Log: "DENIED: non-wrapper command 'pnpm test'"
```

### 4.3 Claude Code Adjusts

```
Claude Code: "I'll use the wrapper instead."
"Do you want to run ./acceptance/run_allowed.sh test? (y/N)"

OpenClaw action:
→ AUTO-APPROVE
→ process action:submit sessionId:abc123 data:"y"
```

---

## Phase 5: VERIFY

### 5.1 Check Artifacts

```bash
cat acceptance/artifacts/latest/report.json
```

```json
{
  "version": "1.0",
  "timestamp": "2026-02-20T12:30:00+08:00",
  "task": {
    "id": "dark-mode-toggle",
    "description": "Add dark mode toggle to React app",
    "acceptance_criteria": [
      {"criterion": "Toggle button visible in header", "met": true, "evidence": "ThemeToggle rendered in Header"},
      {"criterion": "Clicking toggle switches theme", "met": true, "evidence": "onClick handler toggles context"},
      {"criterion": "Theme persists across reload", "met": true, "evidence": "localStorage.getItem('theme')"},
      {"criterion": "No console errors", "met": true, "evidence": "test output clean"}
    ]
  },
  "status": "pass",
  "tests": {
    "total": 24,
    "passed": 24,
    "failed": 0,
    "skipped": 0,
    "duration_ms": 3200
  },
  "files_changed": {
    "added": ["src/components/ThemeToggle.tsx", "src/contexts/ThemeContext.tsx"],
    "modified": ["src/components/Header.tsx", "src/App.tsx"],
    "deleted": [],
    "total_lines_added": 87,
    "total_lines_removed": 3
  }
}
```

### 5.2 Check Diffstat

```bash
cat acceptance/artifacts/latest/diffstat.txt
```

```
 src/App.tsx                    |  5 +++--
 src/components/Header.tsx      |  8 ++++++--
 src/components/ThemeToggle.tsx | 42 +++++++++++++++++++++++++++++++++
 src/contexts/ThemeContext.tsx  | 35 +++++++++++++++++++++++++++
 4 files changed, 87 insertions(+), 3 deletions(-)
```

**VERIFY → ACCEPT** ✅

---

## Phase 6: ACCEPT

### 6.1 Evidence Check (Level 0)

```
OpenClaw reviews artifacts:
✅ report.json exists and valid
✅ status: "pass"
✅ tests: 24/24 passed
✅ All acceptance criteria met with evidence
✅ files_changed matches expected scope
```

### 6.2 DOM-First UI Verification (if needed)

For this task, OpenClaw might also check:

```bash
cat acceptance/artifacts/latest/dom_assertions.json
```

```json
{
  "version": "1.0",
  "timestamp": "2026-02-20T12:30:05+08:00",
  "url": "http://localhost:3000",
  "assertions": [
    {
      "id": "toggle-visible",
      "type": "exists",
      "selector": "[data-testid='theme-toggle']",
      "expected": true,
      "actual": true,
      "pass": true
    },
    {
      "id": "toggle-clickable",
      "type": "enabled",
      "selector": "[data-testid='theme-toggle']",
      "expected": true,
      "actual": true,
      "pass": true
    }
  ],
  "summary": {
    "total": 2,
    "passed": 2,
    "failed": 0
  }
}
```

### 6.3 Final Decision

```
OpenClaw verdict:
✅ All tests pass
✅ All acceptance criteria met
✅ DOM assertions pass
✅ No escalation needed

→ ACCEPT: PASS
```

---

## Summary

| Phase | Duration | Key Actions |
|-------|----------|-------------|
| INIT | 30s | Detect repo, bootstrap acceptance/ |
| PLAN | - | Define task package, criteria |
| IMPLEMENT | 5min | Claude Code works |
| COMMAND APPROVAL | - | 1 AUTO, 1 DENY→retry |
| VERIFY | 10s | Check artifacts |
| ACCEPT | 5s | Evidence review → PASS |

**Total time**: ~6 minutes

---

## Evidence Ladder Used

- **Level 0**: report.json, diffstat.txt, dom_assertions.json
- **Level 1**: Not needed (report was sufficient)
- **Level 2**: Not needed

**No full source files were read by OpenClaw.**
