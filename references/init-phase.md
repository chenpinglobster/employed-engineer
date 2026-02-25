# INIT Phase

Detects project type and bootstraps acceptance scaffolding.

## Step 1: Language Detection (by files)

- Node/TS: `package.json` + lockfile
- Python: `pyproject.toml` or `requirements.txt`
- Go: `go.mod`
- Rust: `Cargo.toml`

## Step 2: Project Type Detection

| Type | Detection Rule | Strategy File |
|------|----------------|---------------|
| CLI | `package.json` has `bin` | `strategies/cli.md` |
| API | Has `routes/` or `controllers/` | `strategies/api.md` |
| Library | Has `main`/`exports`, no `bin` | `strategies/library.md` |
| GUI (React) | Deps include `react` | `strategies/gui-react.md` |
| GUI (Vanilla) | Has `.html`, no framework | `strategies/gui-vanilla.md` |
| Unknown | None of above | ESCALATE |

Cache result: `echo '{"type":"library"}' > acceptance/project_type.json`

## Step 3: Bootstrap Templates

Creates: `acceptance/smoke.sh`, `acceptance/run_allowed.sh`, `acceptance/artifacts/.gitkeep`

Done when: `./acceptance/run_allowed.sh smoke` exits 0

## Step 4: Load Strategy

On first VERIFY: read `acceptance/project_type.json` → load matching `strategies/*.md`
