# Command Approval Examples

Quick reference for handling Claude Code command prompts.

---

## AUTO-APPROVE ✅

Commands that are immediately approved.

### Example 1: Test via wrapper

```
Prompt: Do you want to run ./acceptance/run_allowed.sh test? (y/N)
Action: submit "y"
Log: AUTO-APPROVED: wrapper task 'test'
```

### Example 2: Lint via wrapper

```
Prompt: Run "./acceptance/run_allowed.sh lint"? [y/N]
Action: submit "y"
Log: AUTO-APPROVED: wrapper task 'lint'
```

### Example 3: Smoke test

```
Prompt: `./acceptance/run_allowed.sh smoke`
Action: submit "y"
Log: AUTO-APPROVED: wrapper task 'smoke'
```

---

## APPROVE-WITH-CHECK ⚠️

Commands that need context before approval.

### Example 1: E2E tests (expensive)

```
Prompt: Run ./acceptance/run_allowed.sh e2e? (y/N)

Check: Is E2E needed for this task's acceptance criteria?
- If yes: submit "y"
- If no: submit "n", say "Skip E2E for now, not in acceptance criteria"
```

### Example 2: Build step

```
Prompt: Run ./acceptance/run_allowed.sh build? (y/N)

Check: Does acceptance require a built artifact?
- If yes: submit "y"
- If no: submit "n", say "Build not needed for this verification"
```

---

## DENY ❌

Commands that must be rejected.

### Example 1: Non-wrapper test command

```
Prompt: Run pnpm test? [y/N]
Action: submit "n"
Response: "請改用 ./acceptance/run_allowed.sh test"
Log: DENIED: non-wrapper command 'pnpm test'
```

### Example 2: Direct npm command

```
Prompt: Do you want to run npm run lint? (y/N)
Action: submit "n"
Response: "請改用 ./acceptance/run_allowed.sh lint"
Log: DENIED: non-wrapper command 'npm run lint'
```

### Example 3: High-risk deletion

```
Prompt: Run rm -rf node_modules? [y/N]
Action: submit "n"
Response: "❌ 高風險命令被拒絕。如需清理 node_modules，請手動執行或加入 wrapper。"
Log: DENIED: high-risk pattern 'rm -rf'
```

### Example 4: Git push (deployment)

```
Prompt: Run git push origin main? [y/N]
Action: submit "n"
Response: "❌ 禁止直推主分支。需要人工審核後才能 push。"
Log: DENIED: deployment command 'git push'
```

### Example 5: Sensitive path access

```
Prompt: Run cat ~/.ssh/id_rsa? [y/N]
Action: submit "n"
Response: "❌ 敏感路徑被拒絕"
Log: DENIED: sensitive path '~/.ssh'
```

---

## ESCALATE 🚨

Commands that require supervisor approval.

### Example 1: Kubernetes deployment

```
Prompt: Run kubectl apply -f deployment.yaml? [y/N]

Action: STOP (do not submit)
Message to supervisor:

⚠️ 需要主管批准的操作

- 命令: kubectl apply -f deployment.yaml
- 目的: 部署應用到 Kubernetes cluster
- 風險: 可能影響生產環境
- 替代方案: 使用 --dry-run 先預覽變更
- 建議: 確認目標 cluster 和 namespace

等待主管回覆後再繼續。
```

### Example 2: Docker push

```
Prompt: Run docker push myapp:latest? [y/N]

Action: STOP
Message to supervisor:

⚠️ 需要主管批准的操作

- 命令: docker push myapp:latest
- 目的: 推送 Docker image 到 registry
- 風險: 會覆蓋現有的 :latest tag
- 替代方案: 使用版本號 tag (如 myapp:v1.2.3)
- 建議: 確認 registry 和 tag 策略
```

### Example 3: NPM publish

```
Prompt: Run npm publish? [y/N]

Action: STOP
Message to supervisor:

⚠️ 需要主管批准的操作

- 命令: npm publish
- 目的: 發布套件到 npm registry
- 風險: 公開發布，不可撤銷
- 替代方案: 使用 --dry-run 先測試
- 建議: 確認版本號和 changelog
```

---

## Extraction Patterns

How to extract commands from different prompt styles:

| Style | Pattern | Example |
|-------|---------|---------|
| Backticks | `` `cmd` `` | Run `pnpm test`? |
| Quotes | `"cmd"` | Run "npm install"? |
| Claude style | `(y/N)` | Do you want to run X? (y/N) |
| Alternative | `[y/N]` | Run X? [y/N] |
| Narrative | `wants to run:` | Agent wants to run: X |

---

## Decision Flowchart

```
Command received
       │
       ▼
┌─────────────────┐
│ Is it wrapper?  │──No──► DENY + guide to wrapper
│ run_allowed.sh  │
└────────┬────────┘
         │Yes
         ▼
┌─────────────────┐
│ Safe task?      │──No──► Check risk level
│ (smoke/test/    │           │
│  lint/format)   │           ▼
└────────┬────────┘     ┌───────────┐
         │Yes           │ Denylist? │──Yes──► DENY
         │              └─────┬─────┘
         │                    │No
         │                    ▼
         │              ┌───────────┐
         │              │ Deploy?   │──Yes──► ESCALATE
         │              └─────┬─────┘
         │                    │No
         ▼                    ▼
   AUTO-APPROVE        APPROVE-WITH-CHECK
```
