#!/bin/sh
# Purpose: selftest case — the test analyst's brief (v0.9.7.0.3 spec 3.2;
# §6 B-3). checks/brief.sh accepts a `role: test-analyst` brief, which
# needs no section 6, and refuses one that carries `checks/test.sh
# request` — in section 6 or anywhere — naming the line: the analyst runs
# nothing. v0.9.7.0.11 (3.7, R7): when the ticket it names kept
# timelines, a brief leaving out timeline.deployed.log is refused naming
# it, and one naming both is accepted. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "brief-analyst: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 1; commit_all rows
B=.vid/briefs/1/test-analyst-1.md; mkdir -p .vid/briefs/1
{ printf 'role: test-analyst    slice: 1\nquoted-at: %s\n' "$(git rev-parse --short=12 HEAD)"
  printf 'receives: the ticket folder, the receipt'"'"'s cases, the rows, the harness contract    must not receive: plan prose, verdicts, attempt records, other briefs\n\n'
  printf '## 1 rows\n\n'; sed -n '/^```vid-inventory/,/^```$/p' INVENTORY.md | grep -E '^ROW-001[[:space:]]*\|'
  printf '\nticket 20261002T101500Z-ab12 — result: analyst due: slow request=20261002T101500Z-ab12 rows=ROW-001\n'; } > "$B"
sh checks/brief.sh "$B" > "$T/out" 2>&1 || fail 'a test-analyst brief with no section 6 was refused'
grep -q 'role test-analyst' "$T/out" || fail 'the acceptance does not name the role'
for where in sect6 prose; do
  if [ "$where" = sect6 ]; then { cat "$B"; printf '\n## 6 test requests\n\nsh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why "look again" -- tests/invariants\n'; } > "$T/x.md"
  else { cat "$B"; printf '\nIf unsure, run sh checks/test.sh request --type iterate --role fixer --try t1 --rows ROW-001 --why "x" -- tests\n'; } > "$T/x.md"; fi
  cp "$T/x.md" .vid/briefs/1/test-analyst-x.md
  if sh checks/brief.sh .vid/briefs/1/test-analyst-x.md > "$T/out" 2>&1; then fail "a test-analyst brief carrying a test request ($where) was accepted"; fi
  grep -q 'test-analyst brief: carries a test request (line [0-9]*)' "$T/out" || fail "the $where refusal does not name the line"
done
mkdir -p .vid/requests/20261002T101500Z-ab12; : > .vid/requests/20261002T101500Z-ab12/timeline.inline.log; : > .vid/requests/20261002T101500Z-ab12/timeline.deployed.log
{ cat "$B"; printf '\nthe timelines: timeline.inline.log\n'; } > .vid/briefs/1/test-analyst-x.md
if sh checks/brief.sh .vid/briefs/1/test-analyst-x.md > "$T/out" 2>&1; then fail 'a test-analyst brief leaving out a kept timeline was accepted'; fi
grep -q 'does not name timeline.deployed.log, which ticket 20261002T101500Z-ab12 kept' "$T/out" || fail 'the refusal does not name the timeline left out'
{ cat "$B"; printf '\nthe timelines: timeline.inline.log, timeline.deployed.log\n'; } > .vid/briefs/1/test-analyst-x.md
sh checks/brief.sh .vid/briefs/1/test-analyst-x.md > "$T/out" 2>&1 || fail 'a test-analyst brief naming both timelines was refused'
exit 0
