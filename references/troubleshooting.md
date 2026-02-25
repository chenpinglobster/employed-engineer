# Troubleshooting

## Failure Taxonomy

### Recoverable (retry with fix)
- Test failures → patch specific issue
- Linting/type errors → fix and re-run
- Missing dependency → install and retry

### Irrecoverable (escalate immediately)
- `claude` CLI not found
- Broken environment (node/npm missing)
- Permission denied on project directory
- 3+ consecutive failures (circuit breaker)

## Common Issues

### Sub-agent not completing

```bash
/subagents list          # Find your label
/subagents log <id> 50   # Check progress
/subagents kill <id>     # If stuck, kill and retry
```

### Sub-agent TIMEOUT

1. Check `acceptance/artifacts/latest/` for partial progress
2. Options: re-spawn with remaining work, break into smaller tasks, escalate

### Sub-agent ESCALATE

1. Review escalation reason
2. Fix manually, adjust task, or provide guidance
3. Re-spawn with updated policies if needed

### Claude Code stuck (thinking loop)

**Symptoms:** Sub-agent running long, no progress announcements

**Detection:** Monitor checks for 5 min of no output → auto Ctrl+C

**If auto-detection fails:**
```bash
/subagents log <id> 100   # Look for long gaps in output
/subagents kill <id>       # Kill and retry with smaller task
```

### Post-mortem analysis

1. Find log: `ls -lt acceptance/artifacts/latest/claude_*.log | head -1`
2. Search for: "Fermenting", "Harmonizing" → thinking loop
3. Search for repeated "Read file" → context explosion
4. Search for unanswered permission prompts → monitor failed
5. Record findings in `learnings/YYYY-MM-DD-<topic>.md`
