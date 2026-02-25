# Task Slicing Protocol

## When to Slice

Slice a task if ANY of these are true:
- More than 3 acceptance criteria
- More than 5 files estimated to change
- Multiple independent improvements bundled together
- Task description exceeds ~200 words

## How to Slice

1. Break into sub-tasks with **single clear objective** each
2. Each sub-task should be completable in <15 minutes
3. Specify **exact files to read** (max 3-5 per sub-task)
4. Include verification steps in each sub-task

## Execution

- Run sub-tasks **sequentially** (not parallel)
- Verify each sub-task passes before starting next
- Pass results from sub-task N as context to N+1

## Context Scoping

Each sub-task prompt MUST include:
```
## Reference files (read ONLY these)
- file1.ts — reason
- file2.ts — reason
```

This prevents Claude Code from reading the entire codebase and exploding its context.

## Two-Phase Prompting (for unfamiliar codebases)

If Claude Code doesn't know the codebase:

**Phase 1 (read-only):** "Read these 3 files and summarize their structure and key patterns."

**Phase 2 (implement):** "Based on what you learned, implement X. Only modify file Y."

## Example

❌ Bad: "Improve worker exploration, mineral assignment, and soldier pathfinding"

✅ Good: Three separate sub-tasks:
1. "Improve idle worker exploration in balanced.js (read: balanced.js, GameAPI.ts, StateSerializer.ts)"
2. "Add smart mineral assignment in balanced.js (read: balanced.js, StateSerializer.ts)"
3. "Review soldier pathfinding in balanced.js (read: balanced.js, GameAPI.ts)"
