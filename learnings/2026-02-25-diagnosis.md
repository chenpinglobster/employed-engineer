# 2026-02-25 — Claude Code 卡住問題診斷與改進方向

## 觀察到的問題

在 miniRTS balanced.js 的改進任務中，employed-engineer 監督下的 Claude Code 多次卡住：
- 第一次：卡在 "Fermenting..." 思考循環 50+ 分鐘
- 第二次：修了部分 bug 但在測試階段卡住
- 第三次（cron 排程）：卡在 "Harmonizing..." 16 分鐘，沒產出程式碼

反觀人工直接分析 replay + 寫 code，10 分鐘就解決了。

## 根因分析

### 1. 缺乏 Full Log
employed-engineer 的 monitor 只看到 Claude Code 的最後幾行輸出。
無法事後判斷：卡在哪句話、卡了多久、思考階段在想什麼。

**改進：** Monitor 應保存 Claude Code 的完整 terminal log（tmux capture-pane 或 script 命令），
任務結束後可供事後分析。

### 2. 任務太大塊
三個改進項目（worker 探索、礦場分配、soldier 尋路）一次丟給 Claude Code。
這導致 context 爆炸 + 思考時間過長。

**改進：** employed-engineer 應將大任務拆成子任務，一個一個餵給 Claude Code。
每個子任務完成後再給下一個。

### 3. Context 爆炸
Claude Code 理論上會自己決定讀哪些檔案，但在大型 codebase 中：
- 它可能讀太多無關檔案
- 或花太多時間在「理解全貌」而非「解決問題」

**改進方案 A：** 在 prompt 中明確指定參考範圍
```
重點檔案：
- scripts/balanced.js（要修改的目標）
- src/sandbox/Sandbox.ts（IIFE 包裝邏輯）
- src/sandbox/GameAPI.ts（可用 API 列表）
- src/sandbox/StateSerializer.ts（game.state 結構）
```

**改進方案 B：** 兩階段 prompt
1. 第一個 prompt：「閱讀這些檔案，理解 codebase 結構，總結你的理解」
2. 第二個 prompt：「基於你的理解，執行以下任務：...」

這樣第二階段 Claude Code 已經有 codebase 的 mental model，
不需要在執行任務時同時理解 + 實作。

## 行動項目

- [ ] employed-engineer SKILL.md 加入 full log 保存機制
- [ ] employed-engineer SKILL.md 加入「大任務拆分」的 policy
- [ ] employed-engineer SKILL.md 加入「context scoping」的 prompt template
- [ ] 考慮「兩階段 prompt」模式作為可選策略
- [ ] 建立 learnings/ 目錄，每次失敗後記錄教訓（learning loop 的開始）
