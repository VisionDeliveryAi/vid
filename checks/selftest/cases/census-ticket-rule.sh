#!/bin/sh
# Purpose: selftest case — a ticket-mode rule row (v0.26.10.25.5.1, found by 6.5's test): the planner's rule row, `origin: plan`,
# `owed: spec-only — ticket`, names its places in words for the dev side (`sites: … :: guarded: …`), which counts them and
# reports `covers:` (V2 §3.2). On the toy spec-only tree (fixtures/spec-only.sh) a commit holding such a row passes the real
# hooks; census reports it pending, counted in pending=, and runs nothing. Develop's census is unchanged: the same words under a
# row owed census-armed still run, and still fail on their standard error. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/spec-only.sh"
fail() { echo "census-ticket-rule: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
so_tree "$T/r"
W='sites: every form a person submits, field by field :: guarded: those whose field changes what is stored'
awk -v w="$W" '/^rule \| RULE-001 /{ print; print "rule | RULE-002 | every field a person gives is acted on | " w " | 1 | owed: spec-only — ticket | origin: plan REQ-001"; next } { print }' INVENTORY.md > I.t && mv I.t INVENTORY.md
printf '# toy\n\n```vid-placement\napp/\ndesign/\n```\n' > CLAUDE.md
so_commit 'the spec, with a ticket-mode rule row' > "$T/out" 2>&1 || fail 'the real hooks refused a commit holding a ticket-mode rule row'
sh checks/census.sh > "$T/out" 2>&1 || fail 'census refused a ticket-mode rule row'
grep -q '^PEND  RULE-002  a ticket-mode rule row: its places are counted by the dev side, never run here$' "$T/out" || fail 'census does not report RULE-002 pending'
! grep -q 'command not found' "$T/out" || fail 'census ran the row'"'"'s words'
grep -q '^census: .* pending=[1-9]' "$T/out" || fail 'the row is not counted in pending='
# develop unchanged: the same words, owed census-armed, still run and fail
sed 's/| owed: spec-only — ticket | origin: plan REQ-001$/| owed: census-armed — armed when the forms land/' INVENTORY.md > I.t && mv I.t INVENTORY.md
grep -q '^rule | RULE-002 .*owed: census-armed' INVENTORY.md || fail 'the control row was not written'
RC=0; sh checks/census.sh > "$T/out" 2>&1 || RC=$?; [ "$RC" != 0 ] && grep -q '^FAIL  RULE-002  census command wrote to standard error' "$T/out" || fail "a develop rule row's census no longer runs ($RC)"
# and a row owed spec-only — first stage (develop's spec-only init) still runs too
sed 's/| owed: census-armed — armed when the forms land$/| owed: spec-only — first stage/' INVENTORY.md > I.t && mv I.t INVENTORY.md
RC=0; sh checks/census.sh > "$T/out" 2>&1 || RC=$?; [ "$RC" != 0 ] && grep -q '^FAIL  RULE-002  census command wrote to standard error' "$T/out" || fail "a first-stage rule row's census no longer runs ($RC)"
exit 0
