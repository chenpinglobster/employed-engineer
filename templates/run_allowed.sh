#!/usr/bin/env bash
# run_allowed.sh - Wrapper for all allowed commands
# EmployedEngineer: Only commands through this wrapper are approved

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARTIFACTS_DIR="${SCRIPT_DIR}/artifacts/latest"
COMMANDS_LOG="${ARTIFACTS_DIR}/commands.log"

# Ensure artifacts directory exists
mkdir -p "${ARTIFACTS_DIR}"

# Initialize commands log
log_command() {
    local task="$1"
    local cmd="$2"
    local exit_code="$3"
    local start_time="$4"
    local end_time="$5"
    
    echo "---" >> "${COMMANDS_LOG}"
    echo "timestamp: $(date -Iseconds)" >> "${COMMANDS_LOG}"
    echo "task: ${task}" >> "${COMMANDS_LOG}"
    echo "command: ${cmd}" >> "${COMMANDS_LOG}"
    echo "exit_code: ${exit_code}" >> "${COMMANDS_LOG}"
    echo "duration_ms: $(( (end_time - start_time) * 1000 ))" >> "${COMMANDS_LOG}"
    echo "cwd: $(pwd)" >> "${COMMANDS_LOG}"
}

# Denylist check - prevent dangerous commands from being wrapped
check_denylist() {
    local cmd="$1"
    
    local denylist=(
        "rm -rf /"
        "rm -rf ~"
        "sudo"
        "chmod 777"
        "> /dev/"
        "| bash"
        "| sh"
        "curl.*|.*sh"
        "wget.*|.*sh"
    )
    
    for pattern in "${denylist[@]}"; do
        if [[ "$cmd" =~ $pattern ]]; then
            echo "❌ DENIED: Command matches denylist pattern: ${pattern}" >&2
            exit 1
        fi
    done
}

# Environment allowlist - only these env vars are passed through
filter_env() {
    # Clear sensitive env vars
    unset AWS_SECRET_ACCESS_KEY
    unset GITHUB_TOKEN
    unset NPM_TOKEN
    unset PRIVATE_KEY
    unset DATABASE_URL
    # Add more as needed
}

