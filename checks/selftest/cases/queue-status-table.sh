#!/bin/sh
# Purpose: selftest case — the status's table (v0.26.10.26.3, R1, R3), checks/queue.sh on TW's toy at stage 1, from records made by
# hand, each count worked out below. The stage line from STAGES.md; now, each open ticket's rows accepted; left, each row once in its
# first bucket, a journey by its transitions, a row's handed line before its decision, the deploy-owed and the later rows apart; tests,
# the environments and the newest close's red rows by chunk; the test state, a landed row's evidence read only from a ticket published
# after its landing, the handed fault-proven mark; the debt, owed by kind, a held row with its Q line, a regression carried; landings
# from the landed drafts' resets, transitions apart, an unlanded draft left out; cost, the closed step's lines and the median; the
# hardening and estimate lines; a step-start a start; under breadth first, a row an amendment moved out of a
# feature ticket into a hardening step, deferred. The tripwire (R3): sync prints `regression <close> <n>` once; the debt carries it until a later close
# of the step reads zero, a stage's until it passes, a step's until it closes. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "queue-status-table: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; QS=$CHECKS/queue.sh; D=.vid/decide; mkdir -p "$D/queue" .vid/round .vid/results "$D/close/S01/1" "$D/close/S02/1" "$D/drafts/1" "$D/drafts/2"
st() { VID_STATUS_KEEP=1 sh "$QS" status > "$T/out" 2>&1 || fail 'status failed'; }
is() { grep -qxF -- "$1" "$T/out" || fail "no line: $1 — got: $(grep -F -- "${1%%:*}:" "$T/out" | head -n 1)"; }
pt_rs 's/^stage:.*/stage: 1/'; if ! grep -q '^stage: 1$' .vid/RUN-STATE.md; then { sed -n 1p .vid/RUN-STATE.md; echo 'stage: 1'; sed 1d .vid/RUN-STATE.md; } > "$T/rs"; cat "$T/rs" > .vid/RUN-STATE.md; fi
TAB=$(printf '\t'); h1=aaaaaaaaaaaa; h2=bbbbbbbbbbbb; h3=cccccccccccc
cat > .vid/tw/log <<'L'
published 1 kind=skeleton step=S01 rows=ROW-003,ROW-004 at=2026-11-09T08:00:00Z
published 2 kind=step step=S02 rows=ROW-001,ROW-005,ROW-008,ROW-012 at=2026-11-09T09:00:00Z
published 3 kind=step step=S03 rows=ROW-006,ROW-007,ROW-014 at=2026-11-09T09:30:00Z
landed 1 ids=ROW-012 at=2026-11-09T10:00:00Z
published 4 kind=fix step=S02 rows=ROW-012 at=2026-11-09T10:30:00Z
L
cat >> .vid/tw/handed <<'L'
closed S01 | stand-in: close #9 at 123456789abc
row ROW-003 accepted fault-proven | stand-in: decision
row ROW-004 accepted | stand-in: decision
row ROW-001 accepted | stand-in: decision
row ROW-008 held | stand-in: decision
row ROW-019 known-limit | stand-in: decision
engines alpha beta | stand-in: results reader
L
# decisions: ROW-005's transitions (one failing: the journey fails), ROW-008 failing under its handed held, ROW-006 accepted,
# ROW-007 evidence missing, ROW-010 owed, ROW-001 failing under its handed accepted
printf 'ROW-005-T1\taccepted\taccepted\t10\t%s\tx\nROW-005-T2\tfailing\tfailing\t10\t%s\tx\nROW-008\tfailing\tfailing\t10\t%s\tx\nROW-006\taccepted\taccepted\t11\t%s\tx\nROW-007\tevidence missing\tevidence missing\t11\t%s\tx\nROW-010\towed\towed\t11\t%s\tx\nROW-001\tfailing\tfailing\t10\t%s\tx\n' $h1 $h1 $h1 $h2 $h2 $h2 $h1 > "$D/state"
printf 'issue\t3\tticket\t\nissue\t4\tticket,fix\t\nissue\t9\tclose\t\n' > .vid/round/read
printf 'stacks=2\nunverified-rows=120\n' > .vid/budget
# the closes: S01's, then S02's, red on ROW-008 in chunk p1c1 in two engines, with 2 regressions; S02 is not closed
printf 'ROW-003\tgreen\n' > "$D/close/S01/1/result"; printf 'p1c1|green|1||\n' > "$D/close/S01/1/chunks"
printf 'ROW-001\tgreen\nROW-008\tred\n' > "$D/close/S02/1/result"; printf 'p1c1|red|1| alpha:ROW-008 beta:ROW-008|\np2c1|green|1||\n' > "$D/close/S02/1/chunks"
echo 'regressions introduced 2 · defects still open 0 · fixed 0' > "$D/close/S02/1/numbers"
cat >> .vid/metrics-events <<'L'
close-asked step=S01 issue=9 commit=x chunks=1 ask=1 at=2026-11-09T08:50:00Z
close-closed step=S01 issue=9 commit=x at=2026-11-09T09:00:00Z
close-asked step=S02 issue=12 commit=y chunks=2 ask=1 at=2026-11-09T11:00:00Z
L
# evidence: ticket 2's (published before ROW-012 landed, so its ROW-012 is read from none of it) and ticket 4's; ticket 1's for the cost
printf 'ticket 2, pull request 10, head %s0000\nROW-001\tbehavior\tred\tpassed\tproven\t\nROW-005-T1\tjourney\tred\tpassed\tproven\t\nROW-005-T2\tjourney\tred\tpassed\tproven\t\nROW-005-T3\tjourney\tred\tpassed\tproven\t\nROW-012\tbehavior\tred\tpassed\tproven\t\nROW-008\tbehavior\tno-red\tfailed\tn/a\t\n' $h1 > .vid/results/pr-10-$h1.txt
printf 'ticket 4, pull request 13, head %s0000\nROW-012\tbehavior\tred\tmissing\tmissing\t\n' $h2 > .vid/results/pr-13-$h2.txt
printf 'ticket 1, pull request 20, head %s0000\nROW-003\tbehavior\tred\tpassed\tproven\t\n' $h3 > .vid/results/pr-20-$h3.txt
printf '2026-11-09T08:45:00Z\t20\t%s\tROW-003\taccepted\n2026-11-09T08:45:00Z\t20\t%s\tROW-004-T1\taccepted\n2026-11-09T08:45:00Z\t20\t%s\tROW-004-T2\taccepted\n' $h3 $h3 $h3 > "$D/log"
printf '2026-11-09T09:30:00Z\t10\t%s\tROW-001\taccepted\n' $h1 >> "$D/log"; printf '20 1 %s at=2026-11-09T08:45:00Z\n' $h3 > "$D/accepted-at"; printf '1\n2\n' > "$D/accepted-log"
printf 'held:ROW-008\tQ2\t2026-11-09T11:00:00Z\n' > "$D/queue/ids"
# landings: draft 1 landed (a row and a transition reset, a row added); draft 2 never landed
printf 'reset\tROW-012\nreset\tROW-005-T1\ttransition\nadded\tROW-021\n' > "$D/drafts/1/sets"; : > "$D/drafts/1/landed"; printf 'reset\tROW-001\n' > "$D/drafts/2/sets"
st
# the toy's 34 rows (ROW-001..020, RULE-001..005, DIF-001..002, HOS-001..005, SEAM-001..002; DIF-003 a record): accepted ROW-001
# (its handed line), ROW-003, ROW-004, ROW-006; ROW-019 a known limit. Left: failing ROW-005; held ROW-008; not yet decided ROW-007,
# ROW-012, ROW-014; deploy-owed (owed by kind: ROW-010 alone has the state owed) ROW-009..011, DIF-001, DIF-002, SEAM-001, SEAM-002 (7); later ROW-017, ROW-020; the other 15 in no ticket
is 'stage: 1 — The daily digest · stages closed 0'
is 'now: #3 S03 the footer, unsubscribe and the mail provider: 1 of 3 rows accepted · #4 S02 new jobs only, each listed once: 0 of 1 rows accepted'
is 'left: steps not started 2 · rows failing 1 · held 1 · not yet decided 3 · in no ticket 15 · apart: deploy-owed 7 · later stages 2'
is 'tests: environments declared 2 · engines alpha beta · the newest close: S02/1 p1c1 ROW-008'
# red at T2: ROW-001, ROW-005 (every transition), ROW-012 (ticket 4), ROW-003; T3: ROW-001, ROW-005, ROW-003; proven: those three, ROW-003 also handed
is 'test state: of 34 rows · red seen at T2 4 · T3 passed 3 · fault proven 3'
is 'debt: owed staging 1 · production 0 · rehearsal 0 · held 1 (ROW-008 Q2) · deferred 0 · regressions S02 close 1: 2'
is 'landings: 1 landed · rows reset 1 · transitions reset 1'
is 'cost: steps closed since the last update S01 · median published to accepted 0 h 45 m of 1 tickets · 3 with no accepted-at'
is '  S01 #1 skeleton · published to accepted 0 h 45 m · heads 1 · accepted at the first decision 2 of 2 · held 0 · accepted to closed 0 h 15 m'
is 'hardening: none, depth first'; is "estimate: none in ticket mode: DevAgent's pace is its own (V2 §3.7)"
grep -n '' "$T/out" | grep -q 'tickets: open' || fail 'the earlier lines are gone'
# since the last update: S01 closed before it, so no cost lines
sh "$QS" status > /dev/null 2>&1; st; is 'cost: steps closed since the last update none · median published to accepted 0 h 45 m of 1 tickets · 3 with no accepted-at'
! grep -q '^  S01 #1' "$T/out" || fail 'a step closed before the last update kept its cost lines'
# the tripwire: printed once by sync, carried by the debt
sh "$QS" sync > "$T/out" 2>&1 || fail 'sync failed'; grep -qx 'regression S02/1 2' "$T/out" || fail 'no regression line'
sh "$QS" sync > "$T/out" 2>&1; ! grep -q '^regression ' "$T/out" || fail 'the regression line printed twice'
mkdir -p "$D/close/S02/2"; echo 'regressions introduced 0 · defects still open 1 · fixed 0' > "$D/close/S02/2/numbers"; st
is 'debt: owed staging 1 · production 0 · rehearsal 0 · held 1 (ROW-008 Q2) · deferred 0 · regressions none'
sh "$QS" sync > "$T/out" 2>&1; ! grep -q '^regression ' "$T/out" || fail 'a close with none printed a regression line'
mkdir -p "$D/close/S03/1" "$D/stage/1/1"; echo 'regressions introduced 1 · defects still open 0 · fixed 0' > "$D/close/S03/1/numbers"; echo 'regressions introduced 3 · defects still open 0 · fixed 0' > "$D/stage/1/1/numbers"
sh "$QS" sync > "$T/out" 2>&1; grep -qx 'regression S03/1 1' "$T/out" && grep -qx 'regression stage-1/1 3' "$T/out" || fail 'the step and stage regressions were not printed'
st; is 'debt: owed staging 1 · production 0 · rehearsal 0 · held 1 (ROW-008 Q2) · deferred 0 · regressions S03 close 1: 1, stage-1 close 1: 3'
echo 'closed S03 | stand-in: close #14 at 0123' >> .vid/tw/handed; : > "$D/stage/1/1/passed"; st
is 'debt: owed staging 1 · production 0 · rehearsal 0 · held 1 (ROW-008 Q2) · deferred 0 · regressions none'; is 'stage: 1 — The daily digest · stages closed 0'
# TOY-1: a full run passed is no stage closed; the stage's close is
echo 'stage-closed 1 | stand-in: RM at 0123456789ab candidate 1' >> .vid/tw/handed; st; is 'stage: 1 — The daily digest · stages closed 1'
# a landing of a transition alone: ROW-005-T1's evidence in #2, published before it, is read no more (ROW-005 leaves red and T3)
echo 'landed 2 ids=ROW-005-T1 at=2026-11-09T11:30:00Z' >> .vid/tw/log; st; is 'test state: of 34 rows · red seen at T2 3 · T3 passed 2 · fault proven 2'
# a later head of #2 fails ROW-001's T3: its newest T3 counts, its red and proven stand
printf 'ticket 2, pull request 10, head dddddddddddd0000\nROW-001\tbehavior\tred\tfailed\tproven\t\n' > .vid/results/pr-10-dddddddddddd.txt; printf '2026-11-09T10:45:00Z\t10\tdddddddddddd\tROW-001\tfailing\n' >> "$D/log"
st; is 'test state: of 34 rows · red seen at T2 3 · T3 passed 1 · fault proven 2'
# a step started by its step-start, with no ticket yet, is started
echo 'step-start step=S04 plan=x base=y at=2026-11-09T12:00:00Z' >> .vid/metrics-events; st; grep -q '^left: steps not started 1 · ' "$T/out" || fail "a step-start is not a start: $(grep '^left:' "$T/out")"
# breadth first: S05 a hardening step holding ROW-014, moved out of #3 by its amendment and not accepted, deferred
{ grep -v '^strategy:' .vid/RUN-STATE.md; echo 'strategy: breadth-first'; } > "$T/rs"; cat "$T/rs" > .vid/RUN-STATE.md
pt_rs 's/^\(step S03 .*\)ROW-014 \(.*\)$/\1\2/'; pt_rs 's/^\(step S05 .*rows: ROW-017\) \(.*\)$/\1 ROW-014 \2 | kind: hardening/'
echo 'amended 3 kind=step step=S03 rows=ROW-006,ROW-007 at=2026-11-09T12:00:00Z' >> .vid/tw/log; printf 'ROW-014\tpassing\tpassing\t31\t%s\tx\n' $h2 >> "$D/state"; st   # a regression's pass resolves nothing
grep -q '^debt: .* · deferred 1 · ' "$T/out" || fail "the amended-out row is not deferred: $(grep '^debt:' "$T/out")"; is 'hardening: 2 rows in 1 steps not accepted'
exit 0
