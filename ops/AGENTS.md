# Ops Guidance

Owns the pinned CI lane entrypoints under `ops/ci/` and the git hooks under
`ops/git-hooks/`.

- Owns: `ops/ci/*.sh` (required, fast, security, audit, tool-adoption,
  quality-gates), `ops/git-hooks/pre-push`.
- Forbidden: GitHub Actions workflows. GitHub is a publishing mirror only; CI
  runs on the forge and our own hosts and calls `bash ops/ci/<lane>.sh`, so
  local runs and CI execute the exact same commands (see `scripts/ci-local.sh`).
- Proof lane: `bash scripts/ci-local.sh gates` runs required -> fast -> audit.

Read `AGENTS.md` at the repo root first for split-family routing rules.
