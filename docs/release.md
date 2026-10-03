# Release process

This document is the release control surface for jankurai-contracts. It covers
the version source, the changelog, the release automation, integrity and SBOM
evidence, and rollback. Launch gates require every section below to be backed by
a real artifact or command.

## Version source

The single source of truth for the version is the [`VERSION`](../VERSION) file at
the repository root. Any release tag MUST match `VERSION`. Tags follow the
family pattern `jankurai-contracts-v<MAJOR.MINOR.PATCH>-split.<N>` as described
in [`SPLIT.md`](../SPLIT.md).

## Changelog

Every release records its user-visible changes in
[`CHANGELOG.md`](../CHANGELOG.md) under a heading that matches the new `VERSION`.
The `Unreleased` section is promoted to a dated version heading at tag time.

## Release automation

GitHub is a publishing mirror only. CI runs on the forge and our own hosts, and
releases are built and signed on our servers. A separate change introduces
key-based release signing.

1. Bump [`VERSION`](../VERSION) and promote the `Unreleased` section of
   [`CHANGELOG.md`](../CHANGELOG.md).
2. Run the full local gate: `just check` (schema validation plus the jankurai
   self-audit).
3. Push the version commit through a forge pull request. The forge CI runs the
   fast and jankurai audit lanes and keeps the `repo-score` artifacts.
4. Tag the release commit with `jankurai-contracts-v<version>-split.<N>`. The
   tag mirror in [`.jeryu/repo.toml`](../.jeryu/repo.toml) publishes the
   immutable tag to the public GitHub mirror.

Release builds depend on immutable tags, never branches.

## Integrity, provenance, and SBOM

- **Schema integrity**: every schema under `schemas/` is validated as
  well-formed JSON by the required and fast lanes on every push, so a release
  can never ship a malformed contract.
- **SBOM**: this repository has no compiled dependency graph; its bill of
  materials is the enumerated list of contract files. Generate a release
  manifest with
  `find schemas contracts -type f -name '*.json' | sort | xargs sha256sum > sbom.txt`
  and attach it to the release as `sbom.txt` so every shipped contract is hashed
  and accounted for.
- **Provenance**: the jankurai audit job publishes the `repo-score` artifacts
  (`.jankurai/repo-score.json` and `.md`) that prove the release passed the
  jankurai gate. The audit JSON is the signed record of the score and findings.

## Launch gate

Before a contract release is tagged it must clear an explicit launch gate. Every
item below is backed by a command or artifact, not a claim:

- **Security**: the fast and required lanes validate every schema, and the
  jankurai audit job publishes `repo-score` evidence; every CI action is pinned
  to a 40-character SHA so the release pipeline supply chain is fixed.
- **Backups**: the authoritative history lives in the Jeryu repo and the GitHub
  mirror; every release is an immutable tag, so each shipped contract set has a
  durable, recoverable backup that can be checked out by tag at any time.
- **Monitoring**: downstream family repos consume these schemas and run their
  own jankurai audit, which surfaces contract drift; the `repo-score.json`
  artifact is the monitored signal that a release stayed green.
- **Rollback**: re-point consumers at the previous immutable tag (see below);
  tags are never moved or deleted, so rollback is always available.
- **Abuse and rate limits**: this repository serves only static contract files
  and runs no paid or user-facing endpoint, so there is no request surface to
  rate limit. Mirror-push and tag operations are restricted to maintainers via
  the Jeryu and GitHub mirror permissions, which bound abuse of the release
  pipeline itself.

## Rollback

If a release regresses (a contract is removed or breaks downstream consumers):

1. Identify the last known-good tag (`jankurai-contracts-v<version>-split.<N>`).
2. Re-point consumers at that immutable tag; tags are never moved or deleted.
3. Open a revert commit that restores the previous `VERSION` and
   `CHANGELOG.md` state, and add a `### Fixed` entry describing the rollback.
4. Re-run `just check` to confirm the rolled-back tree is green before
   re-publishing.

Because tags are immutable and every contract is hashed in the release SBOM, any
prior release of the contract surface can be reproduced exactly from its tag.
