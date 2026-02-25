---
name: employed-engineer
description: "Supervised coding workflow: task packaging, evidence-based acceptance (DOM-first), command approval, circuit breaker. Use when you need controlled delegation to Claude Code with human oversight. NOT for: quick one-liners or autonomous work."
metadata:
  openclaw:
    emoji: "👷"
    requires:
      anyBins: ["claude"]
---

# EmployedEngineer

Supervised coding agent workflow. You are the engineering manager; Claude Code is the developer.

## Purpose

- Use built-in coding-agent to drive Claude Code (PTY + background)
- Add: task packaging, evidence-based acceptance, command approval, circuit breaker
- Never re-read full code; decide by artifacts + minimal patch

## External Files

- Policies: `{baseDir}/policies/*.yaml`
- Schemas: `{baseDir}/schemas/*.json`
- Templates: `{baseDir}/templates/*`
- Examples: `{baseDir}/examples/*.md`

When unsure: read `{baseDir}/examples/walkthrough_success.md`

---

## State Machine

```
INIT ──► PLAN ──┬─► IMPLEMENT ──► VERIFY ──► ACCEPT
  │             │        │            │          │
  │             │        ▼            ▼          ▼
  │          PLAN_MODE  COMMAND   ARTIFACTS   PASS/FAIL
  │          (optional) APPROVAL                 │
  │             │                                │
  │             └─► (design decisions) ──────────┤
  │                                           ▼
  └─────────────────────────────────────► PATCH (if FAIL)
                                              │
                                              ▼
                                         ESCALATE (if fail_limit)
```

### States

| State | Entry Condition | Exit Condition |
|-------|-----------------|----------------|
| INIT | acceptance/ missing | smoke passes |
| PLAN | task received | complexity assessed |
| PLAN_MODE | complex task detected | design decisions made |
| IMPLEMENT | plan approved | Claude Code idle |
| VERIFY | implementation done | artifacts generated |
| ACCEPT | artifacts ready | PASS or FAIL |
| PATCH | FAIL with fixable issue | back to IMPLEMENT |
| ESCALATE | fail_limit reached OR high-risk | supervisor responds |

---

## Hard Rules

1. **Wrapper-only execution**
   - Approve ONLY `./acceptance/run_allowed.sh <task>`
   - Non-wrapper commands → DENY, request wrapper

2. **Evidence ladder**
   - Level 0: artifacts only (report.json, diffstat, logs)
   - Level 1: patch hunks (limited lines)
   - Level 2: targeted excerpts (must justify)
   - NEVER read full source files

3. **GUI acceptance: DOM-first**
   - Use selector/text/state assertions
   - Screenshot/recording only when DOM insufficient
   - No artifacts = no acceptance

4. **Circuit breaker**
   - Max 3 consecutive failures → ESCALATE
   - High-risk commands → immediate ESCALATE

5. **Command approval**
   - Parse prompts per `policies/command_policy.yaml`
   - Categories: AUTO-APPROVE / APPROVE-WITH-CHECK / DENY / ESCALATE
   - Never enable "auto-approve all"

