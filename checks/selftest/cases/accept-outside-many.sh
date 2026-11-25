#!/bin/sh
# Purpose: selftest case — several tickets accepted outside ViD are recorded in one call (FB-3 E1): round.sh accept --tickets
# "<n>[@<commit>] …" --outside "<words>", on GitHub manual's toy and the fake gh (fixtures/accept.sh), both issues closed. Before it all four
# stand: the stage-ahead warning counts stage 0's tests; `context closed` is told, its line and accept's refusal naming the third
# command, /vid:vid-accept-step <n> <commit> accepted "<your words>"; the step's close is not owed; rule B holds a step that builds on it. The
# skeleton with no commit named is recorded at its decision comment's commit, the step named at a commit off main at main's newest, its
# record saying which; a withdrawn ticket refused alone; with no words each is. One read, one save of the records, nothing posted. The
# label ends `; evidence: none, accepted outside ViD`, and nothing a run writes is written: no results, no decision log, no review, no fault proof. After it none
# of the four stands: the count is 0, nothing is told, each close is owed, the skeleton's in stage 0's run, and once that passed rule B
# (GitHub auto's; GitHub manual holds no step) admits the step built on it. A ticket already recorded is refused. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/accept.sh"
fail() { echo "accept-outside-many: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
ac_project "$T/p" || fail 'the toy could not be made'; ac_plan || fail 'the plan could not be recorded'; D=.vid/decide; W='both were accepted before this'
c12() { printf %.12s "$1"; }
printf 'engines alpha | stand-in: owner at 2026-11-18T09:00:00Z, words "alpha"\n' >> .vid/tw/handed
sh "$CHECKS/event.sh" 'stage name=run state=start session=ac records=34' > /dev/null 2>&1
K=$(gh_issue 'Skeleton'); { mn_ticket "$K" S01 skeleton ROW-003 ROW-004; printf '\n## Engines\n\n- primary: alpha\n'; } > ".vid/tw/out/issue-$K.md"; printf 'published %s kind=skeleton step=S01 rows=ROW-003,ROW-004 at=2026-11-18T09:00:00Z\n' "$K" >> .vid/tw/log
N2=$(gh_issue 'Step S03'); { mn_ticket "$N2" S03 step ROW-006; } > ".vid/tw/out/issue-$N2.md"; printf 'published %s kind=step step=S03 rows=ROW-006 at=2026-11-18T09:00:00Z\nwithdrawn %s decision=abc at=2026-11-19T09:00:00Z\n' "$N2" "$N2" >> .vid/tw/log
printf 'vid: decision %s\nticket: accepted\n' "$AC_RED" > "$T/cm"; gh issue comment "$K" -R owner/code --body-file "$T/cm" > /dev/null
posts() { for n in "$K" "$AC_N"; do ls "$FAKEGH/issues/$n/comments" 2>/dev/null; done | grep -c . || true; }
w0_() { { cat .vid/tw/handed; find $D -type f -size +0 ! -path '*/queue/*' -exec cksum {} + | grep -vE '/(unit-merges|unit-asks|merged-prs|refused|flags|accepted-log)$' || :; } | sort | cksum; }
warn() { sh "$CHECKS/plan.sh" warnings S05 2> "$T/out" | grep 'ahead of stage 0' | sed 's/.*whose \([0-9]*\) tests are not.*/\1/' | head -n 1; }
mode_() { printf 'setup-answered key=github-mode value="%s" words="the toy, %s" at=2026-11-20T09:00:00Z\n' "$1" "$1" >> .vid/plan/setup; }
# the admission of S03, built on S01: rule B is GitHub auto's (in GitHub manual no step is held), so it is read in auto
admit() { mode_ auto; sh "$CHECKS/plan.sh" admit S03 > "$T/out" 2>&1 || :; mode_ manual; head -n 1 "$T/out"; }
owed() { sh "$CHECKS/close.sh" owed > "$T/out" 2>&1 || :; grep -qx "$1" "$T/out"; }
# the four, before
ac_round read; [ "$(warn)" = 2 ] || fail 'the warning does not count stage 0 two tests on the toy'
for n in "$K" "$AC_N"; do gh issue close "$n" -R owner/code --reason 'not planned'; done
third() { printf '/vid:vid-accept-step %s <commit> accepted "<your words>" records it as accepted outside ViD' "$1"; }
trg() { sh "$CHECKS/next.sh" read > "$T/out" 2>&1; sh "$CHECKS/next.sh" triggers > "$T/L" 2> "$T/out" || fail 'next.sh triggers failed'; cp "$T/L" "$T/out"; }; TABB=$(printf '\t')
trg; for n in "$K" "$AC_N"; do grep "^context${TABB}closed${TABB}#$n${TABB}closed on GitHub as not planned, not accepted — " "$T/out" | grep -qF "$(third "$n")" || fail "#$n, closed, is not told with the third command"; done
ac_round accept "$AC_N"; grep "^refused #$AC_N closed on GitHub before its acceptance: " "$T/out" | grep -qF "$(third "$AC_N")" || fail 'the refusal of a closed ticket does not name the third command'
! owed 'stage 0' && ! owed 'close S02' || fail 'a close is owed before'; case $(admit) in "admit	S03	held	"*'builds on S01, which is not closed'*) ;; *) fail 'S03 is not held for S01 before' ;; esac
# usage, and the words
w0=$(w0_); c0=$(posts)
for a in '' 'x' "$K@zz" "$K@" "@$AC_C"; do ac_round accept --tickets "$a" --outside "$W"; [ "$RC" = 2 ] && [ "$(w0_)" = "$w0" ] || fail "--tickets \"$a\" exited $RC, not 2, or wrote something"; done
ac_round accept --tickets "$K"; [ "$RC" = 2 ] || fail 'with no --outside it is not a usage error'; ac_round accept "$AC_N" "$AC_C" --tickets "$K" --outside "$W"; [ "$RC" = 2 ] || fail 'beside a ticket it is not a usage error'; ac_round accept --tickets "$K" --rows ROW-002 --outside "$W"; [ "$RC" = 2 ] || fail 'beside rows it is not a usage error'
ac_round accept --tickets "$K $AC_N" --outside ' '; [ "$(grep -c '^refused #[0-9]* no words' "$T/out")" = 2 ] && [ "$(w0_)" = "$w0" ] || fail 'with no words it is not refused, or something was written'
# the record
gh_wclear; : > "$FAKEGH/log"; ac_round accept --tickets "$K #$AC_N@$(c12 "$AC_OFF") $N2" --outside "$W"; [ "$RC" = 0 ] || fail "the record exited $RC"
grep -qx "accepted #$K $(c12 "$AC_RED"), outside ViD, by the owner's words" "$T/out" || fail 'the skeleton is not recorded at the commit of its decision comment'
grep -qx "accepted #$AC_N $(c12 "$AC_C"), outside ViD, by the owner's words, at main's newest commit ($(c12 "$AC_OFF") is not on main)" "$T/out" || fail 'the step is not recorded at main newest, said so'
grep -qx "refused #$N2 no published ticket that is not withdrawn" "$T/out" || fail 'the withdrawn ticket is not refused alone'
[ "$(grep -c 'issue list .*--state open --limit 1000 .*updatedAt' "$FAKEGH/log")" = 1 ] || fail 'it did not make one read of GitHub'; [ "$(grep -c '^owner/vid-state push refs/heads/vid-state/records' "$FAKEGH/writes")" = 1 ] || fail 'the records were not saved once'
[ "$(posts)" = "$c0" ] && ! grep -q '^owner/code ' "$FAKEGH/writes" || fail 'something was posted'
E='; evidence: none, accepted outside ViD'
for r in ROW-003 ROW-004; do grep -q "^row $r accepted-by-ruling | stand-in: owner at [0-9TZ:-]*, words \"$W\"$E\$" .vid/tw/handed || { cat .vid/tw/handed >&2; fail "$r's label does not end with the evidence missing"; }; done
grep -q "^row ROW-001 accepted-by-ruling | stand-in: owner at [0-9TZ:-]*, words \"$W\", at main's newest commit ($(c12 "$AC_OFF") is not on main)$E\$" .vid/tw/handed || { cat .vid/tw/handed >&2; fail "ROW-001's label does not say the commit and the evidence missing"; }
grep -q "^accepted-outside ticket=$AC_N .*commit=$(c12 "$AC_C") words=\"$W\" note=\"at main's newest commit ($(c12 "$AC_OFF") is not on main)\"" .vid/metrics-events || { grep '^accepted-outside' .vid/metrics-events >&2; fail 'the event does not say the commit is main newest'; }
grep -qx "$(printf 'step-%s-%s\t%s\t%s\t%s' "$K" "$(c12 "$AC_RED")" "$K" "$AC_RED" "$AC_RED")" $D/merges && grep -qx "$(printf 'step-%s-%s\t%s\t%s\t%s' "$AC_N" "$(c12 "$AC_C")" "$AC_N" "$AC_C" "$AC_C")" $D/merges || fail 'the merge lines are not there'
! ls .vid/results/ 2>/dev/null | grep -qE '^(step|pr|stand-in)' && [ ! -s $D/log ] && [ ! -d $D/review ] && ! grep -q 'fault-proven' .vid/tw/handed && [ -z "$(git --git-dir=.vid/code for-each-ref refs/heads/vid-results)" ] || fail 'something a run or a review writes was written'
# the four, after
for n in "$K" "$AC_N"; do gh_attr "$n" state OPEN; done; ac_round read; [ "$(warn)" = 0 ] || fail 'the warning still counts stage 0 tests'; for n in "$K" "$AC_N"; do gh_attr "$n" state CLOSED; done
trg; ! grep -q "^context${TABB}closed" "$T/out" || fail 'a recorded ticket is still told closed and not accepted'
owed 'stage 0' || fail "stage 0's run, S01's close among it, is not owed"; owed 'close S02' || fail "S02's close is not owed"
ac_round accept --tickets "$K" --outside "$W"; grep -qx "refused #$K accepted already, at $(c12 "$AC_RED")" "$T/out" || fail 'a ticket on record is not refused'
# stage 0's run passed, the line it writes for its step
printf 'closed S01 | stand-in: C3 #9 at 1\n' >> .vid/tw/handed
case $(admit) in "admit	S03	ok	"*) ;; *) fail 'S03, which builds on S01, is not admitted' ;; esac
echo 'accept-outside-many: ok'
