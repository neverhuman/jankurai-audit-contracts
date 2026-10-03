# Testing

This repository ships data, not a running service, so "testing" here means
proving that every contract surface is well-formed, internally consistent, and
validated by the jankurai self-audit. This document is the agent-readable map of
those proofs.

## Proof lanes

| Lane | Command | What it proves |
| --- | --- | --- |
| required | `bash scripts/ci-local.sh required` | every schema under `schemas/` is well-formed JSON |
| fast | `bash scripts/ci-local.sh fast` | required lane plus the jankurai self-audit |
| audit | `bash scripts/ci-local.sh audit` | jankurai audit writes `repo-score` artifacts |
| gates | `bash scripts/ci-local.sh gates` | required -> fast -> audit, the full local gate |

The same lanes are exposed through the root [`Justfile`](../Justfile)
(`just fast`, `just check`, `just audit`) and run unchanged in CI via
`ops/ci/<lane>.sh`, so a green local gate means a green CI run.

## Fast lane

The narrowest deterministic proof loop is `just fast`:

```bash
jq empty schemas/*.json
jankurai audit . --no-score-history --json .jankurai/repo-score.json --md .jankurai/repo-score.md
```

`jq empty` parses each schema and exits non-zero on the first malformed file.
The jankurai audit then scores the whole repository against the standard.

## Observability

Every lane prints structured `[ci] <message>` progress lines via the `log`
helper in [`ops/ci/lib.sh`](../ops/ci/lib.sh), so a failing run names the lane
and the step that failed. The audit lane asserts its `repo-score` artifacts
exist with `assert_artifact`, surfacing missing-output failures explicitly
rather than silently. The audit's machine-readable JSON report
(`.jankurai/repo-score.json`) is the canonical, inspectable record of every
finding, its `rule_id`, `path`, and severity.

## Cost budget

This repo runs no model calls, no paid APIs, and no long-running builds, so its
recurring CI cost budget is effectively zero: two short lanes (schema validation
and a single audit invocation), each budgeted at a 20-minute timeout. The fast
lane is designed to complete in seconds locally so agent iteration stays cheap.

Explicit budget policy for any paid or unbounded operation introduced later:

- **Budget and quota**: the per-run compute budget is the 20-minute job timeout;
  the quota is at most one full audit invocation per job. There is no per-token
  spend because no model or paid API is called.
- **Spend cap and kill switch**: the job timeout is the hard spend cap and acts
  as the kill switch — a lane that exceeds it is terminated by CI.
- **Stop condition**: any future lane that introduces a non-trivial compute,
  token, or paid-API cost MUST declare its own budget, quota, spend cap, kill
  switch, and stop condition in this section before it is added; until then the
  stop condition is "no paid work runs in this repository."

## Repair hints and exception receipts

Every finding the audit emits is a structured repair receipt, not just a log
line. When a lane fails, read the finding object in `.jankurai/repo-score.json`,
which carries the fields an agent needs to act:

- `purpose` / `problem` — what the check proves and why it failed.
- `reason` — the underlying cause the check detected.
- `agent_fix` — the concrete edit to make; this is the catalog of **common fixes**
  for each `rule_id`.
- `docs_url` — the rule's documentation anchor.
- `repair_hint` — the rerun command and the narrowest lane that re-proves the fix.

The convention is: each failing check names its `rule_id`, its `path`, a
`reason`, a `repair_hint`, and the `rerun command` (for example `just fast`), so
the next agent always knows where to rerun proof. Exceptions to a rule follow the
same receipt shape and are recorded as data in
[`docs/exceptions.md`](exceptions.md): an exception states its `purpose`, its
`reason`, its owner, and its expiry.

## Artifact contracts

The index of which durable artifact validates against which schema or guard is
maintained in [`docs/artifact-contracts.md`](artifact-contracts.md). Treat that
file as the source of truth before changing any generated or durable surface.
