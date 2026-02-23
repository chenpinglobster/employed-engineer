# EmployedEngineer 👷

> Supervised coding workflow for OpenClaw: You're the engineering manager; Claude Code is the developer.

**EmployedEngineer** is an [OpenClaw AgentSkill](https://docs.openclaw.ai/skills/) that adds **human oversight** to autonomous coding agents. It wraps coding workflows with:

- **Task packaging** – Clear contracts for inputs/outputs
- **Evidence-based acceptance** – DOM-first UI verification, never "trust me bro"
- **Command approval** – No blind `rm -rf` or `git push`
- **Circuit breaker** – Escalates after repeated failures

Use it when you need **controlled delegation** to Claude Code with guardrails. NOT for simple one-liners or fully autonomous work.

---

## Quick Start

### Prerequisites

1. [OpenClaw](https://github.com/openclaw/openclaw) installed
2. [Claude Code](https://github.com/anthropics/anthropic-quickstarts/tree/main/computer-use-demo/claude-code) CLI installed
3. Project with `acceptance/` scaffolding (auto-generated on first run)

### Installation

```bash
# Clone to your OpenClaw workspace
cd ~/.openclaw/workspace/skills
git clone https://github.com/chenpinglobster/employed-engineer.git
```

OpenClaw will auto-discover the skill on next restart.

### Basic Usage

```
# In OpenClaw chat:
@lobster use employed-engineer to add a dark mode toggle to my React app

# Workflow:
# 1. INIT: Bootstraps acceptance/ scaffolding if missing
# 2. PLAN: Assesses complexity (may use plan mode for architecture decisions)
# 3. IMPLEMENT: Spawns Claude Code in supervised PTY session
# 4. VERIFY: Checks artifacts (diffstat, test results, DOM assertions)
# 5. ACCEPT: Reports PASS/FAIL/ESCALATE
```

---

## Core Concepts

### State Machine

```
INIT → PLAN → IMPLEMENT → VERIFY → ACCEPT
                  ↓          ↓         ↓
             COMMAND    ARTIFACTS   PASS/FAIL
             APPROVAL                   ↓
                                     PATCH (if FAIL)
                                        ↓
                                   ESCALATE (if fail_limit)
```

### Trust Levels

| Level | Auto-Approve | Escalate | Best For |
|-------|--------------|----------|----------|
| **Full Control** | Nothing | Everything | Production, first-time projects |
| **Balanced** ⭐ | Wrapper + file ops | Risky commands | Development (recommended) |
| **Trust Mode** | All except high-risk | Dangerous commands | Rapid prototyping |

### Evidence Ladder

1. **Artifacts only** – `report.json`, `diffstat.txt`, `test_summary.txt`
2. **Patch hunks** – Limited lines of actual changes
3. **Targeted excerpts** – Only when justified

**Never** reads full source files to decide acceptance.

### DOM-First UI Verification

- Uses selector/text/state assertions (not screenshots)
- Upgrades to visual only when necessary (Canvas, WebGL, extensions)
- Generates `dom_assertions.json` with pass/fail per assertion

---

## Project Structure

```
employed-engineer/
├── SKILL.md              # Skill entry point (OpenClaw metadata + protocol)
├── README.md             # This file
├── examples/             # End-to-end walkthroughs
│   ├── walkthrough_success.md
│   └── walkthrough_escalate.md
├── guides/               # Deep dives
│   └── plan_mode.md      # Using Claude Code for architecture planning
├── policies/             # Decision rules
│   ├── command_policy.yaml
│   └── trust_levels.yaml
├── schemas/              # Artifact contracts
│   └── report_schema.json
├── strategies/           # Project-type-specific verification
│   ├── cli.md
│   ├── api.md
│   ├── library.md
│   ├── gui-react.md
│   └── gui-vanilla.md
└── templates/            # Bootstrap files
    ├── smoke.sh
    ├── run_allowed.sh
    └── vitest.setup.ts
```

---

## Why Use This?

**Problem:** Autonomous coding agents can:
- Run destructive commands without approval
- Make architectural decisions without context
- Fail silently and claim success
- Burn through API credits on broken loops

**Solution:** EmployedEngineer adds **supervision without micromanagement**:
- Approves safe commands automatically (per trust level)
- Requires evidence of completion (artifacts, not vibes)
- Escalates on repeated failures or high-risk operations
- Uses plan mode for complex architectural decisions

**Result:** Faster iteration, fewer surprises, clearer audit trail.

---

## Configuration

### Setup: Claude Code Hooks

Add to `~/.claude/settings.json` for efficient PTY monitoring:

```json
{
  "hooks": {
    "Stop": [{"matcher": "*", "hooks": [{"type": "command", "command": "touch .claude_signal"}]}],
    "PermissionRequest": [{"matcher": "*", "hooks": [{"type": "command", "command": "touch .claude_signal"}]}]
  }
}
```

This enables semaphore-based monitoring (3s check interval, 600s max latency).

### Trust Level Selection

Choose at start of IMPLEMENT phase:

```
Choose supervision level for this session:
1. Full Control - approve every command/file
2. Balanced - auto-approve wrapper + file ops (recommended)
3. Trust Mode - only escalate on high-risk

[Press Enter for Balanced]
```

Stored in session context; can be changed per-task.

---

## Troubleshooting

### Sub-agent not completing

```bash
# Check status
/subagents list

# Check log
/subagents log <id-or-label> 50

# If stuck, kill and retry
/subagents kill <id-or-label>
```

### Sub-agent announces TIMEOUT

**Cause:** `runTimeoutSeconds` exceeded (default 40 min)

**Fix:**
1. Check `acceptance/artifacts/latest/` for partial progress
2. Re-spawn with remaining work + longer timeout
3. Or break task into smaller pieces

### Sub-agent announces ESCALATE

**Cause:** 3+ failures (circuit breaker) or high-risk command

**Action:**
1. Review escalation reason
2. Fix manually or adjust task
3. Re-spawn with updated policies

### Claude Code stuck

**Check sub-agent log:**
```bash
/subagents log <id> 100
# Look for approval prompts, errors, loops
```

**Kill if stuck:**
```bash
/subagents kill <id>
```

---

## Examples

See [`examples/walkthrough_success.md`](./examples/walkthrough_success.md) for a complete end-to-end flow.

---

## License

MIT License - see [LICENSE](./LICENSE)

---

## Contributing

Issues and PRs welcome! When proposing changes to policies or strategies, please include:
- Motivation (what problem does this solve?)
- Example scenario (walkthrough-style)
- Risk assessment (new failure modes?)

---

## Credits

Created by [@chenpinglobster](https://github.com/chenpinglobster) for [OpenClaw](https://github.com/openclaw/openclaw).

Inspired by human engineering workflows: delegation + verification + escalation.
