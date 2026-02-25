# Monitoring Protocol

Detailed reference for the monitor sub-agent's execution loop.

## No Setup Required

`run_claude.sh` handles logging and thinking loop detection automatically.
No Claude Code hooks or special configuration needed.

## Monitor Protocol Steps

```
0. Verify: `which claude` exits 0. If not → announce ESCALATE "claude CLI not found"

1. cd PROJECT.path

2. Launch Claude Code with automatic log capture + watchdog:
   exec pty:true background:true timeout:1800
   command:"<SKILL_DIR>/run_claude.sh <PROJECT_DIR> '<TASK>. Use ./acceptance/run_allowed.sh'"
   → sessionId
   
   run_claude.sh handles:
   - Full PTY capture via `script` command
   - Thinking loop watchdog (kills after 5 min silence)

3. Poll loop — repeat until process exits (max 200 iterations):

   a. Poll for output (yields up to 3s, wakes early on new output):
      process action:poll sessionId:<id> timeout:3000

   b. Read last lines and check for approval prompt:
      process action:log sessionId:<id> limit:30
      
      Look for patterns like:
      - "Allow?" / "allow this" / "Do you want to" / "permission" / "[y/N]"
      - File edit confirmations
      - Command execution requests
      
      Response:
      - autoApprove match → process action:submit data:"y\n"
      - deny match → process action:submit data:"n\n"
      - escalate match → STOP, announce ESCALATE
      - unknown prompt → process action:submit data:"n\n" (default deny)

   c. Process alive check: if process exited → break loop

   d. Circuit breaker: fail_count >= 3 → announce ESCALATE

4. Full log is automatic (run_claude.sh handles it).
   Find it: ls -t acceptance/artifacts/latest/claude_*.log | head -1
   Include path in announce message.

5. Verify: acceptance/artifacts/latest/report.json exists

6. Announce: PASS | FAIL | ESCALATE | TIMEOUT + summary + log path
```

## Timeouts

| Component | Duration | Handled By |
|-----------|----------|------------|
| Thinking loop | 300s (5 min) | `run_claude.sh` watchdog (auto-kill) |
| Claude Code | 1800s (30 min) | PTY timeout |
| Sub-agent | 2400s (40 min) | runTimeoutSeconds |
| Poll interval | 3s | Monitor loop |

## Command Approval Quick Reference

| Prompt Pattern | Action |
|----------------|--------|
| `./acceptance/run_allowed.sh *` | AUTO-APPROVE ("y") |
| `pnpm test` (non-wrapper) | DENY ("n") + guide |
| `git push`, `rm -rf`, `sudo` | DENY + warn |
| `kubectl apply`, deploy | ESCALATE |

Read `policies/command_policy.yaml` for full rules.
