#!/bin/sh
# Purpose: selftest case — holding the next stage (v0.26.10.7 spec R12–R14; §5 stage-hold). The toy two-stage product
# (fixtures/stages.sh). The owner's hold asked (`stages.sh hold --after 1`), stage 1's ready close records the close
# and the tag as today, then `stage-hold n=1 state=on` and `run: stopped owner asked to hold after stage 1`. While held
# the staging candidate is HEAD: a correction to stage 1 passes the staging check on a staging receipt, gate 2 passes
# on it, and the production check computes stage 1's close conditions at HEAD and asks the corrected row again; graded,
# it is ready and `--record` tags vid/stage-1.1 at the candidate, vid/stage-1 unmoved. One more correction reaches
# staging only; `hold --off` records `state=off` and counts the one commit staging loses; after it the staging
# candidate is the newest stage candidate again, vid/stage-1.1. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/stages.sh"
fail() { echo "stage-hold: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gate2() { printf 'deploy-gate gate=2 state=start candidate=%s env=staging at=2026-10-20T10:00:00Z\ndeploy-gate gate=2 state=end result=pass at=2026-10-20T10:00:01Z\n' "$(git rev-parse --short=12 HEAD)" >> .vid/metrics-events; }
st_close_repo "$T/repo"
st_rcpt ROW-004=failed; st_keep ROW-001 ROW-002
sh checks/stages.sh hold --after 1 --words 'hold after this stage' > "$T/out" 2>&1 || fail 'the hold was refused'
grep -q '^stage-hold n=1 state=asked words="hold after this stage" at=' .vid/metrics-events || fail 'the asked hold is not recorded'
sh checks/metrics.sh stage-close --stage 1 --record > "$T/out" 2>&1
grep -q '^recorded: stage-closed n=1' "$T/out" && grep -q '^held: stage 1 is closed and held' "$T/out" || fail 'the close did not record and hold'
grep -q '^stage-hold n=1 state=on at=' .vid/metrics-events || fail 'the close did not write stage-hold … on'
grep -qx 'run: stopped owner asked to hold after stage 1' .vid/RUN-STATE.md || fail 'the run is not stopped by the hold'
grep -qx 'stage: 2' .vid/RUN-STATE.md || fail 'stage: is not 2'
TAG1=$(git rev-parse --short=12 'vid/stage-1^{commit}')
# a correction to stage 1: the staging candidate is HEAD
printf '# a correction\n' >> app/main.py; printf '# corrected\n' >> tests/invariants/test_a.py; g commit -qam 'a correction to stage 1'
C1=$(git rev-parse --short=12 HEAD)
sh checks/stages.sh candidate --target staging > "$T/out" 2>&1 && grep -qx "candidate $C1 head - 1" "$T/out" || fail 'while held the staging candidate is not HEAD'
R="$C1.live.sel-1.xml"
printf '<r>\n<case name="tests/invariants/test_a.py::t[ROW-001]" status="passed" time="0.1"/>\n<case name="tests/invariants/test_hos2.py::t[HOS-002]" status="passed" time="0.1"/>\n</r>\n' > ".vid/ledger-results/$R"
printf 'ledger-run seconds=3 kind=scoped report=%s status=0 role=orchestrator request=K1 type=staging at=2026-10-20T10:00:00Z\n' "$R" >> .vid/metrics-events
sh checks/metrics.sh deploy-check --target staging --record > "$T/out" 2>&1
grep -qx "base: $TAG1 (stage-closed n=1)" "$T/out" && grep -qx 'deploy-check staging ready rows=2 ahead=1' "$T/out" || fail 'the correction is not ready for staging'
gate2
# production: stage 1's close conditions at HEAD, and the corrected row asked again
st_rcpt ROW-004=failed
sh checks/metrics.sh deploy-check --target production > "$T/out" 2>&1
grep -qx 'regrade ROW-001' "$T/out" || fail 'the corrected row is not asked again'
st_keep ROW-001
sh checks/metrics.sh deploy-check --target production --record > "$T/out" 2>&1
grep -qx 'deploy-check production ready' "$T/out" || fail 'production is not ready once the row is graded'
[ "$(git rev-parse --short=12 'vid/stage-1.1^{commit}' 2>/dev/null)" = "$C1" ] || fail 'vid/stage-1.1 is not at the candidate'
[ "$(git rev-parse --short=12 'vid/stage-1^{commit}')" = "$TAG1" ] || fail 'vid/stage-1 moved'
# one more correction, staging only; then "continue"
printf '# another\n' >> tests/invariants/test_b.py; g commit -qam 'another correction'; gate2
sh checks/stages.sh hold --off > "$T/out" 2>&1 || fail 'hold --off was refused'
grep -q '^stage-hold n=1 state=off at=' .vid/metrics-events || fail 'continue did not record off'
grep -q "^continue: staging runs $(git rev-parse --short=12 HEAD), 1 commits past stage 1's candidate vid/stage-1.1 that no production deploy covers" "$T/out" || fail 'the reply does not count the commit staging loses'
sh checks/stages.sh candidate --target staging > "$T/out" 2>&1 && grep -qx "candidate $C1 tag vid/stage-1.1 1" "$T/out" || fail 'after continue the staging candidate is not the newest stage candidate'
exit 0
