#!/bin/sh
# Purpose: selftest case — the records at each moment (v0.9.7.4 spec 3.2, 3.4, R3). The viewer fixture, with its
# live RUN-STATE's plan block changed after the fact (ROW-003 moved to S2, no plan change recorded). Convicts unless
# each snapshot reads only the records up to its time and the plan of the last plan change by then: before the
# plan change (building started, 10:10) no step and no step on any promise; at S1's close (10:40) ROW-006 red (r2
# came at 11:10), ROW-001 and ROW-002 built (their hand-back's build-cost is 10:31), no judgment (10:45), ROW-003 in
# S1; at the checkpoint (11:20) question 1 open, its wording not recorded, question 2 (11:25) absent, no agents and
# no prose (now only); at now question 2 with its own wording, the agent and ROW-001's prose. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-replay-records: $*" >&2; exit 1; }
view_project "$T/repo"
sed 's/rows: ROW-001..ROW-003 ROW-006/rows: ROW-001 ROW-002 ROW-006/; s/rows: ROW-004 ROW-005 ROW-007/rows: ROW-003 ROW-004 ROW-005 ROW-007/' .vid/RUN-STATE.md > .vid/rs.x && mv .vid/rs.x .vid/RUN-STATE.md
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the run failed: $(cat "$T/r")"
d() { vdata "$T/out/$1.html"; }
d 20260101T101000Z-building-started > "$T/b"
grep -q '"steps":\[\]' "$T/b" || fail 'steps exist before the plan change'
if grep -q '"step":"S' "$T/b"; then fail 'a promise has a step before the plan change'; fi
d 20260101T104000Z-step-closed > "$T/s"
grep -q '{"id":"ROW-006",.*"state":"red"' "$T/s" || fail 'ROW-006 is not red at the close'
grep -q '{"id":"ROW-001",.*"built":true,"judgments":\[\]}' "$T/s" || fail 'ROW-001 is not built and unjudged at the close'
grep -q '{"id":"ROW-003",.*"step":"S1"' "$T/s" || fail 'ROW-003 is not in S1 (the recorded plan)'
grep -q '{"id":"ROW-003",.*"built":false' "$T/s" || fail 'ROW-003 reads as built'
d 20260101T112000Z-checkpoint > "$T/c"
grep -q '"questions":\["Q1 · asked 2026-01-01 · gates ROW-004, ROW-005 · wording not recorded' "$T/c" || fail "the checkpoint's open question is not Q1 with its wording not recorded"
if grep -q 'Q2' "$T/c"; then fail 'the checkpoint reads a question asked after it'; fi
grep -q '"agentsOpen":\[\],"recentCommits":\[\],"planChanges":\[\]' "$T/c" || fail 'a past snapshot carries activity'
grep -q '"prose":null' "$T/c" && ! grep -q 'reads the list' "$T/c" || fail 'a past snapshot carries review prose'
grep -q '"nowOnly":true' "$T/c" || fail 'a past snapshot does not say what is shown at now only'
d now > "$T/n"
grep -q '"questions":\["Q2 · asked 2026-01-01 · gates ROW-004 · May a restock exceed the shelf? Recommended: no\."\]' "$T/n" || fail 'now does not carry the open question as written'
grep -q '"agentsOpen":\[{"name":"builder b0b0b0b0' "$T/n" || fail 'now does not list the open agent'
grep -q '"prose":"The test searches the name and reads the list\.\\n"' "$T/n" || grep -q '"prose":"The test searches the name and reads the list\."' "$T/n" || fail 'now lacks the prose'
exit 0
