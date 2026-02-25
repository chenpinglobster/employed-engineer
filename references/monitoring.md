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

2. Launch Claude Code with automatic log capture:
   exec pty:true background:true timeout:1800
   command:"<SKILL_DIR>/run_claude.sh <PROJECT_DIR> '<TASK>. Use ./acceptance/run_allowed.sh'"
   → sessionId
   
   run_claude.sh wraps Claude Code with `script` to capture ALL terminal output
   to a timestamped log file. No manual log saving needed.

3. Semaphore wait loop — repeat until process exits (max 200 iterations):

   a. Sleep: process action:poll sessionId:<id> timeout:3000
      (Yields up to 3s, wakes early on output.)

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
      Track last_output_change. If no new output for 5 minutes (100 iterations):
      → process action:submit data:"\x03" (Ctrl+C to interrupt)
      → announce TIMEOUT with "thinking loop detected"

   e. Process alive check: if process exited → break loop

   f. Circuit breaker: fail_count >= 3 → announce ESCALATE

4. Full log is automatic (run_claude.sh handles it).
   Confirm log file exists in acceptance/artifacts/latest/claude_*.log
   Include path in announce message.

5. Verify: acceptance/artifacts/latest/report.json exists

6. Announce: PASS | FAIL | ESCALATE | TIMEOUT + summary + log path
```

## Timeouts

| Component | Duration | Notes |
|-----------|----------|-------|
| Claude Code | 1800s (30 min) | PTY timeout |
| Sub-agent | 2400s (40 min) | Includes buffer |
| Semaphore check | 3s interval | 200 iterations max |
| Thinking loop | 300s (5 min) | No new output → Ctrl+C |

## Command Approval Quick Reference

| Prompt Pattern | Action |
|----------------|--------|
| `./acceptance/run_allowed.sh *` | AUTO-APPROVE ("y") |
| `pnpm test` (non-wrapper) | DENY ("n") + guide |
| `git push`, `rm -rf`, `sudo` | DENY + warn |
| `kubectl apply`, deploy | ESCALATE |

Read `policies/command_policy.yaml` for full rules.
