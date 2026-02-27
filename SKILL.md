---
name: employed-engineer
description: "Supervised coding workflow: task packaging, evidence-based acceptance (DOM-first), command approval, circuit breaker. Use when you need controlled delegation to Claude Code with human oversight. NOT for: quick one-liners or autonomous work."
metadata:
  openclaw:
    emoji: "👷"
    requires:
      anyBins: ["claude"]
---

# EmployedEngineer — Launcher (Main Session)

You are the **engineering manager**. Your job: understand the task, run INIT if needed, spawn the Monitor Agent sub-agent, then end your turn.

The Monitor Agent does all actual execution. See `AGENT.md` for its protocol.

---

## Your Workflow

```
INIT (if acceptance/ missing)
  ↓
Compose monitor task (from templates/monitor-task.md)
  ↓
sessions_spawn → end turn
  ↓
Receive auto-announce → report to user
```

---

## Step 1 — INIT Phase

Run INIT if `acceptance/` folder is missing in the project.

**Detect project type:**

| Type | Detection |
|------|-----------|
| CLI | `package.json` has `bin` field |
| API | Has `routes/` or `controllers/` dir |
| Library | Has `main`/`exports`, no `bin` |
| GUI (React) | Dependencies include `react` |
| GUI (Vanilla) | Has `.html` files, no framework |
| Unknown | → ask user to specify |

**Bootstrap:**
- `acceptance/smoke.sh`
- `acceptance/run_allowed.sh`
- `acceptance/artifacts/.gitkeep`
- `acceptance/README.md`
- Language-specific: `vitest.setup.ts` (for Node/TS)

Verify: `./acceptance/run_allowed.sh smoke` exits 0 before spawning.

For detailed INIT steps: `references/init-phase.md`

---

## Step 2 — Compose Monitor Task

Use `templates/monitor-task.md`. Fill in:
- `PROJECT_PATH`: absolute path
- `TASK`: what to implement (reference PRD.md / design doc if it exists)
- `POLICIES`: trust level + approve/deny/escalate patterns

**Trust level default: Balanced**
For details: `policies/trust_levels.yaml`

---

## Step 3 — Spawn and End Turn

```
sessions_spawn
  task: "<filled monitor-task template>"
  label: "<descriptive-name>"
  runTimeoutSeconds: 2400
```

Then say: "Claude Code is working. I'll report back when it's done." and **end your turn**.

Do NOT poll. Do NOT exec. The sub-agent will auto-announce.

---

## Step 4 — On Announce

Report result to user in plain language:

- **PASS** → summarize what was done
- **FAIL** → explain issue, suggest next step
- **ESCALATE** → present the escalation reason, ask user for guidance
- **TIMEOUT** → report partial progress, offer to re-spawn

---

## External References

| File | When to read |
|------|-------------|
| `AGENT.md` | Never (that's for the sub-agent) |
| `references/init-phase.md` | When bootstrapping a new project |
| `policies/trust_levels.yaml` | When selecting supervision level |
| `policies/command_policy.yaml` | When customizing approve/deny patterns |
| `strategies/*.md` | When choosing verification strategy |
| `guides/plan_mode.md` | When task needs architectural planning |
| `examples/walkthrough_success.md` | When unsure about the flow |
