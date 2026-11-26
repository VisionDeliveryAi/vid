#!/bin/sh
# Purpose: selftest case — a row the owner struck has no charge (FIX-BATCH-T1 §14, B-11). A develop run (not GitHub manual):
# step S1 started with ROW-001..ROW-003, ROW-003 also on the protected: line, ROW-001 and ROW-002 not passing. ROW-003 struck
# from INVENTORY.md and ROW-004 added, in one commit. Convicts unless: a change leaving ROW-002 (still a row, red) in no step is
# refused naming ROW-002 alone; with unverified-rows=3, a change with S1 holding ROW-001, ROW-002 and ROW-004 and the protected:
# line gone is accepted and recorded (3 unverified; the struck row charged would make 4) and the charge no longer holds ROW-003;
# a builder brief for S1 is then admitted. And in a second run whose block keeps only a rule row after its one ROW is struck,
# the charge drops that ROW; with INVENTORY.md gone, it drops nothing. And in GitHub auto (mode: tickets, its re-plan
# through plan.sh change), a struck row of a started step leaves it, evidence.sh never called. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"; . "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "plan-struck-row: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 3; commit_all rows
SH="shared: $PLANS_SHARED"
plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001..ROW-003' 'protected: ROW-003' "$SH"
sh checks/plan.sh change create 'the plan' --trigger initial --expect 'the steps build in order' > /dev/null
sh checks/plan.sh start S1 > "$T/out" 2>&1 || fail 'S1 was refused at its start'
rcpt r1 HEAD inline ROW-001=failed ROW-002=failed ROW-003=passed
# the owner strikes ROW-003; ROW-004 is added
grep -v '^ROW-003 ' INVENTORY.md > i && mv i INVENTORY.md; rows s1 4 4; commit_all 'the owner strikes ROW-003; ROW-004 added'
# ROW-002 (still a row, red) dropped beside it: refused, naming ROW-002 alone
plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001' "$SH"
if sh checks/plan.sh change rows 'ROW-002 out' --trigger unknown --expect 'the steps build in order' > "$T/out" 2>&1; then fail 'a red row still in INVENTORY.md left its started step'; fi
grep -q 'leaves rows of started steps in no step: ROW-002\.' "$T/out" || fail 'the refusal does not name ROW-002 alone'
# the struck row leaves its step and the protected: line; rule A counts 3, not 4
printf 'unverified-rows=3\n' > .vid/budget
plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002 ROW-004' "$SH"
sh checks/plan.sh change rows 'ROW-003 struck by the owner; ROW-004 in its place' --trigger unknown --expect 'the steps build in order' > "$T/out" 2>&1 || fail 'the change with the struck row gone was refused'
grep -q '^plan-change what=rows ' .vid/metrics-events || fail 'the change was not recorded'
sh checks/plan.sh charged > "$T/ch" 2>&1; grep -q '^ROW-003	' "$T/ch" && fail 'the struck row is still charged'
grep -q '^ROW-001	' "$T/ch" || fail 'a row INVENTORY.md holds lost its charge'
brief .vid/briefs/1/builder-1.md builder S1 ROW-001
sh checks/brief.sh .vid/briefs/1/builder-1.md > "$T/out" 2>&1 || fail 'a builder brief for S1 was refused after the change'
# the last ROW struck, a rule row left: a read, so the charge drops it; no INVENTORY.md: drops nothing
plan_repo "$T/two"; rows s1 1 1
awk '/^```$/ && !d { print "rule | RULE-001 | every write is atomic | checks/extractors/invariant.atomic.sh | 0 | owed: census-armed — armed later | origin: REQ-001"; d = 1 } { print }' INVENTORY.md > i && mv i INVENTORY.md; commit_all rows
plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'the plan' --trigger initial --expect 'it builds' > /dev/null
sh checks/plan.sh start S1 > "$T/out" 2>&1 || fail 'the second run refused its S1'
grep -v '^ROW-001 ' INVENTORY.md > i && mv i INVENTORY.md; commit_all 'the last ROW struck'
sh checks/plan.sh charged > "$T/ch" 2>&1; grep -q '^ROW-001	' "$T/ch" && fail 'with no ROW left in the block, the struck row is still charged'
mv INVENTORY.md "$T/inv.away"
sh checks/plan.sh charged > "$T/ch" 2>&1; grep -q '^ROW-001	' "$T/ch" || fail 'with INVENTORY.md gone, the charge dropped a row'
# GitHub auto (mode: tickets, not manual): its re-plan goes through plan.sh change. A started with ROW-001 and ROW-002,
# ROW-002 struck: the change keeping A with ROW-001 is accepted, and evidence.sh (a stub that must never run in ticket mode)
# is not called — before, the struck row was an orphan read through it
. "$CHECKS/selftest/fixtures/stages.sh"
rm -rf "$T/auto"; mkdir -p "$T/auto/checks" "$T/auto/.vid"; cd "$T/auto"; git init -q
cp "$CHECKS/plan.sh" "$CHECKS/planner.sh" "$CHECKS/lib.sh" "$CHECKS/stages.sh" "$CHECKS/prd.sh" checks/
printf '#!/bin/sh\n# Purpose: a stub that must never run\n: > "%s/evidence-called"\nexit 1\n' "$T" > checks/evidence.sh
st_files; printf '.vid/\n' > .gitignore; g add -A && g commit -qm root
printf 'run: active\nsession: S1\nmode: tickets\nplan: required\nstage: 1\n\n## The plan\n\n```vid-plan\nstep A | name: sign in | modules: app/login | builds-on: - | rows: ROW-001 ROW-002\nshared: -\n```\n' > .vid/RUN-STATE.md
printf 'stage name=replan state=start session=S1 records=29 at=2026-10-24T10:00:00Z\n' > .vid/metrics-events
sh checks/plan.sh change create 'the plan' --trigger initial --expect 'A first' > "$T/out" 2>&1 || fail 'auto: the plan was not recorded'
sh checks/plan.sh start A > "$T/out" 2>&1 || fail 'auto: A was refused at its start'
grep -v '^ROW-002 ' INVENTORY.md > i && mv i INVENTORY.md; g commit -qam 'the owner strikes ROW-002'
sed 's/rows: ROW-001 ROW-002/rows: ROW-001/' .vid/RUN-STATE.md > "$T/rs" && cp "$T/rs" .vid/RUN-STATE.md
sh checks/plan.sh change rows 'ROW-002 struck by the owner' --trigger unknown --expect 'A builds' > "$T/out" 2>&1 || fail 'auto: the struck row could not leave its started step'
[ ! -e "$T/evidence-called" ] || fail 'auto: evidence.sh was called under mode: tickets'
exit 0