6. **PTY monitoring - Sub-Agent + Semaphore Pattern**
   
   Use a monitor sub-agent with semaphore signaling for efficient monitoring.
   Claude Code hooks create `.claude_signal` file on PermissionRequest/Stop events.
   Sub-agent waits for signal (fast response) or timeout (max 600s between checks).
   
   **Prerequisites:** Configure Claude Code hooks (see Setup section below)
   
   **Implementation:**
   ```bash
   # 1. Main agent prepares monitor task (see Monitor Task Format)
   
   # 2. Spawn monitor sub-agent
   sessions_spawn task:"<monitor-task>" label:"impl" runTimeoutSeconds:2400
   # → returns immediately with runId
   
   # 3. Tell user and END TURN
   "Claude Code is working. I'll report when done."
   
   # --- Sub-agent works in background ---
   # - Spawns Claude Code (PTY)
   # - Semaphore wait loop (3s check, 600s max)
   # - Handles approvals per policy
   # - Verifies artifacts when done
   
   # --- Main agent receives announce (auto-wakeup) ---
   # [System Message] Subagent "impl" completed...
   # Result: PASS/FAIL/ESCALATE/TIMEOUT + summary
   
   # 4. Report result to user
   ```
   
   **Timeouts:**
   - Claude Code: `timeout:1800` (30 min)
   - Sub-agent: `runTimeoutSeconds:2400` (40 min, includes buffer)
   - Semaphore check: 3s interval, 200 iterations (600s max between wakeups)
   
   **Setup: Claude Code Hooks**
   
   Add to `~/.claude/settings.json`:
   ```json
   {
     "hooks": {
       "Stop": [{"matcher": "*", "hooks": [{"type": "command", "command": "touch .claude_signal"}]}],
       "PermissionRequest": [{"matcher": "*", "hooks": [{"type": "command", "command": "touch .claude_signal"}]}]
     }
   }
   ```

---

## Quick Start

### Simple Task (No Plan Mode)

```bash
# 1. INIT (if needed) → 2. PLAN: no architecture needed → skip plan mode

# 3. Spawn monitor sub-agent (see Monitor Task Format for full template)
sessions_spawn task:'EMPLOYED_ENGINEER_MONITOR
PROJECT: {path, type}
TASK: <description>
POLICIES: {trustLevel, autoApprove, deny, escalate}
' label:"<task-name>" runTimeoutSeconds:2400

# 4. END TURN: "Claude Code is working. I'll report when done."
# 5. On announce: report result to user
```

### Complex Task (With Plan Mode)

```bash
# 1. PLAN: architecture unclear → read {baseDir}/guides/plan_mode.md

# 2. Spawn plan sub-agent
sessions_spawn task:'EMPLOYED_ENGINEER_MONITOR
PROJECT: {path, type}
TASK: claude plan "<design question>"
POLICIES: {trustLevel: Balanced, autoApprove: ["*"]}
' label:"plan" runTimeoutSeconds:1200

# 3. On announce: extract design decisions

# 4. Spawn implementation sub-agent with decisions baked in
sessions_spawn task:'EMPLOYED_ENGINEER_MONITOR
PROJECT: {path, type}
TASK: <impl task incorporating plan decisions>
POLICIES: {trustLevel, autoApprove, deny, escalate}
' label:"impl" runTimeoutSeconds:2400
```

**Key principles:**
- **PLAN Phase:** Check complexity → use plan mode sub-agent if needed
- **Monitoring:** Sub-agent uses semaphore pattern (signal file + timeout)
- **Timeouts:** Claude Code 30min, sub-agent 40min, semaphore 600s
- **Plan output:** Becomes task input for implementation sub-agent

---

## Monitor Task Format

The monitor sub-agent receives a structured task:

```
EMPLOYED_ENGINEER_MONITOR
PROJECT: {path: <abs-path>, type: <cli|api|library|gui-react|gui-vanilla>}
TASK: <description for Claude Code>
POLICIES: {trustLevel, autoApprove: [...], deny: [...], escalate: [...]}
```

### Monitor Protocol (sub-agent execution)

```
1. cd PROJECT.path && rm -f .claude_signal

2. exec pty:true background:true timeout:1800
   command:"claude '<TASK>. Use ./acceptance/run_allowed.sh'"
   → sessionId

3. Semaphore wait loop (while process running):
   a. Wait: 3s × 200 iterations = 600s max, exit early if .claude_signal exists
   b. rm -f .claude_signal
   c. Check log for approval prompt:
      - autoApprove match → submit "y"
      - deny match       → submit "n"
      - escalate match   → STOP, announce ESCALATE
      - unknown          → submit "n" (default deny)
   d. fail_count >= 3 → circuit breaker, announce ESCALATE

   **Tip:** Filter ANSI escape codes and carriage returns to save tokens:
   ```bash
   process log --sessionId xxx --limit 50 | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g; s/\r//g'
   ```

4. Verify: acceptance/artifacts/latest/report.json exists

5. Announce: PASS (summary) | FAIL (issue+fix) | ESCALATE (reason) | TIMEOUT (partial)
```

