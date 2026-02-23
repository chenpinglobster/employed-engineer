# Plan Mode Guide

## Overview

Plan mode offloads deep architectural thinking to Claude Code (Opus subscription, unlimited use). This saves your (Sonnet API) tokens for execution supervision.

**When you've decided to use plan mode** (from PLAN Phase complexity assessment), follow this guide.

---

## Workflow

### 1. Formulate Design Question

**Be specific about the architectural decision:**

❌ Bad: "Design the system"
✅ Good: "Multi-tenant database: schema-per-tenant vs row-level isolation. Tradeoffs for 1000+ tenants?"

❌ Bad: "Make it fast"
✅ Good: "Caching strategy for user profile API: Redis vs in-memory LRU. 10k RPS target, stale data tolerance 5 min?"

**Template:**
```
"[Problem context]: [Option A] vs [Option B] vs [Option C].
 [Key constraints or metrics]?"
```

### 2. Spawn Plan Mode

**Default: Background monitoring**

```bash
# Spawn in background (most cases)
exec pty:true background:true workdir:/path/to/project \
  command:"claude plan '[your design question]'"

# Returns: {"sessionId": "plan-xyz"}
```

**Why background:**
- Plan mode typically completes in 2-5 minutes
- Rarely needs interaction (Claude thinks, outputs recommendation)
- Frees you to do other work while waiting
- Uses same monitoring pattern as IMPLEMENT (30s + 90s)

**When to use foreground (rare):**
- You know you'll need to provide additional context mid-discussion
- Iterative exploration where you want to refine the question

```bash
# Foreground (interactive)
exec pty:true background:false workdir:/path/to/project \
  command:"claude plan '[your design question]'"
```

### 3. Monitor (Background Plan)

**Same pattern as IMPLEMENT phase:**

```bash
# First check: 30s
sleep 30
process action:log sessionId:plan-xyz limit:50

# Check for:
# - "Ready to implement" or "Recommendation: ..."
# - Unexpected errors
# - Request for more information

# If still working, subsequent checks: 90s intervals
sleep 90
process action:log sessionId:plan-xyz limit:50

# Repeat until completion
```

**System events apply:**
- `[System Message] Exec finished` → check output immediately
- If Claude asks a question → respond via `process action:write`

### 4. Extract Design Decisions

**When plan mode completes, read the output:**

```bash
# Get final output
process action:log sessionId:plan-xyz limit:100

# Look for:
# - Recommended approach
# - Key constraints/tradeoffs mentioned
# - Implementation guidance
```

**Example output:**

```
Analyzing caching strategy...

Option 1: Redis (external)
  ✓ Shared across instances
  ✓ Persistence
  ✗ Network latency (~1-2ms per request)
  ✗ Additional infrastructure

Option 2: In-memory LRU (per-instance)
  ✓ Zero latency
  ✓ Simple deployment
  ✗ No sharing (cache per instance)
  ✗ Cold start penalty

Option 3: Hybrid (L1 in-memory + L2 Redis)
  ✓ Fast path for hot data
  ✓ Shared cold data
  ✗ More complexity

Recommendation: Option 3 (Hybrid)
- Use node-cache for L1 (TTL: 5 min)
- Redis for L2 (TTL: 30 min)
- Estimated hit rate: 85% L1, 10% L2, 5% miss
- Meets 10k RPS target with ~0.5ms avg latency

Implementation notes:
- Serialize once per object (avoid double serialization)
- Use pipeline for Redis multi-get
- Monitor L1/L2 hit rates
```

**Take notes:**
- Chosen architecture: Hybrid L1/L2 cache
- Key constraints: node-cache (5min) + Redis (30min)
- Performance target: 10k RPS, 0.5ms avg latency
- Watch-outs: monitor hit rates

---

## Write Task Package

**Based on plan mode output, create clear task package for IMPLEMENT:**

```markdown
Task: [Brief description]

Architecture (from plan mode):
- [Chosen approach]
- [Key design decisions]
- [Constraints to enforce]

Acceptance Criteria:
- [ ] [Criterion from plan]
- [ ] [Performance target from plan]
- [ ] [...]

Use ./acceptance/run_allowed.sh for all commands.
```

**Example (from caching plan above):**

```bash
# Task package for IMPLEMENT phase
"Implement hybrid caching for user profile API.

Architecture (from plan mode):
- L1: node-cache (TTL 5min, max 10k entries)
- L2: Redis (TTL 30min)
- Fallback to DB on miss
- Single serialization per object

Acceptance:
- [ ] 10k RPS load test passes
- [ ] Avg latency < 0.5ms (p99 < 2ms)
- [ ] L1 hit rate > 80% in test
- [ ] Graceful degradation if Redis down

Use ./acceptance/run_allowed.sh for all commands."
```

---

## Examples: When to Use Plan Mode

### ✅ Use Plan Mode

#### Example 1: API Design

**Task:** "Design REST API for task management with subtasks and comments"

**Why plan?**
- Resource structure unclear (nested vs flat resources?)
- Endpoint design (/tasks/123/subtasks vs /subtasks?taskId=123?)
- Auth/permissions strategy

**Plan query:**
```
"REST API design for hierarchical tasks (task > subtask > comment).
 Resource structure: nested vs flat? Auth: per-resource vs inherited?
 Pagination and filtering patterns?"
```

**Expected output:**
- Recommended resource structure
- Endpoint schema
- Query parameter conventions
- Auth strategy

#### Example 2: Database Schema