# Task definitions
run_task() {
    local task="$1"
    shift
    local extra_args="$*"
    
    case "${task}" in
        smoke)
            # Minimal healthcheck - should always pass on clean repo
            echo "🔥 Running smoke test..."
            if [[ -f "package.json" ]]; then
                npm run --if-present lint 2>/dev/null || true
                echo "✅ Smoke: Node.js project detected"
            elif [[ -f "pyproject.toml" ]] || [[ -f "requirements.txt" ]]; then
                python3 --version
                echo "✅ Smoke: Python project detected"
            elif [[ -f "go.mod" ]]; then
                go version
                echo "✅ Smoke: Go project detected"
            elif [[ -f "Cargo.toml" ]]; then
                cargo --version
                echo "✅ Smoke: Rust project detected"
            else
                echo "⚠️ Smoke: Unknown project type"
            fi
            ;;
        
        test)
            echo "🧪 Running tests..."
            if [[ -f "package.json" ]]; then
                npm test 2>&1 | tee "${ARTIFACTS_DIR}/test_output.txt"
            elif [[ -f "pyproject.toml" ]]; then
                pytest 2>&1 | tee "${ARTIFACTS_DIR}/test_output.txt"
            elif [[ -f "go.mod" ]]; then
                go test ./... 2>&1 | tee "${ARTIFACTS_DIR}/test_output.txt"
            elif [[ -f "Cargo.toml" ]]; then
                cargo test 2>&1 | tee "${ARTIFACTS_DIR}/test_output.txt"
            fi
            ;;
        
        lint)
            echo "🔍 Running linter..."
            if [[ -f "package.json" ]]; then
                npm run lint 2>&1 || true
            elif [[ -f "pyproject.toml" ]]; then
                ruff check . 2>&1 || pylint **/*.py 2>&1 || true
            elif [[ -f "go.mod" ]]; then
                golangci-lint run 2>&1 || true
            elif [[ -f "Cargo.toml" ]]; then
                cargo clippy 2>&1 || true
            fi
            ;;
        
        typecheck)
            echo "📝 Running type checker..."
            if [[ -f "tsconfig.json" ]]; then
                npx tsc --noEmit 2>&1
            elif [[ -f "pyproject.toml" ]]; then
                mypy . 2>&1 || true
            fi
            ;;
        
        format)
            echo "✨ Running formatter..."
            if [[ -f "package.json" ]]; then
                npm run format 2>&1 || npx prettier --write . 2>&1 || true
            elif [[ -f "pyproject.toml" ]]; then
                ruff format . 2>&1 || black . 2>&1 || true
            elif [[ -f "go.mod" ]]; then
                go fmt ./... 2>&1
            elif [[ -f "Cargo.toml" ]]; then
                cargo fmt 2>&1
            fi
            ;;
        
        build)
            echo "🔨 Running build..."
            if [[ -f "package.json" ]]; then
                npm run build 2>&1
            elif [[ -f "Cargo.toml" ]]; then
                cargo build 2>&1
            elif [[ -f "go.mod" ]]; then
                go build ./... 2>&1
            fi
            ;;
        
        e2e)
            echo "🎭 Running E2E tests..."
            if [[ -f "playwright.config.ts" ]] || [[ -f "playwright.config.js" ]]; then
                npx playwright test 2>&1 | tee "${ARTIFACTS_DIR}/e2e_output.txt"
            elif [[ -f "cypress.config.ts" ]] || [[ -f "cypress.config.js" ]]; then
                npx cypress run 2>&1 | tee "${ARTIFACTS_DIR}/e2e_output.txt"
            else
                echo "⚠️ No E2E framework detected"
                exit 1
            fi
            ;;
        
        integration)
            echo "🔗 Running integration tests..."
            if [[ -f "package.json" ]]; then
                npm run test:integration 2>&1 || npm test -- --testPathPattern=integration 2>&1
            fi
            ;;
        
        *)
            echo "❌ Unknown task: ${task}" >&2
            echo "Available tasks: smoke, test, lint, typecheck, format, build, e2e, integration" >&2
            exit 1
            ;;
    esac
}

# Main
main() {
    if [[ $# -lt 1 ]]; then
        echo "Usage: $0 <task> [args...]" >&2
        echo "Tasks: smoke, test, lint, typecheck, format, build, e2e, integration" >&2
        exit 1
    fi
    
    local task="$1"
    shift
    
    filter_env
    
    local start_time=$(date +%s)
    local exit_code=0
    
    # Capture output
    local output_file="${ARTIFACTS_DIR}/${task}_output.txt"
    
    if run_task "${task}" "$@" 2>&1 | tee "${output_file}"; then
        exit_code=0
        echo "✅ Task '${task}' completed successfully"
    else
        exit_code=$?
        echo "❌ Task '${task}' failed with exit code ${exit_code}"
    fi
    
    local end_time=$(date +%s)
    
    # Log the command
    log_command "${task}" "run_allowed.sh ${task} $*" "${exit_code}" "${start_time}" "${end_time}"
    
    # Parse test output and generate enhanced report
    local total_tests=0 passed_tests=0 failed_tests=0 skipped_tests=0
    local failure_type="unknown"
    local failure_evidence=""
    local suggested_fix=""
    local auto_patchable="false"
    
    if [[ -f "${output_file}" ]]; then
        # Parse vitest output
        if grep -q "Test Files.*failed" "${output_file}"; then
            total_tests=$(grep -oP '\d+(?= failed)' "${output_file}" | head -1)
            passed_tests=$(grep -oP '\d+(?= passed)' "${output_file}" | head -1)
            failed_tests=$(grep -oP '\d+(?= failed)' "${output_file}" | head -1)
            
            # Analyze failure patterns
            if grep -q "expected.*to have a length of.*but got" "${output_file}"; then
                failure_type="test_isolation"
                failure_evidence="Multiple tests show length mismatches indicating shared state"
                suggested_fix="Use unique temp files per test (see vitest.setup.ts)"
                auto_patchable="true"
            elif grep -q "Cannot find module" "${output_file}"; then
                failure_type="missing_dependency"
                failure_evidence=$(grep "Cannot find module" "${output_file}" | head -1)
                suggested_fix="Run: npm install <missing-module>"
                auto_patchable="false"
            elif grep -q "Type.*is not assignable to type" "${output_file}"; then
                failure_type="type_error"
                failure_evidence=$(grep "is not assignable to type" "${output_file}" | head -1)
                suggested_fix="Fix type mismatches in TypeScript code"
                auto_patchable="true"
            fi
        fi
        
        # Parse pytest output
        if grep -q "passed.*failed" "${output_file}"; then
            passed_tests=$(grep -oP '\d+(?= passed)' "${output_file}" | tail -1)
            failed_tests=$(grep -oP '\d+(?= failed)' "${output_file}" | tail -1)
            total_tests=$((passed_tests + failed_tests))
        fi
    fi
    
    # Generate enhanced report
    cat > "${ARTIFACTS_DIR}/report.json" << EOF
{
  "version": "1.1",
  "timestamp": "$(date -Iseconds)",
  "task": {
    "id": "${task}",
    "description": "Auto-generated from run_allowed.sh",
    "duration_ms": $(( (end_time - start_time) * 1000 ))
  },
  "status": "$([ ${exit_code} -eq 0 ] && echo 'pass' || echo 'fail')",
  "exit_code": ${exit_code},
  "tests": {
    "total": ${total_tests},
    "passed": ${passed_tests},
    "failed": ${failed_tests},
    "skipped": ${skipped_tests}
  },
  "failure_analysis": {
    "type": "${failure_type}",
    "confidence": "$([ "${failure_type}" != "unknown" ] && echo 'high' || echo 'low')",
    "evidence": "${failure_evidence}",
    "suggested_fix": "${suggested_fix}",
    "auto_patchable": ${auto_patchable}
  },
  "files_changed": {
    "added": [],
    "modified": [],
    "deleted": []
  },
  "artifacts": {
    "log": "${task}_output.txt",
    "log_tail": "log_tail.txt",
    "commands": "commands.log"
  }
}
EOF
    
    # Capture log tail
    tail -50 "${output_file}" > "${ARTIFACTS_DIR}/log_tail.txt" 2>/dev/null || true
    
    # Generate diffstat if in git repo
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        git diff --stat HEAD~1 2>/dev/null > "${ARTIFACTS_DIR}/diffstat.txt" || \
        git diff --stat 2>/dev/null > "${ARTIFACTS_DIR}/diffstat.txt" || true
    fi
    
    exit ${exit_code}
}

main "$@"
