#!/usr/bin/env bash
# run_claude.sh — Launch Claude Code with automatic logging + thinking loop watchdog
# Usage: ./run_claude.sh <project_dir> "<prompt>" [timeout_seconds]
#
# Features:
#   - Full PTY capture via `script` command
#   - Watchdog: kills Claude Code if no output for THINKING_TIMEOUT seconds
#   - Timestamped log file in acceptance/artifacts/latest/

set -euo pipefail

PROJECT_DIR="${1:?Usage: run_claude.sh <project_dir> \"<prompt>\" [timeout_seconds]}"
PROMPT="${2:?Usage: run_claude.sh <project_dir> \"<prompt>\" [timeout_seconds]}"
THINKING_TIMEOUT="${3:-300}"  # Default 5 minutes

# Setup
ARTIFACTS_DIR="${PROJECT_DIR}/acceptance/artifacts/latest"
mkdir -p "$ARTIFACTS_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${ARTIFACTS_DIR}/claude_${TIMESTAMP}.log"

cd "$PROJECT_DIR"

echo "📄 Log: ${LOG_FILE}"
echo "⏱️  Thinking timeout: ${THINKING_TIMEOUT}s"

# Watchdog: monitor log file for staleness, kill claude if stuck
watchdog() {
  local pid="$1"
  local logfile="$2"
  local timeout="$3"
  
  while kill -0 "$pid" 2>/dev/null; do
    sleep 10
    
    # Check if log file was modified recently
    if [[ -f "$logfile" ]]; then
      local now last_mod age
      now=$(date +%s)
      if [[ "$(uname)" == "Darwin" ]]; then
        last_mod=$(stat -f %m "$logfile")
      else
        last_mod=$(stat -c %Y "$logfile")
      fi
      age=$((now - last_mod))
      
      if [[ $age -gt $timeout ]]; then
        echo "" >> "$logfile"
        echo "=== WATCHDOG: No output for ${age}s (limit ${timeout}s) — killing process ===" >> "$logfile"
        echo "⚠️  WATCHDOG: Thinking loop detected (${age}s silent). Killing Claude Code."
        kill "$pid" 2>/dev/null || true
        return 1
      fi
    fi
  done
  return 0
}

# Run claude under `script` for full PTY capture
if [[ "$(uname)" == "Darwin" ]]; then
  script -q "$LOG_FILE" claude "$PROMPT" &
else
  script -q -c "claude \"$PROMPT\"" "$LOG_FILE" &
fi
CLAUDE_PID=$!

# Start watchdog in background
watchdog "$CLAUDE_PID" "$LOG_FILE" "$THINKING_TIMEOUT" &
WATCHDOG_PID=$!

# Wait for claude to finish
wait "$CLAUDE_PID" 2>/dev/null
EXIT_CODE=$?

# Clean up watchdog
kill "$WATCHDOG_PID" 2>/dev/null || true
wait "$WATCHDOG_PID" 2>/dev/null || true

echo ""
echo "=== Session ended: $(date -Iseconds) | exit: ${EXIT_CODE} ===" >> "$LOG_FILE"
echo "📄 Full log: ${LOG_FILE}"

if [[ $EXIT_CODE -ne 0 ]]; then
  echo "⚠️  Claude Code exited with code ${EXIT_CODE}"
fi

exit $EXIT_CODE
