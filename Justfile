# jankurai-contracts root command surface.
# One-command setup and validation lanes for agents and CI.
# This is a JSON-schema and artifact-contract repository: the proof loop is
# schema validation plus the jankurai self-audit. Every lane below is
# deterministic, hermetic, and runnable from the repo root.

# Default: list available lanes.
default:
    @just --list

# One-command bootstrap: install the validation tooling this repo needs.
setup:
    bash ops/ci/required.sh

# Alias for setup so `just install` and `just bootstrap` also resolve.
install: setup

bootstrap: setup

# Deterministic fast lane: the narrowest proof loop for agent iteration.
# Validate every schema is well-formed JSON, then run the jankurai self-audit.
fast:
    jq empty schemas/*.json
    jankurai audit . --no-score-history --json .jankurai/repo-score.json --md .jankurai/repo-score.md

# Run the full local check: fast lane, drift, security, and the audit lane.
check: fast drift security audit

# Contract-drift lane: openapi-diff style check for breaking contract removals.
drift:
    bash ops/ci/contract-drift.sh # openapi-diff over schemas/ and contracts/

# Security lane: secret scanning and SBOM/provenance.
# gitleaks scans the committed tree for secrets; the SBOM hashes every shipped
# contract file.
security:
    bash tools/security-lane.sh

# Verify is an alias of check for agents that look for a `verify` lane.
verify: check

# Lint every JSON schema as well-formed JSON.
lint:
    jq empty schemas/*.json

# Validate the schema and contract surface.
test:
    jq empty schemas/*.json

# Jankurai self-audit lane: writes the repo-score artifacts that CI uploads.
audit:
    jankurai audit . --no-score-history --json .jankurai/repo-score.json --md .jankurai/repo-score.md

# Print the declared version.
versions:
    cat VERSION
