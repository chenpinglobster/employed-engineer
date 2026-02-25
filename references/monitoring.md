# Monitoring Protocol

Detailed reference for the monitor sub-agent's execution loop.

## Prerequisites

Configure Claude Code hooks in `~/.claude/settings.json`:
```json
{
  "hooks": {
    "Stop": [{"matcher": "*", "hooks": [{"type": "command", "command": "touch .claude_signal"}]}],
    "PermissionRequest": [{"matcher": "*", "hooks": [{"type": "command", "command": "touch .claude_signal"}]}]
  }
}
```

## Monitor Protocol Steps

```
0. Verify: `which claude` exits 0. If not → announce ESCALATE "claude CLI not found"

1. cd PROJECT.path && rm -f .claude_signal

2. Launch Claude Code:
   exec pty:true background:true timeout:1800
   command:"<SKILL_DIR>/run_claude.sh <PROJECT_DIR> '<TASK>. Use ./acceptance/run_allowed.sh'"
   → sessionId

3. Semaphore wait loop — repeat until process exits (max 200 iterations):
   Track last_log_hash (to detect new output) and stale_count (for thinking loop).

   a. Sleep: process action:poll sessionId:<id> timeout:3000

   b. Signal check:
      exec command:"[ -f .claude_signal ] && echo SIGNAL || echo waiting"
      exec command:"rm -f .claude_signal"

   c. Log check (on SIGNAL or every 10 iterations):
      process action:log sessionId:<id> limit:30
      - autoApprove match → process action:submit data:"y\n"
      - deny match → process action:submit data:"n\n"
      - escalate match → STOP, announce ESCALATE
      - unknown prompt → process action:submit data:"n\n" (default deny)

   d. Thinking loop detection:
      Compare log output to last_log_hash.
      If same → stale_count += 1
      If different → stale_count = 0, update last_log_hash
      If stale_count >= 100 (= ~5 min at 3s intervals):
      → announce TIMEOUT "thinking loop detected — no output for 5 min"

   e. Process alive check: if process exited → break loop

   f. Circuit breaker: fail_count >= 3 → announce ESCALATE

4. Save full log:
   process action:log sessionId:<sessionId> offset:0 limit:99999
   Write to: acceptance/artifacts/latest/claude_YYYYMMDD_HHMMSS.log
   
   Use exec to write the log content to the timestamped file.
   This is a MONITORING action — allowed under monitor constraint.

5. Verify: acceptance/artifacts/latest/report.json exists

6. Announce: PASS | FAIL | ESCALATE | TIMEOUT + summary + log path
```

## Timeouts

| Component | Duration | Handled By |
|-----------|----------|------------|
| Thinking loop | ~300s (5 min) | Monitor stale_count ≥ 100 |
| Claude Code | 1800s (30 min) | PTY timeout |
| Sub-agent | 2400s (40 min) | runTimeoutSeconds |
| Semaphore check | 3s interval | Monitor poll loop |

## Command Approval Quick Reference

| Prompt Pattern | Action |
|----------------|--------|
| `./acceptance/run_allowed.sh *` | AUTO-APPROVE ("y") |
| `pnpm test` (non-wrapper) | DENY ("n") + guide |
| `git push`, `rm -rf`, `sudo` | DENY + warn |
| `kubectl apply`, deploy | ESCALATE |

Read `policies/command_policy.yaml` for full rules.
