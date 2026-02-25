#!/usr/bin/env bash
# run_claude.sh — Launch Claude Code with automatic full terminal logging
# Usage: ./run_claude.sh <project_dir> "<prompt>"
#
# Automatically captures complete PTY output to a timestamped log file.
# Monitor does NOT need to manually save logs — this script handles it.

set -euo pipefail

PROJECT_DIR="${1:?Usage: run_claude.sh <project_dir> \"<prompt>\"}"
PROMPT="${2:?Usage: run_claude.sh <project_dir> \"<prompt>\"}"

# Ensure artifacts directory exists
ARTIFACTS_DIR="${PROJECT_DIR}/acceptance/artifacts/latest"
mkdir -p "$ARTIFACTS_DIR"

# Timestamped log file
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${ARTIFACTS_DIR}/claude_${TIMESTAMP}.log"

echo "=== Claude Code Session ===" > "$LOG_FILE"
echo "Started: $(date -Iseconds)" >> "$LOG_FILE"
echo "Project: ${PROJECT_DIR}" >> "$LOG_FILE"
echo "Log: ${LOG_FILE}" >> "$LOG_FILE"
echo "===========================" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

cd "$PROJECT_DIR"

# Use `script` to capture all PTY output (works on macOS and Linux)
if [[ "$(uname)" == "Darwin" ]]; then
  # macOS: script -q <logfile> <command> <args...>
  script -q "$LOG_FILE" claude "$PROMPT"
else
  # Linux: script -q -c "<command>" <logfile>
  script -q -c "claude \"$PROMPT\"" "$LOG_FILE"
fi

echo "" >> "$LOG_FILE"
echo "=== Session ended: $(date -Iseconds) ===" >> "$LOG_FILE"

echo ""
echo "📄 Full log saved to: ${LOG_FILE}"
