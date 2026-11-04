#!/bin/sh
# Purpose: selftest case — an append under ticket mode materialises nothing (v0.26.10.9 spec R3; §5 append-tickets).
# The toy spec-only tree (fixtures/spec-only.sh), its spec committed, RUN-STATE at `mode: tickets`: the append's new
# row, ROW-006, written `owed: spec-only — ticket`, lands in a standalone law commit under the real hooks; the par holds
# with it counted legitimate (spec-only=5); no ledger file, receipt or proved-red stamp exists in ViD's repository
# after it. `spec-only — first stage` stays legal beside it. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/spec-only.sh"
fail() { echo "append-tickets: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
so_tree "$T/r"; so_commit 'the spec' > "$T/out" 2>&1 || fail 'the spec commit was refused'
mkdir -p .vid; printf 'run: active\nsession: S1\nmode: tickets\nplan: required\nstage: 1\n' > .vid/RUN-STATE.md
printf 'stage name=replan state=start session=S1 records=29 at=2026-10-24T10:00:00Z\n' > .vid/metrics-events
awk '{ print } /^ROW-005 / { print "ROW-006 | behavior | REQ-003 | anonymous | n/a | a note is read back after a restart | REQ-003 | owed: spec-only — ticket" }' INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md
g add INVENTORY.md
g commit -q -m "$(so_msg 'append A-002: ROW-006, its test owed to its ticket')" > "$T/out" 2>&1 || fail 'the appended spec-only — ticket row was refused'
sh checks/inventory.sh --report > "$T/out" 2>&1 || true
grep -q ' spec-only=5 ' "$T/out" && grep -q '^par: rows=6 materialised=0 legitimate=5 deploy-owed=1 other=0 — holds' "$T/out" || fail 'the par does not count the appended row legitimate'
grep -q '^OWED  ROW-006 (REQ-003) — owed: spec-only — ticket' "$T/out" || fail 'ROW-006 is not owed to its ticket'
[ ! -d tests ] && [ ! -d .vid/ledger-results ] && ! grep -q 'proved-red:' INVENTORY.md || fail 'something was materialised in ViD'"'"'s repository'
exit 0
