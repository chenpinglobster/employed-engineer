# Monitor Task Template

Copy, fill in `__PLACEHOLDERS__`, and pass to `sessions_spawn`.

---

```
⛔ ROLE CONSTRAINT — READ THIS FIRST:
You are a Monitor Agent. You spawn Claude Code and watch it. You do NOT write code.
Your first tool call MUST be exec(pty:true, background:true) to spawn Claude Code.
If you find yourself using edit/write on project files → STOP immediately.

Read this file for your complete protocol:
/Users/chenping/.openclaw/workspace/skills/employed-engineer/AGENT.md

Then execute the protocol with these parameters:

PROJECT_PATH: __PROJECT_PATH__
TASK: __TASK_DESCRIPTION__
POLICIES:
  trustLevel: __TRUST_LEVEL__        (Full Control | Balanced | Trust Mode)
  autoApprove:
    - __AUTO_APPROVE_PATTERNS__      (e.g. "./acceptance/run_allowed.sh *")
  deny:
    - __DENY_PATTERNS__              (e.g. "git push", "rm -rf")
  escalate:
    - __ESCALATE_PATTERNS__          (e.g. "kubectl", "terraform")
```

---

## Placeholders

| Placeholder | Example |
|---|---|
| `__PROJECT_PATH__` | `/Users/chenping/.openclaw/workspace/miniRTS` |
| `__TASK_DESCRIPTION__` | `Implement ECS combat system per PRD.md Section 3. Use ./acceptance/run_allowed.sh for tests.` |
| `__TRUST_LEVEL__` | `Balanced` |
| `__AUTO_APPROVE_PATTERNS__` | `"./acceptance/run_allowed.sh *"` |
| `__DENY_PATTERNS__` | `"git push", "rm -rf", "sudo"` |
| `__ESCALATE_PATTERNS__` | `"kubectl", "terraform", "deploy"` |

## Usage

```
sessions_spawn task:"<filled template>" label:"<task-name>" runTimeoutSeconds:2400
```

Then **end your turn**. Sub-agent auto-announces when done.

## Trust Level Quick Select

| Level | Auto-Approve | Escalate | Use When |
|-------|--------------|----------|----------|
| Full Control | Nothing | Everything | First-time project, production |
| **Balanced** ⭐ | Wrapper + file ops | git push, deploy | Most dev work |
| Trust Mode | All except high-risk | Only dangerous | Rapid prototyping |
