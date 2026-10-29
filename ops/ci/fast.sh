#!/usr/bin/env bash
# Deterministic fast lane: the narrowest proof loop for agent iteration.
# This is a JSON-schema repository, so the fast proof is "every schema is
# well-formed JSON" followed by the jankurai self-audit. The identical command
# set is exposed locally via `just fast` and `bash scripts/ci-local.sh fast`.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "$REPO_ROOT"
require_auditor

mkdir -p .jankurai
log "fast lane: jq empty schemas/*.json + jankurai audit"
jq empty schemas/*.json
"$JANKURAI_BIN" audit . --no-score-history --json .jankurai/repo-score.json --md .jankurai/repo-score.md --full

assert_artifact .jankurai/repo-score.json