---

## INIT Phase

Detects project type and bootstraps acceptance scaffolding.

### Step 1: Language Detection

**Detection (by files, not guessing):**
- Node/TS: `package.json` + lockfile
- Python: `pyproject.toml` or `requirements.txt`
- Go: `go.mod`
- Rust: `Cargo.toml`

### Step 2: Project Type Detection

Detect project type to choose verification strategy (load strategy file on-demand):

| Type | Detection Rule | Strategy File |
|------|----------------|---------------|
| **CLI** | `package.json` has `bin` field | `{baseDir}/strategies/cli.md` |
| **API** | Has `routes/` or `controllers/` dir | `{baseDir}/strategies/api.md` |
| **Library** | Has `main`/`exports`, no `bin` | `{baseDir}/strategies/library.md` |
| **GUI (React)** | Dependencies include `react` | `{baseDir}/strategies/gui-react.md` |
| **GUI (Vanilla)** | Has `.html` files, no framework | `{baseDir}/strategies/gui-vanilla.md` |
| **Unknown** | None of the above | ESCALATE to engineer |

**Cache detection result:**
```bash
echo '{"type": "cli", "confidence": "high"}' > acceptance/project_type.json
```

**Unknown projects:**
1. Run `tree -L 2 -I node_modules` to show structure
2. ESCALATE: "Cannot auto-classify. Please decide verification strategy."
3. Engineer can:
   - Create custom `acceptance/custom_verify.sh`
   - Or specify existing strategy: `echo '{"type": "api"}' > acceptance/project_type.json`

### Step 3: Bootstrap Templates

**Bootstraps:**
- `acceptance/smoke.sh`
- `acceptance/run_allowed.sh`
- `acceptance/artifacts/.gitkeep`
- `acceptance/README.md`
- Language-specific: `vitest.setup.ts` (for Node/TS)

**Done when:** `./acceptance/run_allowed.sh smoke` exits 0

### Step 4: Load Verification Strategy

**On first VERIFY phase:**
1. Read `acceptance/project_type.json`
2. Load corresponding strategy file (e.g., `strategies/cli.md`)
3. Follow strategy-specific verification steps
4. Generate strategy-specific artifacts

**Token efficiency:** Strategies loaded only when needed, not upfront.

---

## PLAN Phase

### Complexity Assessment

**Use plan mode when task requires deep architectural thinking:**

- Designing multi-component systems or choosing between architectural patterns
- Analyzing algorithm/performance tradeoffs with significant implications
- Exploring unfamiliar problem domains where best practices aren't obvious
- Making decisions that are expensive to reverse later

Such as: API contract design, database schema optimization, state management architecture, security model selection, caching strategy.

**Skip plan mode when:**

- Implementation path is straightforward (standard patterns)
- Modifying existing code following established conventions
- Bug fixes or incremental feature additions
- Task already includes detailed design from user

### Decision

**If task is complex (needs architectural thinking):**

Read `{baseDir}/guides/plan_mode.md` and follow the plan mode workflow.

**Otherwise:**

Write task package directly → proceed to IMPLEMENT.

---

## Trust Level Selection

At the start of IMPLEMENT phase, choose supervision level (read `{baseDir}/policies/trust_levels.yaml`):

| Level | Auto-Approve | Escalate | Best For |
|-------|--------------|----------|----------|
| **Full Control** | Nothing | Everything | Production, first-time projects |
| **Balanced** ⭐ | Wrapper + file ops (after first approval) | Risky commands (git push, deploy) | Development, feature work |
| **Trust Mode** | All except high-risk | Only dangerous commands | Rapid prototyping, trusted code |

**Default: Balanced** (recommended for most workflows)

**Selection prompt:**
```
Choose supervision level for this session:
1. Full Control - approve every command/file
2. Balanced - auto-approve wrapper + file ops (recommended)
3. Trust Mode - only escalate on high-risk

[Press Enter for Balanced]
```

