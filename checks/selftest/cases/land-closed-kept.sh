#!/bin/sh
# Purpose: selftest case — a landing on a closed step keeps its close while its stage has a candidate (0.26.10.29.2, R9),
# checks/land.sh on the writer's toy and the fake gh. S01, stage 0's skeleton, is closed and stage 0 has its candidate:
# a landing that resets ROW-003 keeps S01's closed line and its close ask (no `reopened`, no withdrawal), drops the
# row's handed line, and S03, which builds on S01, is refused by rule B naming ROW-003; once ROW-003 is accepted again
# S03 is admitted. With no candidate for stage 0, a landing that resets ROW-004 reopens S01 as before: its closed line
# dropped and its newest close ask withdrawn, and once its new ticket merges its close is owed again. And
# a landing replacing a closed step's rows with a new stage-1 row, stage 1 with a candidate, keeps its close. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "land-closed-kept: $*" >&2; sed 's/^/    /' "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; tw_skel || fail "the skeleton round failed: $(cat "$T/werr" "$T/sk" 2>/dev/null | tail -n 3)"
LS=$CHECKS/land.sh; R=owner/code; printf 'none\n' > "$T/rv"
ld() { RC=0; if [ "$1" = draft ]; then shift; set -- draft --review "$T/rv" "$@"; fi; sh "$LS" "$@" > "$T/out" 2>&1 || RC=$?; }
sed 's/^open-tickets: 2$/open-tickets: 9/' .vid/tw/settings > "$T/st" && cp "$T/st" .vid/tw/settings
mkdir -p .vid/decide/close/S01/1; I1=$(gh issue create -R $R --title 'Close run: S01' --body b --label run | sed 's/.*\///')
printf 'issue\t%s\ncommit\t0123\nchunk\tp1c1\tchromium\tROW-003 ROW-004\n' "$I1" > .vid/decide/close/S01/1/ask
# stage 0 has its candidate: S01 keeps its close; its dependents wait for ROW-003
awk '/^ROW-003 \|/ { sub(/ shows the saved search/, " shows the saved search at once") } { print }' INVENTORY.md > "$T/i" && cp "$T/i" INVENTORY.md
ld draft --why 'ROW-003 says at once'; [ "$RC" = 0 ] || fail "the draft failed ($RC)"; ld 1 --words 'Yes, land it'; [ "$RC" = 0 ] || fail "draft 1 did not land ($RC)"
! grep -q '^reopened S01$' "$T/out" && grep -q '^closed S01 ' .vid/tw/handed || fail 'a landing on a step of a stage with a candidate dropped its closed line'
[ ! -f .vid/decide/close/S01/1/withdrawn ] || fail 'a landing on a step of a stage with a candidate withdrew its close ask'
! grep -q '^row ROW-003 ' .vid/tw/handed || fail "the reset row's handed line stayed"
RC=0; tw_start S03 || RC=$?; [ "$RC" = 1 ] && grep -q 'S03 builds on S01' "$T/start" && grep -q 'ROW-003' "$T/start" || { cp "$T/start" "$T/out"; fail "S03 was not held by rule B on S01's reset row ROW-003 ($RC)"; }
tw_hand 'row ROW-003 accepted'; tw_start S03 || { cp "$T/start" "$T/out"; fail "S03 was refused once S01's rows are accepted again"; }
# a landing that replaces a closed step's rows with a new stage-1 row, stage 1 with a candidate: the step's
# stage is read after the draft's rows land (close.sh's rule), so S02 keeps its close and its dependents wait for ROW-021
tw_closed S02; tw_hand 'candidate 1'
awk '/^ROW-020 \|/ { print; print "ROW-021 | behavior | REQ-001 | (process) | n/a | A job read twice in a day is listed once with its first read time. Fails if a second read moves its time. | REQ-001 | owed: spec-only — ticket"; next } { print }' INVENTORY.md > "$T/i" && cp "$T/i" INVENTORY.md
O2=$(sed -n 's/^step S02 .*rows: \([^|]*[^| ]\) *|.*/\1/p' .vid/RUN-STATE.md)
sed -n '/^```vid-plan/,/^```$/p' .vid/RUN-STATE.md | sed '1d;$d' | awk -v o="$O2" '/^step S02 / { sub(/rows: [^|]*\|/, "rows: ROW-021 |") } /^shared: / { print "needs ROW-021 | -" } { print } /^step S05 / { print "step S07 | name: the listings | modules: ingest digest | builds-on: S01 | rows: " o " | lane: devagent" }' > "$T/plan"
grep -q '^step S02 .*rows: ROW-021 |' "$T/plan" && grep -q '^step S07 .*rows: ROW-001 ' "$T/plan" || fail "the replacing plan was not drafted: $(grep 'step S0[27]' "$T/plan")"
ld draft --why 'S02 holds ROW-021, its rows move to S07' --plan "$T/plan"; [ "$RC" = 0 ] || fail "the replacing draft failed ($RC)"; n3=$(sed -n 's/^draft \([0-9]*\)$/\1/p' "$T/out"); ld "$n3" --words 'Yes, S07'; [ "$RC" = 0 ] || fail "draft $n3 did not land ($RC)"
! grep -q '^reopened S02$' "$T/out" && grep -q '^closed S02 ' .vid/tw/handed || fail 'a landing that replaced S02'"'"'s rows with a new stage-1 row dropped its closed line, stage 1 having a candidate'
RC=0; tw_start S04 || RC=$?; [ "$RC" = 1 ] && grep -q 'S04 builds on S02, which is closed, but its rows ROW-021 ' "$T/start" || { cp "$T/start" "$T/out"; fail "S04 was not held on S02's new row ROW-021 ($RC)"; }
# stage 0 with no candidate: S01 reopened, its ask withdrawn, as before
grep -v '^candidate 0 ' .vid/tw/handed > "$T/h" && cp "$T/h" .vid/tw/handed
awk '/^ROW-004 \|/ { sub(/saves a search, confirms it/, "saves a search, then confirms it") } { print }' INVENTORY.md > "$T/i" && cp "$T/i" INVENTORY.md
ld draft --why 'ROW-004 says then'; [ "$RC" = 0 ] || fail "the second draft failed ($RC)"; n2=$(sed -n 's/^draft \([0-9]*\)$/\1/p' "$T/out"); ld "$n2" --words 'Yes, land it too'; [ "$RC" = 0 ] || fail "draft $n2 did not land ($RC)"
grep -q '^reopened S01$' "$T/out" && ! grep -q '^closed S01 ' .vid/tw/handed || fail 'a landing on a step of a stage with no candidate did not reopen it'
grep -q '^withdrawn S01 1$' "$T/out" && [ -f .vid/decide/close/S01/1/withdrawn ] || fail 'the reopened step'"'"'s close ask was not withdrawn, so its close is not asked again'
# once its new ticket is out and every ticket of it merged, the reopened S01's close is owed again
sh "$CHECKS/github.sh" spec-export > /dev/null 2>&1; sh "$CHECKS/writer.sh" due > "$T/out" 2>&1; grep -qx 'new step S01' "$T/out" || fail 'the reopened step is owed no new ticket'
tw_post step S01 || { cat "$T/werr" "$T/post" > "$T/out" 2>/dev/null; fail "the reopened step's ticket was not posted"; }
for n in $(awk '$1 == "published" && / step=S01( |$)/ { print $2 }' .vid/tw/log); do printf '%s\t%s\tabc\tabc\n' $((100 + n)) "$n" >> .vid/decide/merges; echo $((100 + n)) >> .vid/decide/merged-prs; done
sh "$CHECKS/close.sh" owed > "$T/out" 2>&1; grep -qx 'close S01' "$T/out" || fail 'the reopened step'"'"'s close is not asked again once its tickets merged'
exit 0
