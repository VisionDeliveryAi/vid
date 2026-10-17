#!/bin/sh
# Purpose: selftest case — started work is never re-judged, and its charge
# follows the row (v0.9.6 spec 3.4–3.5, R4–R5; §7 case 27), under a ceiling
# of 60. A fixer brief for the started 60-row S1 is admitted with its
# prerequisite S0 red and the unverified count over the budget. A
# `plan-change` adding 90 rows to S1 is refused. S1 moved whole to S9 and
# dropped: the change is recorded; a new 60-row S2 is refused (S1's rows
# still count, once); S9 is admitted without either rule, its rows red, then
# partly passing, its prerequisite stale. A change dropping S9 — leaving
# started rows in no step — is refused. 27c: with RUN-STATE rewritten, the
# rows every started step held and the charged set (plan.sh charged, from
# .vid/plans/ and the step-start events) are the same as before; and the
# progress update's Left names the rows in no step "not in the plan". Env:
# CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "started-and-moved: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s0 1 2; rows s1 3 62; rows s2 63 122; rows s3 123 212; commit_all rows
SH="shared: $PLANS_SHARED"
S0='step S0 | name: base | modules: app/s0 | builds-on: - | rows: ROW-001 ROW-002'
S2='step S2 | name: second | modules: app/s2 | builds-on: - | rows: ROW-063..ROW-122'
plan "$S0" 'step S1 | name: first | modules: app/s1 | builds-on: S0 | rows: ROW-003..ROW-062' "$S2" "$SH"
sh checks/plan.sh change create 'the plan' --trigger initial --expect 'the steps build in order' > /dev/null
rcpt r1 HEAD inline ROW-001=passed ROW-002=passed
sh checks/plan.sh start S1 > "$T/out" 2>&1 || fail 'S1 was refused over a passing S0'
rcpt r2 HEAD inline ROW-001=passed ROW-002=failed
printf 'unverified-rows=50\n' > .vid/budget
brief .vid/briefs/1/fixer-1.md fixer S1 ROW-003
sh checks/brief.sh .vid/briefs/1/fixer-1.md > "$T/out" 2>&1 || fail 'a fixer brief for a started step was refused'
grep -q 'S1 already started' "$T/out" || fail 'the fixer brief was not admitted as a started step'
printf 'unverified-rows=60\n' > .vid/budget
plan "$S0" 'step S1 | name: first | modules: app/s1 | builds-on: S0 | rows: ROW-003..ROW-062 ROW-123..ROW-212' "$S2" "$SH"
if sh checks/plan.sh change rows 'ninety more rows for S1' --trigger unknown --expect 'the steps build in order' > "$T/out" 2>&1; then fail 'adding 90 rows to a started step was accepted'; fi
grep -q 'admitted like a new step' "$T/out" || fail 'the refusal does not say why'
# moved whole to S9, S1 dropped
plan "$S0" 'step S9 | name: first, moved | modules: app/s1 | builds-on: S0 | rows: ROW-003..ROW-062' "$S2" "$SH"
sh checks/plan.sh change split 'S1 becomes S9' --trigger unknown --expect 'the steps build in order' > "$T/out" 2>&1 || fail 'the move was refused'
sh checks/plan.sh charged | cut -f1 | sort > "$T/charged.before"
[ "$(grep -c . "$T/charged.before")" -eq 60 ] || fail 'the charged set is not the 60 rows, once'
if sh checks/plan.sh start S2 > "$T/out" 2>&1; then fail 'a new 60-row step was admitted beside 60 moved unverified rows'; fi
grep -q 'rule A: 120 unverified rows' "$T/out" || fail 'the moved rows were not counted once'
sh checks/plan.sh start S9 > "$T/out" 2>&1 || fail 'S9 (red rows, a red prerequisite) was refused'
grep -q 'neither rule applies' "$T/out" || fail 'S9 was judged by a rule'
# partly passing, prerequisite stale: still admitted (already started now, and would be regardless)
rcpt r3 HEAD inline ROW-003=passed ROW-004=passed
mkdir -p app/s0; printf 'x\n' >> app/s0/main.py; commit_all 'S0 moves'
brief .vid/briefs/1/builder-9.md builder S9 ROW-005
sh checks/brief.sh .vid/briefs/1/builder-9.md > "$T/out" 2>&1 || fail 'S9 was refused with its rows partly passing and S0 stale'
# a drop leaving started rows in no step
plan "$S0" "$S2" "$SH"
if sh checks/plan.sh change drop 'S9 dropped' --trigger unknown --expect 'the steps build in order' > "$T/out" 2>&1; then fail 'a drop leaving started rows in no step was accepted'; fi
grep -q 'leaves rows of started steps in no step' "$T/out" || fail 'the refusal does not name the orphaned rows'
# 27c: RUN-STATE rewritten; the charged set rebuilt from the records alone
plan "$S0" 'step S9 | name: first, moved | modules: app/s1 | builds-on: S0 | rows: ROW-003..ROW-062' "$S2" "$SH"
{ printf 'run: active\nsession: S2\nplan: required\nquestions: - · next Q1\n\n'; sed -n '/^## The plan/,$p' .vid/RUN-STATE.md; } > x && mv x .vid/RUN-STATE.md
sh checks/plan.sh charged | cut -f1 | sort > "$T/charged.after"
cmp -s "$T/charged.before" "$T/charged.after" || fail 'the charged set differs after RUN-STATE was rewritten'
sh checks/plan.sh charged | awk -F'\t' '$1 == "ROW-003" { print $2 }' | grep -qx S1 || fail 'the rows S1 held when it started are not rebuilt under S1'
# rows in no step are "not in the plan" in the progress update's Left (v0.9.6 3.15)
sh checks/progress.sh > "$T/out" 2>&1 || fail 'the progress update failed'
grep '^| Left |' "$T/out" | grep -q '90 not in the plan' || fail 'Left does not show the 90 rows in no step as not in the plan'
exit 0