**Task:** "Design schema for event sourcing system"

**Why plan?**
- Event store structure (single table vs per-aggregate?)
- Snapshot strategy
- Query patterns for projections

**Plan query:**
```
"Event sourcing schema design: event store structure (single table vs sharded?).
 Snapshot frequency tradeoffs. Projection query optimization for 1M+ events?"
```

**Expected output:**
- Table design
- Indexing strategy
- Snapshot policy
- Migration path

#### Example 3: State Management

**Task:** "Add real-time collaboration to document editor"

**Why plan?**
- State sync algorithm (CRDT vs Operational Transform?)
- Conflict resolution strategy
- Network efficiency

**Plan query:**
```
"Real-time collaborative editing: CRDT vs OT for rich text.
 Implementation complexity, conflict resolution, and network efficiency tradeoffs?"
```

**Expected output:**
- Recommended algorithm
- Conflict resolution rules
- Sync protocol
- Edge case handling

#### Example 4: Performance Optimization

**Task:** "Optimize search for 10M+ records"

**Why plan?**
- Indexing strategy (B-tree vs full-text vs vector?)
- Trade-offs between index size, speed, accuracy
- Scaling approach

**Plan query:**
```
"Search optimization for 10M records: indexing strategy (PostgreSQL full-text vs Elasticsearch).
 Query latency target <100ms, relevance vs performance tradeoffs?"
```

**Expected output:**
- Recommended search engine
- Index configuration
- Query structure
- Scaling approach

### ❌ Skip Plan Mode

**Simple implementation tasks:**

- "Add email validation to signup form" → Standard pattern
- "Fix mobile responsive layout for navbar" → Incremental UI fix
- "Update user model to include phone number" → Straightforward schema change
- "Add logging to error handler" → Minor enhancement
- "Upgrade React from 18.2 to 18.3" → Dependency update

---

## Token Efficiency Analysis

### Scenario: Build VWAP Oracle (Complex Task)

**With plan mode:**

1. **Plan (2 min, background):**
   - Spawn: 0 tokens
   - Monitor: 2 checks (30s + 90s) = ~6k tokens
   - Extract: 1k tokens
   - **Subtotal: 7k tokens**

2. **Implement (15 min, background):**
   - Spawn: 0 tokens
   - Monitor: 11 checks (30s + 90s×10) = ~33k tokens
   - Verify artifacts: 2k tokens
   - **Subtotal: 35k tokens**

**Total: ~42k tokens**

**Without plan mode (guess and iterate):**

1. **Implement wrong approach (10 min):**
   - Monitor: 7 checks = ~21k tokens
   - Verify + discover issue: 3k tokens

2. **PATCH cycle (discuss fix, re-implement):**
   - Discussion: 5k tokens
   - Re-implement (12 min): 8 checks = ~24k tokens
   - Verify: 2k tokens

**Total: ~55k tokens** (31% more)

**Savings: 13k tokens (~24%)**

Plus intangible benefits:
- Higher quality implementation (thought through upfront)
- Fewer surprises during verification
- Less cognitive load on supervisor (you)

---

## Common Patterns

### Pattern 1: Binary Choice

**When:** Two clear alternatives, need to compare

**Query template:**
```
"[Context]: [Option A] vs [Option B].
 [Key constraint]. Which is better for [specific goal]?"
```

**Example:**
```
"Authentication: JWT vs session cookies.
 Mobile + web clients. Which is better for security and UX?"
```

### Pattern 2: Design Exploration

**When:** Problem space unclear, need to explore options

**Query template:**
```
"How to [goal] given [constraints]?
 Consider [relevant factors]."
```

**Example:**
```
"How to implement rate limiting for API (1000 req/min per user)?
 Consider distributed deployment (3+ instances) and Redis availability."
```

### Pattern 3: Optimization

**When:** Existing approach, need to improve specific metric

**Query template:**
```
"Optimize [component] for [metric].
 Current: [baseline]. Target: [goal].
 Constraints: [what can't change]."
```

**Example:**
```
"Optimize image upload pipeline for throughput.
 Current: 50 uploads/sec. Target: 500/sec.
 Constraints: max 2GB RAM, single server."
```

---

## Troubleshooting

### "Plan mode output is too vague"

**Symptom:** Claude says "it depends" or lists options without recommendation

**Cause:** Question too open-ended or missing constraints

**Fix:**
```bash
# Add specific constraints to the query
process action:write sessionId:plan-xyz data:"Constraint: Must support 1000 concurrent users, budget $200/month for infrastructure."
```

### "Plan took too long (>5 min)"

**Symptom:** Still running after 5+ minutes

**Diagnosis:**
```bash
process action:log sessionId:plan-xyz limit:50
# Check if stuck or legitimately thinking
```

**Action:**
- If output shows progress → wait longer
- If stuck/looping → interrupt and simplify question

### "Plan mode recommended something I can't use"

**Symptom:** Suggested tech not available in your stack

**Prevention:** Include stack constraints in query

```bash
# Bad query
"Database design for analytics?"

# Good query
"Database design for analytics. Stack: Node.js, existing PostgreSQL (v14), no budget for new services."
```

---

## Summary

**Plan mode is for:** Deep architectural thinking before implementation
**Saves tokens by:** Reducing iteration/PATCH cycles (get design right first)
**Monitor like:** IMPLEMENT phase (30s + 90s background checks)
**Output:** Clear recommendation with rationale → becomes task package

**Default to background monitoring** unless you know you need interaction.
