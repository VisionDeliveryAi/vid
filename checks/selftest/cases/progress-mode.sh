#!/bin/sh
# Purpose: selftest case — the progress of a take-stock (FB-3 D2). On GitHub manual's toy (fixtures/manual.sh), its checks/ a copy whose
# face.sh records its arguments, /vid mode manual names its eight parts once, runs each once, in order, reads `ticket 1 of 3` to
# `3 of 3` with how many are new, and clears them at its end (exit 0). Each stop says what it needs: the answers to the setup (exit 3,
# before any part), the yes to update the checks (4), what ViD could not find (5), the words for a test to place, the yes to the
# plan, the part it stopped at left stopped; a run after it begins afresh. A project not in ticket mode gets no .vid/face; a face.sh
# that fails fails no take-stock. Env: CHECKS.
set -eu
unset VID_CALLER CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
HOME=$T/home; export HOME; mkdir -p "$HOME"   # the plan page goes under HOME
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "progress-mode: $*" >&2; cat "$T/mo" >&2 2>/dev/null; echo '-- the calls of face.sh:' >&2; cat "$T/calls" >&2 2>/dev/null; exit 1; }
mn_project "$T/p"
mkdir checks "$T/nohooks"; ( cd "$CHECKS" && tar cf - --exclude ./selftest . ) | ( cd checks && tar xf - ); mv checks/face.sh checks/face-real.sh
printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "%s/calls"\nexec sh "${0%%/*}/face-real.sh" "$@"\n' "$T" > checks/face.sh
git config core.hooksPath "$T/nohooks"; git add -A; git commit -qm 'checks'; CHECKS=$PWD/checks
N1=$(gh_issue 'Skeleton'); mn_ticket "$N1" S01 skeleton ROW-003 ROW-004 > "$T/t1"; gh_writing "$N1" "$T/t1" body 2
N2=$(gh_issue 'Step S02'); mn_ticket "$N2" S02 step ROW-001 > "$T/t2"; gh_writing "$N2" "$T/t2" comments 2
N3=$(gh_issue 'Step S04'); mn_ticket "$N3" S04 step ROW-009 > "$T/t3"; gh_writing "$N3" "$T/t3" body 2
printf '%s S01\n%s S02\n%s S04\n' "$N1" "$N2" "$N3" > "$T/register"
P='Connecting and checking the project
Finding the published tickets
Reading each ticket
Comparing their tests with the spec
Writing the plan down
Checking the plan
Recording your approval
Saving the records'
sw() { : > "$T/calls"; mn_switch "$@"; grep '^wait ' "$T/calls" | sed 's/^wait //' > "$T/w" || :; }
last() { [ "$(tail -n 1 "$T/w")" = "$1" ] || fail "the last word is not: $1"; }
st() { sh checks/face-real.sh standing 2> /dev/null | tr -d '\n' | sed 's/.*"wait":\({.*}\),"backlog".*/\1/'; }
at() { st | grep -qF "{\"name\":\"$1\",\"state\":\"stopped\"}" || fail "the part it stopped at is not $1: $(st)"; }
# the setup not answered: before any part
cp .vid/plan/setup "$T/su"; grep -v 'key=issue-form ' "$T/su" > .vid/plan/setup; sw --applied "$AP"; [ "$MN_RC" = 3 ] || fail "with a setup key to ask the call exited $MN_RC"
last 'stop your answers to the setup'; ! grep -q '^parts' "$T/w" || fail 'parts named before the setup is answered'
cp "$T/su" .vid/plan/setup
# the owner's no to the refresh
mkdir -p .vid/next; printf 'not now at=x\n' > .vid/next/refresh-no; sw --applied "$AP"; [ "$MN_RC" = 4 ] || fail "under the owner's no the call exited $MN_RC"
last "stop your yes to update the project's checks"; at 'Connecting and checking the project'; rm .vid/next/refresh-no
# what ViD could not find
: > "$T/calls"; MN_RC=0; sh checks/mode.sh manual --register "$T/register" --review "$T/review" > "$T/mo" 2>&1 || MN_RC=$?; grep '^wait ' "$T/calls" | sed 's/^wait //' > "$T/w"
[ "$MN_RC" = 5 ] || fail "with inputs not found the call exited $MN_RC"; last 'stop what ViD could not find: the plan, the commit the tickets were written from'; at 'Finding the published tickets'
# a test with no step, then the yes to the plan
cp "$T/plan.blk" "$T/b0"; sed 's/^\(step S05 .*rows: \)ROW-017/\1/; /^needs ROW-017 /d' "$T/b0" | grep -v '^step S05 ' > "$T/plan.blk"
sw --applied "$AP"; [ "$MN_RC" = 1 ] || fail "with a test in no step the call exited $MN_RC"; last 'stop your words for 1 test to place'; at 'Checking the plan'
sw --applied "$AP" --to-place 'yes, later'; [ "$MN_RC" = 1 ] || fail "with no yes to the plan the call exited $MN_RC"; last 'stop your yes to the plan'; at 'Recording your approval'
# the whole take-stock, the tickets taken over by the calls before forgotten, so each is new
grep -v '^published ' .vid/tw/log > "$T/lg"; cat "$T/lg" > .vid/tw/log
sw --applied "$AP" --to-place 'yes, later' --words 'yes, ratify'; [ "$MN_RC" = 0 ] || fail "the switch exited $MN_RC"
[ "$(grep -c '^parts ' "$T/w")" = 1 ] && grep -qxF "parts $(printf '%s\n' "$P" | paste -sd ' ' -)" "$T/w" || fail 'the parts are not named once'
[ "$(sed -n 's/^on //p' "$T/w" | grep -vx -e 'Reading GitHub' -e 'Working out what changed')" = "$P" ] || fail 'the parts do not run each once, in order'
[ "$(grep '^now ticket .* so far$' "$T/w")" = 'now ticket 1 of 3, 0 new so far
now ticket 2 of 3, 1 new so far
now ticket 3 of 3, 2 new so far' ] || fail 'the tickets are not counted, one by one'
last 'done'; [ ! -e .vid/face/wait ] || fail 'an ended take-stock left its parts'
# the register not given: the tickets read to find it are counted
for n in "$N1" "$N2" "$N3"; do gh issue edit "$n" -R owner/code --add-label vid:ticket > /dev/null; done
: > "$T/calls"; sh checks/mode.sh manual --plan "$T/plan.blk" --plan-md "$T/plan.md" --review "$T/review" --words 'yes, again' --to-place 'yes, later' > "$T/mo" 2>&1 || fail "a re-take with no register was refused"
grep -qx 'wait now ticket 3 of 3' "$T/calls" || fail 'the tickets read to find the register are not counted'
# a face.sh that fails
printf '#!/bin/sh\nexit 1\n' > checks/face.sh; git commit -qam 'a failing face'; sw --words 'yes, once more' --to-place 'yes, later'; [ "$MN_RC" = 0 ] || fail "with a failing face.sh the re-take exited $MN_RC"
# not in ticket mode: no panel folder
mkdir "$T/dev"x; cd "$T/dev"x; git init -q; mkdir .vid; printf 'mode: develop\n' > .vid/RUN-STATE.md; MN_RC=0; sh "$T/p/checks/../checks/mode.sh" manual > "$T/mo" 2>&1 || MN_RC=$?
[ "$MN_RC" = 1 ] && [ ! -e .vid/face ] || fail 'a project not in ticket mode got a panel folder'
exit 0
