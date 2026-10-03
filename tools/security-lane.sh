#!/usr/bin/env bash
# Canonical security lane wrapper for jankurai-contracts.
#
# This repository ships static JSON contracts, so its security posture is:
#  - secret scanning of the committed tree (gitleaks),
#  - and a software bill of materials enumerating + hashing every contract file
#    (syft-style SBOM via sha256 over schemas/ and contracts/).
# The same lane runs locally via `just security` and in CI via ops/ci/security.sh.
set -euo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[security] secret scan: gitleaks detect"
gitleaks detect --source . --no-banner --redact

echo "[security] SBOM / provenance: hash every contract file"
# syft-equivalent: a hashed bill of materials of every shipped contract.
find schemas contracts -type f -name '*.json' | sort | xargs sha256sum > target/sbom.txt
echo "[security] sbom written to target/sbom.txt"
