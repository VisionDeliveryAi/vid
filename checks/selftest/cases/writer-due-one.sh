#!/bin/sh
# Purpose: selftest case — one due rule set (GM-4 F7, phase 3's half): writer.sh keeps no GitHub-manual-only subcommand, and
# `due --why` prints what `mowed`, `followups` and `qat` gave. In both modes `writer.sh mowed <n>`, `followups` and `qat <n>` are
# unknown subcommands (exit 2), and `due` takes `--why` alone (another argument is a usage error, exit 2). On GitHub manual's
# switch toy (fixtures/manual.sh): #M1 (S01, the skeleton, ROW-003 and ROW-004) and #M2 (S02) taken over by the switch, #M2
# closed, then ROW-003 and ROW-013 (S02's) reworded and committed. `due --why`, read at HEAD with #M2 read as closed, prints
# due's own lines, then GM M5's: `why <M1> reset|reached ROW-003` and `why <M1> writing -` for the open #M1 (what mowed gave),
# `followup S02 ROW-013` (what followups gave), and nothing for ROW-004 or of #M2's. #M5 (S05, ROW-017), open and taken over too,
# its quoted text the same at its own commit and at HEAD, gets no `why` line and no `amend` from due or due --why. On the writer's toy (fixtures/tw-toy.sh,
# GitHub auto) after its skeleton round, `due --why` prints exactly what `due` prints. And the writer runs itself for no
# writing (no `writer.sh" qat` left in it). Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); T0=$T; trap 'rm -rf "$T0" "$T"' EXIT
fail() { echo "writer-due-one: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
W=$CHECKS/writer.sh
! grep -q 'writer\.sh" qat' "$W" || fail 'the writer still runs itself for a writing (writer.sh qat)'
# gone: each folded subcommand is unknown, in the mode it is called in
gone() { for c in 'mowed 1' followups 'qat 1'; do RC=0; sh "$W" $c > "$T/out" 2>&1 || RC=$?
    [ "$RC" = 2 ] && grep -q 'unknown subcommand' "$T/out" || fail "$1: writer.sh $c is still a subcommand (exit $RC)"; done
  RC=0; sh "$W" due --all > "$T/out" 2>&1 || RC=$?; [ "$RC" = 2 ] || fail "$1: due took an argument it does not know (exit $RC)"; }
# GitHub manual
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
mn_project "$T/p"
R2=$(sed -n 's/^step S02 .*| rows: \([^|]*[^| ]\) *|.*/\1/p' "$T/plan.blk"); [ -n "$R2" ] || fail "S02's rows could not be read from the switch toy's plan"
M1=$(gh_issue 'Skeleton'); mn_ticket "$M1" S01 skeleton ROW-003 ROW-004 > "$T/t1"; gh_writing "$M1" "$T/t1" body 2
M2=$(gh_issue 'Step S02'); mn_ticket "$M2" S02 step $R2 > "$T/t2"; gh_writing "$M2" "$T/t2" comments 2
M5=$(gh_issue 'Step S05'); mn_ticket "$M5" S05 step ROW-017 > "$T/t5"; gh_writing "$M5" "$T/t5" body 2
printf '%s S01\n%s S02\n%s S05\n' "$M1" "$M2" "$M5" > "$T/register"; gh_wclear
mn_switch --applied "$AP" --words 'yes, ratify the taken-over plan'; cp "$T/mo" "$T/out"; [ "$MN_RC" = 0 ] || fail "the switch exited $MN_RC"
echo CLOSED > "$FAKEGH/issues/$M2/state"
printf 'engines alpha beta | stand-in: results reader\n' >> .vid/tw/handed   # the skeleton's report's engines, which a step ticket's writing names
sed -e 's/shows the saved search, its address and/shows the saved search, its own address and/' -e 's/Reading the same feed twice leaves/Reading one feed twice leaves/' INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md
git commit -qam 'ROW-003 and ROW-013 reworded'
sh "$CHECKS/github.sh" spec-export > "$T/out" 2>&1 || fail 'the spec export failed on the switched project'   # a writing quotes the newest export
gone 'GitHub manual'
VID_WRITER_CLOSED=$M2 VID_WRITER_AT=$(git rev-parse HEAD) sh "$W" due --why > "$T/out" 2>&1 || fail 'writer.sh due --why failed on the switched project'
grep -Eqx "why $M1 (reset|reached) ROW-003" "$T/out" || fail "the open #$M1 is not owed for ROW-003, reworded since its own commit"
grep -qx "why $M1 writing -" "$T/out" || fail "the open #$M1's writing is not named as changed since its own commit"
grep -qx 'followup S02 ROW-013' "$T/out" || fail "the closed #$M2, taken over by the switch, is owed no follow-up of S02 holding ROW-013"
! grep -q "^why $M1 .* ROW-004\$" "$T/out" || fail 'ROW-004, unchanged, is named owed'
! grep -q "^why $M2 " "$T/out" || fail "the closed #$M2 is named owed as an open ticket"
[ "$(grep -c '^followup ' "$T/out")" = 1 ] || fail 'a follow-up beyond S02 is owed'
# the open #M5, whose quoted text is the same at its own commit and at HEAD, is owed nothing: no why line, no amendment
! grep -q "^why $M5 " "$T/out" || fail "the open #$M5, unchanged since its own commit, is named owed: $(grep "^why $M5 " "$T/out" | paste -sd ';' -)"
! grep -qx "amend $M5" "$T/out" || fail "the open #$M5, unchanged since its own commit, is owed an amendment by due --why"
# what due owes stands first, as due alone gives it
VID_WRITER_CLOSED=$M2 VID_WRITER_AT=$(git rev-parse HEAD) sh "$W" due > "$T/d0" 2>&1 || { cp "$T/d0" "$T/out"; fail 'writer.sh due failed on the switched project'; }
! grep -qx "amend $M5" "$T/d0" || { cp "$T/d0" "$T/out"; fail "the open #$M5, unchanged since its own commit, is owed an amendment by due"; }
grep -v '^why \|^followup ' "$T/out" > "$T/d1" || :; cmp -s "$T/d0" "$T/d1" || { diff "$T/d0" "$T/d1" > "$T/out" || :; fail "due --why's own lines are not due's"; }
# GitHub auto, as today
T=$(mktemp -d); . "$CHECKS/selftest/fixtures/tw-toy.sh"; tw_toy "$T/toy"
tw_skel || fail "the skeleton round failed: $(cat "$T/werr" "$T/sk" 2>/dev/null | tail -n 3)"
gone 'GitHub auto'
sh "$W" due > "$T/d0" 2>&1 || { cp "$T/d0" "$T/out"; fail 'writer.sh due failed in GitHub auto'; }
sh "$W" due --why > "$T/out" 2>&1 || fail 'writer.sh due --why failed in GitHub auto'
cmp -s "$T/d0" "$T/out" || { diff "$T/d0" "$T/out" > "$T/x" || :; cp "$T/x" "$T/out"; fail 'in GitHub auto, due --why prints other than due'; }
exit 0
