# Changelog

All notable changes to jankurai-contracts are documented in this file. The
format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
The authoritative version string lives in [`VERSION`](VERSION).

## [Unreleased]

## [1.7.3] - 2026-10-06

### Changed

- `agent/standard-version.toml` declares `auditor_version = "1.7.3"` (was `1.6.0`), the family auditor pin the hub's `validate-family` checks for the 1.7.3 release.

### Removed

- GitHub Actions workflows and the GitHub-only job aggregator
  (`ops/ci/aggregate.sh`, `scripts/ci-aggregate.mjs` and its test). GitHub is a
  publishing mirror only; CI runs on the forge and our own hosts, and releases
  are built and signed on our servers.

### Added

- Root `Justfile` command surface with `setup`, `fast`, `check`, `lint`, `test`,
  and `audit` lanes for one-command setup and validation.
- GitHub Actions CI (`.github/workflows/ci.yml`) with a deterministic fast lane
  (schema validation) and a jankurai audit job, all third-party actions pinned
  to commit SHAs.
- Agent-readable documentation: `README.md`, `docs/architecture.md`,
  `docs/boundaries.md`, `docs/testing.md`, `docs/release.md`, and
  `docs/exceptions.md`.
- `agent/audit-policy.toml` with scan exclusions scoped to this repo's transient
  output paths.

### Changed

- Re-scoped `agent/owner-map.json`, `agent/test-map.json`, and
  `agent/generated-zones.toml` to the paths that exist in this schema and
  contract repository.

## [1.7.0] - 2026-06-12

### Added

- Initial split-family extraction of the jankurai JSON Schemas and artifact
  contracts.
