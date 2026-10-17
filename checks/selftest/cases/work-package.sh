#!/bin/sh
# Purpose: selftest case — the fixed work package stays what §7 case 15 says
# it is (v0.9.3 spec §7 case 15, R21), plugin repository only. Convicts
# unless the fixture's PRD is court-green; it carries two actor journeys;
# ARCHITECTURE names one feed boundary, one queue, one schedule and a seam
# with `credentials: not-yet` (the deploy-owed row); the README states the
# six seeds (a)–(f) at their named points and the counts; the scripted
# owner's stack line is left for the evaluator; and the driver is marked
# owner-run. The run itself is never part of the suite. Env: CHECKS.
set -eu
F="$CHECKS/selftest/fixtures/work-package"
[ -d "$F" ] || exit 0
fail() { echo "work-package: $*" >&2; exit 1; }
sh "$CHECKS/prd.sh" "$F/PRD.md" --report | grep -q ' gaps=0 ' || fail 'the PRD is not court-green'
[ "$(sed -n '/^## Actors and journeys/,/^## /p' "$F/PRD.md" | grep -c '^### ')" -eq 2 ] || fail 'not two actor journeys'
grep -q 'one external INPUT boundary' "$F/ARCHITECTURE.md" || fail 'no feed boundary'
grep -q 'the one queue, `work`' "$F/ARCHITECTURE.md" || fail 'not one queue'
grep -q 'one schedule, the' "$F/ARCHITECTURE.md" || fail 'not one schedule'
grep -q 'Credentials: not-yet' "$F/ARCHITECTURE.md" || fail 'no seam without credentials (the deploy-owed row)'
for s in '(a) a routing with no consumer' '(b) the session killed mid-slice' '(c) a ledger run killed mid-way' '(d) an owner append amending one Fail-if' '(e) the deploy-owed row' '(f) a row whose module no slice planned'; do
  grep -qF "$s" "$F/README.md" || fail "the README lacks seed $s"
done
grep -q 'STACK: ____' "$F/owner-answers.md" || fail "the stack is chosen by the evaluator at the run, never shipped"
head -n 3 "$F/run-package.sh" | grep -q 'OWNER-RUN' || fail 'the driver is not marked owner-run'
exit 0
