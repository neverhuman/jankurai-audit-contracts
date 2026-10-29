#!/usr/bin/env bash
# Proves the release-notes command in docs/release.md fails closed: a valid
# published tag emits subjects and Todo trailers, while a missing, non-ancestor
# or unset tag stops before an existing notes file is replaced, and a branch
# named like the tag is never used in its place.
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

work="$(mktemp -d "${TMPDIR:-/tmp}/release-notes-test.XXXXXX")"
trap 'rm -rf "$work"' EXIT

# The block under test is the one the document ships, not a copy.
awk '/^```sh$/ { buf = ""; on = 1; next }
     /^```$/ && on { if (buf ~ /PREVIOUS_RELEASE_TAG/) printf "%s", buf; on = 0; next }
     on { buf = buf $0 "\n" }' "$repo/docs/release.md" > "$work/cmd.sh"
[[ -s "$work/cmd.sh" ]] || { echo "FAIL: no release-notes block in docs/release.md" >&2; exit 1; }

failures=0
ok()  { printf 'ok: %s\n' "$1"; }
bad() { printf 'FAIL: %s\n' "$1" >&2; failures=$((failures + 1)); }

fx="$work/fx"
mkdir "$fx"
cd "$fx"
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
git init -q -b main .
git config user.email t@example.invalid
git config user.name tester
printf '1.2.3\n' > VERSION
git add VERSION
git commit -q -m 'initial'
git tag v1
git commit -q --allow-empty -m 'Add widget' -m 'Todo: 20260101-000000-abc123'
git switch -q -c side v1
git commit -q --allow-empty -m 'Side work'
git tag side-tag
git switch -q main
# Branch "v2" exists but no tag "v2" does: the branch must not stand in for it.
git branch v2 v1

run() { PREVIOUS_RELEASE_TAG="$1" bash "$work/cmd.sh" >/dev/null 2>&1; }
notes=target/release-notes/1.2.3.md

if run v1; then ok "valid tag succeeds"; else bad "valid tag failed"; fi
if grep -qxF -- '- Add widget' "$notes" && grep -qxF 'Todo: 20260101-000000-abc123' "$notes"; then
  ok "notes carry subject and Todo trailer"
else
  bad "notes miss subject or trailer"
fi
if grep -qF 'initial' "$notes"; then bad "notes include commits at or before the tag"; else ok "range excludes the tag"; fi
if compgen -G 'target/release-notes/.1.2.3.*' >/dev/null; then bad "temp file left behind"; else ok "no temp file left"; fi

printf 'PRIOR\n' > "$notes"
for bad_tag in no-such-tag side-tag v2; do
  if run "$bad_tag"; then bad "$bad_tag was accepted"; else ok "$bad_tag rejected"; fi
  if [[ "$(cat "$notes")" == PRIOR ]]; then ok "$bad_tag left prior notes intact"; else bad "$bad_tag replaced prior notes"; fi
done
if env -u PREVIOUS_RELEASE_TAG bash "$work/cmd.sh" >/dev/null 2>&1; then bad "unset tag accepted"; else ok "unset tag rejected"; fi
if [[ "$(cat "$notes")" == PRIOR ]]; then ok "unset tag left prior notes intact"; else bad "unset tag replaced prior notes"; fi

(( failures == 0 )) || { echo "release-notes-test: $failures failure(s)" >&2; exit 1; }
echo "release-notes-test: all passed"
