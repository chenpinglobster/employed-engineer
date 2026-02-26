# Monitor Task Template

Copy, fill in `__PLACEHOLDERS__`, and pass to `sessions_spawn`.

---

```
You are a monitor agent for Claude Code.

1. cd __PROJECT_PATH__ && rm -f .claude_signal

2. Run Claude Code:
   exec pty:true background:true timeout:1800
   command: claude '__TASK_DESCRIPTION__' --dangerously-skip-permissions
   workdir: __PROJECT_PATH__

3. Semaphore wait loop:
   - Check .claude_signal every 3s, max 200 iterations (600s)
   - When found: rm .claude_signal, read process log (strip ANSI)
   - If approval prompt detected: send "y" for safe commands, "n" for risky
   - If process exited: proceed to step 4

4. Verify results:
   __VERIFY_STEPS__

5. Announce summary: what worked, what failed, key outputs.
```

---

## Placeholders

| Placeholder | Example |
|---|---|
| `__PROJECT_PATH__` | `/Users/chenping/.openclaw/workspace/miniRTS` |
| `__TASK_DESCRIPTION__` | `Refactor the combat system to use ECS pattern. Use ./acceptance/run_allowed.sh for tests.` |
| `__VERIFY_STEPS__` | `Check if tests pass. Check if acceptance/artifacts/latest/report.json exists.` |

## Usage

```
sessions_spawn task:"<filled template>" label:"<task-name>" runTimeoutSeconds:2400
```

Then **end your turn**. Sub-agent auto-announces when done.

## ⚠️ Never do this

```
# WRONG — will timeout after 10 min idle in main session
exec command:"claude '...'" pty:true background:true
process poll sessionId:xxx timeout:600000  # ← YOU WILL GET KILLED
```
