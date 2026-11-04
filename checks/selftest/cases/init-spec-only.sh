#!/bin/sh
# Purpose: selftest case — a spec-only init's commits pass the courts on a tree with no code (v0.26.10.9 spec R1, R3;
# §5 init-spec-only). The toy spec-only tree (fixtures/spec-only.sh: writable rows `owed: spec-only — first stage`, one
# row owed to deploy gate 2, one census-armed RULE row, one guard-first HOS row, checks/ installed, no code, no harness,
# no extractor): the spec commit (VID_ROLE=fix, the template message) and a STAGES.md commit pass pre-commit and
# commit-msg under the real hooks; the par holds with spec-only=4 counted legitimate and the other classes kept;
# `owed: spec-only` without its detail, or with another detail, is refused (by=inventory). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/spec-only.sh"
fail() { echo "init-spec-only: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
so_tree "$T/r"
so_commit 'the spec' > "$T/out" 2>&1 || fail 'the spec commit was refused on a tree with no code'
[ "$(git log --format=%s | head -n 1)" = 'the spec' ] || fail 'the spec commit did not land'
[ ! -e docker-compose.test.yml ] && [ ! -d checks/extractors ] && [ ! -d app ] || fail 'the toy is not a tree without code'
printf '# Stages\n\n```vid-stages\nSTAGE-1 | everything | features: -\nsplit: REQ-001 REQ-002 REQ-003 -> STAGE-1\n```\n' > STAGES.md
so_commit 'the stage cut' 'Owner: A-001 one stage' > "$T/out" 2>&1 || fail 'the STAGES.md commit was refused'
[ "$(git log --format=%s | head -n 1)" = 'the stage cut' ] || fail 'the STAGES.md commit did not land'
sh checks/inventory.sh --report > "$T/out" 2>&1 || true
grep -q 'guard-first=1 census-armed=1 .* prerequisite=0 spec-only=4 ' "$T/out" || fail 'the class split does not count spec-only=4 beside the other classes'
grep -q '^par: rows=5 materialised=0 legitimate=4 deploy-owed=1 other=0 — holds' "$T/out" || fail 'the par does not hold with the spec-only rows legitimate'
for bad in 'owed: spec-only' 'owed: spec-only — later'; do
  so_row ROW-002 "$bad"; g add INVENTORY.md
  if VID_ROLE=fix g commit -q -m "$(so_msg 'a bare spec-only')" > "$T/out" 2>&1; then fail "'$bad' was accepted"; fi
  grep -q "GAP  ROW-002 .*unclassed deferral" "$T/out" || fail "the refusal of '$bad' does not name ROW-002 as unclassed"
  tail -n 1 .vid/hook-times | grep -q ' by=inventory' || fail "'$bad' was not refused by the inventory court"
  g checkout -q HEAD -- INVENTORY.md
done
so_row ROW-002 'owed: spec-only — ticket'; sh checks/inventory.sh > "$T/out" 2>&1 || fail "'spec-only — ticket' is not a legal detail"
exit 0
