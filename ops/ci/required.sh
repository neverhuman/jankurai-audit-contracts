#!/usr/bin/env bash
# Required lane: the lightweight gate that must pass on every push.
# Validates that every committed schema under schemas/ is well-formed JSON.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "$REPO_ROOT"

log "required lane: contract-drift controls"
require_tool node
node --test scripts/contract-drift.test.mjs

log "required lane: jq empty schemas/*.json"
jq empty schemas/*.json
