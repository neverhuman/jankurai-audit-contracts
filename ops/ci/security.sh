#!/usr/bin/env bash
# Security lane: secret scanning and SBOM/provenance for the
# contract surface. Delegates to the canonical tools/security-lane.sh wrapper so
# local runs (`just security`) and CI run the exact same commands.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "$REPO_ROOT"

mkdir -p target
log "security lane: gitleaks detect + sbom"
bash tools/security-lane.sh
