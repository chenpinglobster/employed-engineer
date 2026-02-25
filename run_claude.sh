#!/usr/bin/env bash
# run_claude.sh — Launch Claude Code in project directory
# Usage: ./run_claude.sh <project_dir> "<prompt>"
#
# Thinking loop detection and log capture are handled by the monitor.
# This script just ensures correct working directory and passes the prompt.

set -euo pipefail

PROJECT_DIR="${1:?Usage: run_claude.sh <project_dir> \"<prompt>\"}"
PROMPT="${2:?Usage: run_claude.sh <project_dir> \"<prompt>\"}"

cd "$PROJECT_DIR"
exec claude "$PROMPT"