**After selection:**
- Store choice in session context
- Apply auto-approve patterns from trust_levels.yaml
- Reduce approval fatigue while maintaining safety

**Example (Balanced mode):**
- First `./acceptance/run_allowed.sh test` → Ask approval
- Subsequent wrapper commands → Auto-approve
- `git push` → Always escalate

---

## Command Approval

Read `{baseDir}/policies/command_policy.yaml` for full rules.

**Quick reference:**

| Prompt Pattern | Action |
|----------------|--------|
| `./acceptance/run_allowed.sh test` | AUTO-APPROVE ("y") |
| `./acceptance/run_allowed.sh e2e` | APPROVE-WITH-CHECK |
| `pnpm test` (non-wrapper) | DENY ("n") + guide |
| `git push`, `rm -rf`, `sudo` | DENY + warn |
| `kubectl apply`, deploy commands | ESCALATE |

**Extraction patterns:**
- `` `command` ``
- `"command"`
- `Run "..."? [y/N]`
- `Do you want to run ...? (y/N)`

---

## Artifacts Contract

Claude Code must produce in `acceptance/artifacts/latest/`:

| File | Purpose |
|------|---------|
| `report.json` | Structured summary (see schema) |
| `diffstat.txt` | Files changed |
| `test_summary.txt` | Test results |
| `log_tail.txt` | Last N lines of output |
| `commands.log` | Wrapper execution log |

For UI tasks, also:
| `dom_assertions.json` | Assertion results |
| `dom_snapshot.html` | Key DOM fragments |

---

## Acceptance Criteria

**DOM-first (default):**
- Selector/text/state assertions in `dom_assertions.json`
- Each assertion: `{ selector, expected, actual, pass }`

**Upgrade to visual when:**
- Canvas/WebGL/charts (DOM can't see)
- Browser extensions (isolated context)
- Multi-window/OS-level UI

**On upgrade:** produce `screenshots/step-*.png` or `screenrecord.mp4`

---

## Circuit Breaker

```
fail_count >= 3  →  ESCALATE to supervisor
```

ESCALATE report includes:
- What was attempted
- Evidence of failures
- Suggested next steps
- Risk assessment

---

## Troubleshooting

### Sub-agent not completing

**Check status:**
```bash
/subagents list
# Look for your label (e.g., "impl", "cache-plan")
```

**Check log:**
```bash
/subagents log <id-or-label> 50
```

**If stuck, kill and retry:**
```bash
/subagents kill <id-or-label>
# Then re-spawn with adjusted task
```

### Sub-agent announces TIMEOUT

**Cause:** Sub-agent `runTimeoutSeconds` exceeded

**Recovery:**
1. Check `acceptance/artifacts/latest/` for partial progress
2. Review what was accomplished
3. Options:
   - Re-spawn with remaining work and longer timeout
   - Break task into smaller pieces
   - Escalate if task is too complex

### Sub-agent announces ESCALATE

**Cause:** 
- 3+ consecutive failures (circuit breaker)
- High-risk command detected

**Action:**
1. Review the escalation reason in announce
2. Decide: fix manually, adjust task, or provide guidance
3. Re-spawn with updated policies if needed

### Sub-agent announces FAIL

**Cause:** Artifacts missing or verification failed

**Recovery:**
1. Check what artifacts exist
2. Review Claude Code output (sub-agent log)
3. Options:
   - Re-spawn to complete missing work
   - Manually fix and re-verify

### Claude Code stuck inside sub-agent

**Symptoms:** Sub-agent running too long without announce

**Check sub-agent log for Claude Code status:**
```bash
/subagents log <id> 100
# Look for approval prompts, errors, or infinite loops
```

**If sub-agent is stuck, kill it:**
```bash
/subagents kill <id>
```

---

## Token Budget

- This file: ~150 lines (entry point only)
- Detailed rules: external YAML/JSON
- Examples: separate walkthrough files
- Never paste full policies into chat
