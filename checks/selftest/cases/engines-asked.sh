#!/bin/sh
# Purpose: selftest case — what an analysis or an apply needs is asked before it starts (FB-3 E2), on the toy switched to GitHub manual with
# its tickets (no engines line on record) and the fake gh. The switch and a take-stock in manual, and round.sh accept --outside of a ticket,
# of rows and of several tickets, in both modes, each print `engines not named — /vid:vid-accept-step engines "<primary> <other>…" "<words>"`
# once; a refused record does not. `replan.sh scope` says them missing in its list (FB-4 A3: `needs engines missing apply owner` and the same words), and the call's
# question of an own proposal due says it; `replan.sh own` and `analyse` print nothing of it, so a making that is refused names its real
# reason. The command it names, the vid-connect start, `results.sh declare --engines … --words …` and the end, records them in both modes;
# then none of these lines is printed. In GitHub auto, where a close with no engines ends `round.sh next` in an error, the same command
# mends it; its take-stock prints nothing. The skills say it. Env: CHECKS.
# selftest-limit: 1800 s
set -eu
unset VID_CALLER CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "engines-asked: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
L='engines not named — /vid:vid-accept-step engines "<primary> <other>…" "<words>"'
asks() { [ "$(grep -cxF "$L" "$T/out")" = 1 ] || fail "$1 does not say, once, that the engines are not named"; }; none() { ! grep -qi 'engines not named\|needs.engines.missing' "$T/out" || fail "$1 says the engines are not named"; }
st() { HOME=$T/home MN_RC=0; sh "$CHECKS/mode.sh" "$@" --review "$T/review" > "$T/out" 2>&1 || MN_RC=$?; }
rd() { RC=0; sh "$CHECKS/round.sh" "$@" > "$T/out" 2>&1 || RC=$?; }
lock() { CLAUDE_CODE_SESSION_ID=engines; export CLAUDE_CODE_SESSION_ID; sh "$CHECKS/github.sh" lock-take engines > "$T/out" 2>&1 || fail 'no lock'; }; free() { sh "$CHECKS/github.sh" lock-free > "$T/out" 2>&1 || fail 'the lock could not be freed'; }
# the command the line names: the vid-connect start, the one writer, the end
named() { sh "$CHECKS/connect.sh" start > "$T/out" 2>&1 || fail 'the connect did not start'; sh "$CHECKS/results.sh" declare --engines "$1" --words "$2" > "$T/o2" 2>&1 || { cp "$T/o2" "$T/out"; fail 'declare refused'; }; sh "$CHECKS/connect.sh" end > "$T/out" 2>&1 || fail 'the connect did not end'; grep -q "^engines $1 | stand-in: owner at .*words \"$2\"" .vid/tw/handed || fail 'the engines are not on record'; }
mn_project "$T/p"; tk_dev 'the skeleton'; tk_dev 'the step'; C=$(git -C "$T/dev" rev-parse HEAD); c12=$(printf %.12s "$C"); mkdir -p "$T/home"; HOME=$T/home; export HOME
N1=$(gh_issue 'Skeleton'); mn_ticket "$N1" S01 skeleton ROW-003 ROW-004 > "$T/t1"; gh_writing "$N1" "$T/t1" body 2
N2=$(gh_issue 'Step S02'); mn_ticket "$N2" S02 step ROW-001 ROW-005 > "$T/t2"; gh_writing "$N2" "$T/t2" body 2
N3=$(gh_issue 'Step S03'); mn_ticket "$N3" S03 step ROW-006 > "$T/t3"; gh_writing "$N3" "$T/t3" body 2
for n in "$N1" "$N2" "$N3"; do printf 'vid:ticket\n' > "$FAKEGH/issues/$n/labels"; done
printf '%s S01\n%s S02\n%s S03\n' "$N1" "$N2" "$N3" > "$T/register"
mn_switch --applied "$AP" --words 'yes, ratify'; cp "$T/mo" "$T/out"; [ "$MN_RC" = 0 ] || fail "the switch exited $MN_RC"; asks 'the switch'
st manual; [ "$MN_RC" = 0 ] || fail "the take-stock exited $MN_RC"; asks 'the take-stock'
# the analysis: scope says it; the question of an own proposal says it; a refused making names its real reason
printf '\nThe pages are served by one process.\n' >> ARCHITECTURE.md; git commit -qam 'the architecture, one line more'
lock; sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'
sh "$CHECKS/replan.sh" scope > "$T/out" 2>&1 || fail 'replan.sh scope failed'; tr '\t' ' ' < "$T/out" > "$T/tl"; [ "$(grep -cxF "needs engines missing apply owner $L" "$T/tl")" = 1 ] && [ "$(tail -n 1 "$T/tl")" = 'review needed' ] || fail 'scope does not say, in its list, that the engines are missing'
sh "$CHECKS/next-move.sh" call > "$T/out" 2>&1 || fail 'the call failed'; grep '^proposal due: ' "$T/out" | grep -qF "$L" || fail 'the question of the own proposal does not say it'
sh "$CHECKS/replan.sh" own > "$T/out" 2>&1 || fail 'the own proposal was not made'; none 'a proposal made'; rm -rf .vid/next/proposal; cp .vid/tw/handed "$T/kept"; printf 'row ROW-001 nonsense\n' >> .vid/tw/handed
RC=0; sh "$CHECKS/replan.sh" own > "$T/out" 2>&1 || RC=$?; [ "$RC" != 0 ] && grep -q 'could not be made: ViD writer: refused — \.vid/tw/handed' "$T/out" || fail 'a refused making does not name its real reason'; none 'a refused making'; ! grep -q 'engines' .vid/next/own-refused || fail 'the kept reason is the engines'
cat "$T/kept" > .vid/tw/handed
# the records of an acceptance outside ViD, in GitHub manual
rd accept "$N2" "$C" --outside ''; none 'a refused record'
rd accept --rows ROW-002 --outside 'done before'; grep -q '^recorded 1 rows' "$T/out" || fail 'the rows were not recorded'; asks 'the record of rows'
rd accept "$N2" "$C" --outside 'done before'; grep -q "^accepted #$N2 " "$T/out" || fail 'the ticket was not recorded'; asks 'the record of a ticket'
sh "$CHECKS/close.sh" owed > "$T/out" 2>&1; ! grep -q '^close ' "$T/out" || fail 'in manual a close is owed with no engines'
named 'alpha beta' 'alpha first, then beta'; lock
sh "$CHECKS/close.sh" owed > "$T/out" 2>&1; grep -qx 'close S02' "$T/out" || fail 'with the engines named its close is not owed'
rd accept --tickets "$N3" --outside 'done before'; grep -q "^accepted #$N3 " "$T/out" || fail 'the last ticket was not recorded'; none 'a record with the engines named'
sh "$CHECKS/replan.sh" scope > "$T/out" 2>&1 || fail 'replan.sh scope failed'; none 'scope with the engines named'
sh "$CHECKS/next-move.sh" call > "$T/out" 2>&1 || fail 'the call failed'; none 'the question with the engines named'; free; unset CLAUDE_CODE_SESSION_ID
st manual --words 'yes, the re-take'; [ "$MN_RC" = 0 ] || fail "the take-stock with the engines named exited $MN_RC"; none 'the take-stock with the engines named'
# GitHub auto: the skeleton outside, then the close the round asks
sed '/^engines /d' .vid/tw/handed > "$T/h" && cat "$T/h" > .vid/tw/handed; printf 'setup-answered key=github-mode value="auto" words="back to auto" at=2026-11-24T09:00:00Z\n' >> .vid/plan/setup; rm -f .vid/tw/applied
st auto --words 'yes, the re-take'; none 'the take-stock in GitHub auto'
lock; rd accept --tickets "$N1" --outside 'the skeleton, done before'; grep -q "^accepted #$N1 " "$T/out" || fail 'in GitHub auto the skeleton was not recorded'; asks 'the record in GitHub auto'
rd next; grep -q 'error .*the handed record names no engines yet' "$T/out" || fail 'the toy has no close that stops the round for want of engines'; none 'the round'
named 'alpha' 'alpha alone'; lock; rd next; ! grep -q 'names no engines yet' "$T/out" && ! grep -q '^error ' "$T/out" || fail 'round.sh next still stops after the command the line names'
# the skills
S=$CHECKS/../skills; [ -f "$S/vid-mode/SKILL.md" ] || exit 0; : > "$T/out"
for f in vid-accept-step vid-mode; do grep -qF 'engines not named' "$S/$f/SKILL.md" || fail "$f does not say the line"; done; grep -qF '/vid:vid-accept-step engines "<primary> <other>…" "<words>"' "$S/vid-accept-step/SKILL.md" || fail 'vid-accept-step does not name its command'
grep -qF 'needs engines' "$S/vid-replan/SKILL.md" || fail 'vid-replan does not say it'; awk '/^1\. \*\*What it covers/ { f = 1 } /^2\. \*\*The candidate/ { f = 0 } f' "$S/vid-replan/SKILL.md" | grep -qF 'needs engines' || fail 'vid-replan says it, but not at step 1'
echo 'engines-asked: ok'
