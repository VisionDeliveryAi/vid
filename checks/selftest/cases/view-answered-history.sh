#!/bin/sh
# Purpose: selftest case — Needs you shows every answered question (v0.9.8.1 R22). The viewer fixture, its answer
# ledger gaining A-004 with no Q: (as consolidation leaves it) and A-002 marked delegated. Convicts unless the
# snapshot's needsYou.answered lists every answer, newest first (A-004 first); A-004's entry in decisions.answers
# keeps an empty question (nothing inferred); the page carries the answered list and its "not recorded" reading; the
# snapshot passes the check; and the check refuses an answered id that is no answer of the snapshot. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-answered-history: $*" >&2; cat "$T/r" >&2 2>/dev/null; exit 1; }
view_project "$T/repo"
awk '/^```vid-prd-answers$/ { n++ } { print } n == 2 && /^A-001 AMENDED/ { print "A-004 | human | 2026-01-02 | A: Weekly, on Mondays. | settles: REQ-002" }' PRD.md > PRD.x && mv PRD.x PRD.md
grep -q '^A-004 | human' PRD.md || fail 'the fixture did not take A-004'
g add PRD.md; vcommit 11:31 'an answer without its question'
printf 'delegated answer=A-002 at=%s\n' "$(vt 11:32)" >> .vid/metrics-events
vview . --out "$T/o" > "$T/r" 2>&1 || fail 'the run failed'
vdata "$T/o/now.html" > "$T/d"
A=$(sed -n 's/.*"answered":\(\[[^]]*\]\).*/\1/p' "$T/d")
[ "$A" = '["A-004","A-003","A-002","A-001"]' ] || fail "needsYou.answered is not every answer, newest first: $A"
grep -q '{"id":"A-004","amended":false,"tier":"human","date":"2026-01-02","q":"","a":"Weekly, on Mondays."' "$T/d" || fail 'A-004 is not read as recorded, its question empty'
grep -q 'every answer the records hold, newest first' "$T/o/now.html" && grep -q "NR='not recorded'" "$T/o/now.html" && grep -qF '...this.ansV(D),' "$T/o/now.html" || fail 'the page lacks the answered list'
sh "$VIEWER_SH" --check "$T/o/now.html" > "$T/r" 2>&1 || fail 'the snapshot fails the check'
sed 's/"answered":\["A-004"/"answered":["A-999"/' "$T/o/now.html" > "$T/o/bad.html"
if sh "$VIEWER_SH" --check "$T/o/bad.html" > "$T/r" 2>&1; then fail 'the check took an answered id that is no answer'; fi
grep -q 'needsYou.answered\[0\] cites A-999' "$T/r" || fail 'the check does not name the bad answered id'
exit 0
