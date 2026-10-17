#!/bin/sh
# Purpose: selftest case — a held row (v0.9.7.2 spec 3.6, R9). ROW-003 is held (two product rounds) and RUN-STATE's
# open question Q1 names it. Held rows are outside eligibility, yet done waits for them: S1, closed with its other
# rows KEPT, is not done, and step-state names `held step=S1 row=ROW-003 reason=bound question=Q1`. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/breadth.sh"
fail() { echo "done-held: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bf_repo "$T/repo"
bf_on > /dev/null; bf_plan "$S1L" "$S2L" > /dev/null
sh checks/plan.sh start S1 > /dev/null; close S1 ROW-001=passed ROW-002=passed ROW-003=passed ROW-004=passed > /dev/null; keepall ROW-001 ROW-002 ROW-004
for n in 1 2; do printf 'verdict slice=1 row=ROW-003 result=BREACHED class=product brief=.vid/briefs/1/grader-%s.md quoted-at=%s at=%s\n' "$n" "$(git rev-parse HEAD)" "$(utcnow)" >> .vid/metrics-events; done
printf '\n## Open product questions\n\n- Q1 · asked 2026-10-13 · gates ROW-003 · does the export include archived rows?\n' >> .vid/RUN-STATE.md
ss S1 > "$T/out"
grep -q '^step-state step=S1 .* done=no eligible=3 ' "$T/out" || fail 'S1 is done with a held row (or the held row counts as eligible)'
grep -q '^held step=S1 row=ROW-003 reason=bound question=Q1' "$T/out" || fail 'the held row is not named with its question'
exit 0
