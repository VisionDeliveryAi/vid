#!/bin/sh
# Purpose: selftest case — breadth first in ticket mode (v0.26.10.26.3, R5), checks/plan.sh on TW's toy. Under depth first a plan
# listing a hardening step (S06) before a feature step (S05) is recorded, and `change edge` moves a weak-test row: untouched. The
# owner's breadth first is refused on that plan (an unstarted hardening step before a feature step), and `check` and `change` refuse
# it too; reordered, it is set. `change edge` is refused for a row whose newest decision fails it on a weak test, and for one held on
# a product failure the dependency safeguard reads the breach from that decision, though the row has no handed line: refused until
# --not-needed-by names S04 and S05, then recorded. Rule A in ticket mode leaves out the row parked in the unstarted S06: S03 is
# refused at unverified-rows=24 under depth first (25 open rows), admitted under breadth first (24). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "plan-breadth-tickets: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
P=$CHECKS/plan.sh; D=.vid/decide; TAB=$(printf '\t')
pc() { sh "$P" change "$1" "$2" --trigger test-evidence --evidence step:S02 --expect 'the plan holds' ${3:+--not-needed-by "$3" "$4"} > "$T/out" 2>&1; }
tw_toy "$T/a"; mkdir -p checks "$D"; cp "$CHECKS/stages.sh" "$CHECKS/prd.sh" "$CHECKS/inventory.sh" checks/; tw_hand 'candidate 0'; tw_hand 'staged 0'
sed 's/^open-tickets: 2/open-tickets: 9/' .vid/tw/settings > "$T/s" && cat "$T/s" > .vid/tw/settings
tw_start S01 || fail "S01 was refused: $(cat "$T/start")"; tw_closed S01; tw_start S02 || fail "S02 was refused: $(cat "$T/start")"
# depth first: a hardening step before a feature step is recorded
pt_rs 's/^\(step S04 .*\)ROW-018 \(.*\)$/\1\2/'
pt_rs 's/^\(step S05 .*\)$/step S06 | name: the edge cases | modules: digest | builds-on: - | rows: ROW-018 | lane: devagent | kind: hardening\n\1/'
pc add 'S06, hardening' || fail "depth first refused a hardening step before a feature step: $(cat "$T/out")"
# the owner's breadth first refused on it; check refuses it too, once set
if sh "$P" strategy breadth-first --by owner --words 'core first, then harden' > "$T/out" 2>&1; then fail 'breadth first was set over a hardening step before a feature step'; fi
grep -q 'every unstarted hardening step comes after the feature steps' "$T/out" && grep -q 'feature step S05 is listed after the unstarted hardening step S06' "$T/out" || fail 'the refusal does not name the order'
grep -q '^strategy:' .vid/RUN-STATE.md && fail 'the refusal set the strategy'
awk '/^step S06 /{ h = $0; next } { print } /^step S05 /{ print h }' .vid/RUN-STATE.md > "$T/rs" && cat "$T/rs" > .vid/RUN-STATE.md
pc reorder 'S06 after the features' || fail "the reorder was refused: $(cat "$T/out")"
sh "$P" strategy breadth-first --by owner --words 'core first, then harden' > "$T/out" 2>&1 || fail "breadth first was refused on a drained plan: $(cat "$T/out")"
sh "$P" check > "$T/out" 2>&1 || fail "check refused the drained plan: $(cat "$T/out")"
cp .vid/RUN-STATE.md "$T/drained"; awk 'NR == FNR { if (/^step S06 /) h = $0; next } /^step S06 / { next } /^step S05 / { print h } { print }' "$T/drained" "$T/drained" > .vid/RUN-STATE.md
if sh "$P" check > "$T/out" 2>&1; then fail 'check passed a hardening step before a feature step under breadth first'; fi
if pc reorder 'S06 first'; then fail 'a change put a hardening step before a feature step under breadth first'; fi; cat "$T/drained" > .vid/RUN-STATE.md
# the newest decisions: ROW-015 failing on a weak test (an earlier product failure in its words); ROW-016 held on a product failure, with no handed line
printf 'ROW-015\tfailing\tfailing\t30\taaaaaaaaaaaa\tx\nROW-016\theld\tfailing\t30\taaaaaaaaaaaa\tx\n' > "$D/state"
printf 'ROW-015\tROW-015\tfailing\tfailing\tnot-proven\tfailing, a weak test — its fault not proven, pr-30-aaaaaaaaaaaa — earlier: a product failure — its test failed, pr-30-bbbbbbbbbbbb, answered by cccccccccccc\t0\tpassed\tw\t0\t\nROW-016\tROW-016\theld\tfailing\tproven\theld — failing, a product failure — its test failed, pr-30-aaaaaaaaaaaa\t0\tfailed\tp\t0\t\n' > "$D/pr-30-aaaaaaaaaaaa.rows"
mv_row() { pt_rs "s/^\(step S02 .*\)$1 \(.*\)$/\1\2/"; pt_rs "s/^\(step S06 .*rows: ROW-018\)/\1 $1/"; }
mv_row ROW-015; if pc edge 'defer ROW-015'; then fail 'a weak-test row was moved to hardening'; fi
grep -q 'a row failing or held on a weak test is never moved to hardening: ROW-015' "$T/out" || fail 'the weak-test refusal does not name the row'
cat "$T/drained" > .vid/RUN-STATE.md; mv_row ROW-016
if pc edge 'defer ROW-016'; then fail 'the safeguard missed the held product failure'; fi
grep -q 'ROW-016, needed by S04 (not done)' "$T/out" && grep -q 'ROW-016, needed by S05 (not done)' "$T/out" || fail 'the safeguard does not name the dependents'
pc edge 'defer ROW-016' S04,S05 'they read no partner feed' || fail "the deferral was refused: $(cat "$T/out")"
# rule A: the started S02's 11 rows, less the parked ROW-016, and S03's 12 new rows not yet owed (0.26.10.29.2, R9: S01's 2 rows
# are accepted at its close, tw_closed, as its dependents need)
printf 'unverified-rows=22\n' > .vid/budget
sh "$P" strategy depth-first --by owner --words 'depth again' > /dev/null 2>&1 || fail 'the switch back was refused'
if tw_start S03; then fail 'S03 was admitted under depth first with the parked row counted'; fi; grep -q 'rule A (tickets): 23 open rows' "$T/start" || fail "rule A under depth first: $(cat "$T/start")"
sh "$P" strategy breadth-first --by owner --words 'breadth again' > /dev/null 2>&1 || fail 'breadth first was refused again'
tw_start S03 || fail "S03 was refused under breadth first, the parked row counted: $(cat "$T/start")"
# depth first untouched: a weak-test row moves by an edge change
sh "$P" strategy depth-first --by owner --words 'depth, last' > /dev/null 2>&1; mv_row ROW-015; pc edge 'ROW-015 under depth first' || fail "depth first refused an edge change: $(cat "$T/out")"
exit 0
