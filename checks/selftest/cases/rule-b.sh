#!/bin/sh
# Purpose: selftest case — rule B: build only on passing steps (v0.9.6 spec
# 3.4, R4; §7 case 25). S2 builds on S1, which has one red row: a builder
# brief for S2 is refused naming that row, and so is `plan.sh start S2`;
# after a recorded split — the red row into its own step S1b that S2 does
# not build on — both admit S2. 25b (the tree a brief starts from): a brief
# for S2 is refused when S1 passes at HEAD but an S1 path has an
# uncommitted edit. v0.9.6.1 (spec 3.4, R4) changes 0.9.6's last verdict:
# S1 red at the brief's quoted-at commit, then a scoped snapshot carrying
# an uncommitted fix passing it on the same commit — the newer result
# stands (the snapshot's diff touches no test of S1), so S2 is admitted,
# where 0.9.6 refused it. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "rule-b: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 3; rows s2 4 5; commit_all rows
SH="shared: $PLANS_SHARED"
S2='step S2 | name: second | modules: app/s2 | builds-on: S1 | rows: ROW-004 ROW-005'
plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001..ROW-003' "$S2" "$SH"
sh checks/plan.sh change create 'two steps' --trigger initial --expect 'the steps build in order' > /dev/null
rcpt r1 HEAD inline ROW-001=passed ROW-002=failed ROW-003=passed
brief .vid/briefs/1/builder-1.md builder S2 ROW-004 ROW-005
if sh checks/brief.sh .vid/briefs/1/builder-1.md > "$T/out" 2>&1; then fail 'a brief for S2 was admitted over a red S1'; fi
grep -q 'S2 builds on S1, which is not passing: ROW-002 red' "$T/out" || fail 'the refusal does not name the red row'
if sh checks/plan.sh start S2 > "$T/out" 2>&1; then fail 'plan.sh start S2 was admitted over a red S1'; fi
grep -q 'ROW-002 red' "$T/out" || fail 'the start refusal does not name the red row'
plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-003' 'step S1b | name: the red row | modules: app/s1 | builds-on: - | rows: ROW-002' "$S2" "$SH"
sh checks/plan.sh change split 'ROW-002 is red; S2 does not need it' --trigger unknown --expect 'the steps build in order' > /dev/null || fail 'the split was refused'
sh checks/brief.sh .vid/briefs/1/builder-1.md > "$T/out" 2>&1 || fail 'S2 was refused after the split'
grep -q 'admitted S2' "$T/out" || fail 'the brief did not admit S2'
# 25b — a fresh run: S1 passes at HEAD, S1 edited but uncommitted
plan_repo "$T/b"; rows s1 1 2; rows s2 3 4; commit_all rows
plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002' 'step S2 | name: second | modules: app/s2 | builds-on: S1 | rows: ROW-003 ROW-004' "$SH"
sh checks/plan.sh change create 'two steps' --trigger initial --expect 'the steps build in order' > /dev/null
rcpt r1 HEAD inline ROW-001=passed ROW-002=passed
brief .vid/briefs/1/builder-1.md builder S2 ROW-003 ROW-004
printf 'an unseen edit\n' >> app/s1/main.py
if sh checks/brief.sh .vid/briefs/1/builder-1.md > "$T/out" 2>&1; then fail 'a brief was admitted with S1 edited and uncommitted'; fi
grep -q 'uncommitted changes on its currency paths' "$T/out" || fail 'the refusal does not name the uncommitted edit'
g checkout -q -- app/s1/main.py
# red at quoted-at; a scoped snapshot carrying an uncommitted fix passed it
rcpt r2 HEAD inline ROW-001=passed ROW-002=failed
printf 'the fix\n' >> app/s1/main.py
SNAP=$(GIT_INDEX_FILE="$T/idx" sh -c 'git read-tree HEAD && git add -A -- app && git write-tree')
g checkout -q -- app/s1/main.py
sh checks/brief.sh .vid/briefs/1/builder-1.md > "$T/out" 2>&1 && fail 'S2 was admitted over S1 red at quoted-at'
grep -q 'ROW-002 red' "$T/out" || fail 'the refusal does not name the row red at quoted-at'
rcpt r3 "$SNAP" inline ROW-001=passed ROW-002=passed
sh checks/brief.sh .vid/briefs/1/builder-1.md > "$T/out" 2>&1 || fail 'the newer result (the snapshot'"'"'s pass) did not admit S2'
grep -q 'admitted S2' "$T/out" || fail 'the brief did not admit S2'
exit 0
