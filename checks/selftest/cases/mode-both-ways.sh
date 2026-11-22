#!/bin/sh
# Purpose: selftest case — /vid mode both ways, with GM M2's refusals (GM-4 F13, its case mode-both-ways, less what stays readable,
# 4c's). On the GitHub manual toy (fixtures/manual.sh), switched to GitHub manual with one open ticket: the switch writes I3's
# `owner-questions: all`. `mode.sh auto` is refused, the mode left manual, while the open ticket has a sub-issue; while a change is
# pending (a requirement added since the applied commit); while a row is to place (.vid/tw/to-place); and until the plan is
# ratified again in auto, in the owner's words. With none of them it takes stock and completes: github-mode auto recorded last, a
# `mode name=auto from=manual` event, the plan ratified in those words, no .vid/tw/applied kept and no owner-questions line, and
# no move or trigger the last /vid next raised left open in the owner's queue. What GitHub manual recorded stays readable (4c's part,
# L3): the ticket's acceptance as its merge (E4's `step-<n>-<c12>` line in merges and merged-prs), its decision's `step-` files and
# .vid/decide/unit-merges are as they were after the switch, and the next round in GitHub auto reads them (its step lists the accepted
# ticket not open, GM-4 E2): the step's close owed
# and asked through `close.sh step` at the acceptance's commit. FB-1 B3: there `next.sh triggers` lists a publish move whose line does
# not end "needs your words". Then back to manual, the setting written again, and each publish, amend or withdraw move line ends
# "needs your words". Env: CHECKS.
set -eu
unset VID_CALLER CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "mode-both-ways: $*" >&2; cat "$T/mo" >&2 2>/dev/null; exit 1; }
mode_() { sh -c '. "$1/lib.sh"; ghmode' x "$CHECKS"; }
auto_() { MN_RC=0; sh "$CHECKS/mode.sh" auto --register "$T/register" --review "$T/review" "$@" > "$T/mo" 2>&1 || MN_RC=$?; }
refused() { [ "$MN_RC" = 1 ] || fail "$1: the switch to auto exited $MN_RC, not 1"; grep -qe "$2" "$T/mo" || fail "$1: the refusal does not say: $2"
  [ "$(mode_)" = manual ] || fail "$1: a refused switch changed the mode"; }
mn_project "$T/p"
N1=$(gh_issue 'Skeleton'); mn_ticket "$N1" S01 skeleton ROW-003 ROW-004 > "$T/t1"; gh_writing "$N1" "$T/t1" body 2; printf '%s S01\n' "$N1" > "$T/register"
mn_switch --applied "$AP" --words 'yes, ratify'
[ "$MN_RC" = 0 ] && [ "$(mode_)" = manual ] || fail "the switch to manual exited $MN_RC"
grep -qx 'owner-questions: all' .vid/tw/settings || fail 'the switch to manual did not write owner-questions: all'
# an open ticket with a sub-issue
NS=$(gh_issue 'A unit of the skeleton'); gh_sub "$N1" "$NS"
auto_ --words 'yes, back to auto'; refused 'a sub-issue' 'sub-issues'
grep -q "#$N1" "$T/mo" || fail 'the refusal does not name the ticket with sub-issues'
rm -f "$FAKEGH/issues/$NS/parent"
# a change pending
printf '\nA line the team does not have yet.\n' >> PRD.md; git commit -qam 'a change not applied'
auto_ --words 'yes, back to auto'; refused 'a pending change' 'pending'
git revert --no-edit HEAD > /dev/null
# a row to place
printf 'ROW-005\tno-step\t2026-11-03T09:00:00Z\tthe owner placed it later\n' > .vid/tw/to-place
auto_ --words 'yes, back to auto'; refused 'a row to place' 'to place'
: > .vid/tw/to-place
# until ratified in auto
auto_; refused 'no words' '--words'
# done
# what the last /vid next raised, a move to-do, before the switch
TB=$(printf '\t'); printf 'move\tpublish\tS05\t%s\tpublishes the ticket of S05; needs your words\n' 0123456789abcdef0123456789abcdef01234567 > "$T/lines"
sh "$CHECKS/queue.sh" raise "$T/lines" > "$T/out" 2>&1 || fail 'queue.sh raise failed'
sh "$CHECKS/queue.sh" list > "$T/ql" 2> "$T/out" || fail 'queue.sh list failed'; grep -q "${TB}move:publish:" "$T/ql" || { cp "$T/ql" "$T/out"; fail 'the raised move is no Q line before the switch'; }
# what GitHub manual recorded (4c, L3): #N1 accepted at main's commit, its decision's files, a unit's merge under it; one engine
MC=$(git --git-dir="$T/code.git" rev-parse main); M12=$(printf %.12s "$MC"); mkdir -p .vid/decide .vid/tw/out
printf 'step-%s-%s\n' "$N1" "$M12" >> .vid/decide/merged-prs; printf 'step-%s-%s\t%s\t%s\t%s\n' "$N1" "$M12" "$N1" "$MC" "$MC" >> .vid/decide/merges
printf 'rows ROW-003 ROW-004\n' > ".vid/decide/step-$N1-$M12.rows"; printf 'ticket %s, step %s\nticket: accepted\n' "$N1" "$M12" > ".vid/decide/step-$N1-$M12.txt"
printf '7\t%s\t%s\t%s\n' "$N1" "$MC" "$MC" > .vid/decide/unit-merges; [ -f ".vid/tw/out/issue-$N1.md" ] || cp "$T/t1" ".vid/tw/out/issue-$N1.md"
printf 'engines alpha | stand-in: results reader\n' >> .vid/tw/handed
for f in merged-prs merges unit-merges "step-$N1-$M12.rows" "step-$N1-$M12.txt"; do cp ".vid/decide/$f" "$T/kept-$f"; done
auto_ --words 'yes, back to auto'
[ "$MN_RC" = 0 ] || fail "with nothing in the way the switch to auto exited $MN_RC"
for f in merged-prs merges unit-merges "step-$N1-$M12.rows" "step-$N1-$M12.txt"; do cmp -s ".vid/decide/$f" "$T/kept-$f" || fail "the switch to auto changed .vid/decide/$f"; done
RC=0; sh "$CHECKS/close.sh" owed > "$T/cl" 2>&1 || RC=$?; grep -qx 'close S01' "$T/cl" || { cp "$T/cl" "$T/mo"; fail 'in GitHub auto the acceptance line made no close owed'; }
RC=0; sh "$CHECKS/close.sh" step S01 > "$T/cl" 2>&1 || RC=$?; CN=$(sed -n 's/^asked \([0-9]*\) close S01$/\1/p' "$T/cl")
[ "$RC" = 0 ] && [ -n "$CN" ] || { cp "$T/cl" "$T/mo"; fail "in GitHub auto close.sh step S01 exited $RC, asking nothing"; }
grep -qx "commit: $MC" "$FAKEGH/issues/$CN/body" || fail 'the close in GitHub auto is not at the acceptance commit'
# GM-4 E2, F13: the auto round lists no ticket accepted in GitHub manual as open (its issue open until the step's close)
CLAUDE_CODE_SESSION_ID=mbw; export CLAUDE_CODE_SESSION_ID; sh "$CHECKS/github.sh" lock-take mbw > "$T/out" 2>&1 || fail 'no lock for the auto round'
[ -f DECISIONS.md ] || { printf '# DECISIONS\n\n## Log\n' > DECISIONS.md; git add DECISIONS.md; git commit -qm 'decisions'; }   # the round records the dev side's decisions there
gh issue edit "$N1" -R owner/code --add-label vid:ticket > /dev/null 2>&1 || fail 'the ticket could not be labelled'   # labelled as the writer posts it
RC=0; sh "$CHECKS/round.sh" step > "$T/rs" 2>&1 || RC=$?; [ "$RC" = 0 ] || { cp "$T/rs" "$T/mo"; fail "the auto round's step exited $RC"; }
TO=$(awk -F'\t' '$1 == "issue" && ("," $3 ",") ~ /,vid:(ticket|run|grade|deploy),/' .vid/round/read | grep -c . || true); OP=$(sed -n 's/^progress: .* open=\([0-9]*\) .*/\1/p' "$T/rs")
grep -q "^issue	$N1	" .vid/round/read && [ "$OP" = $((TO - 1)) ] || { cp "$T/rs" "$T/mo"; fail "the auto round lists the ticket accepted in GitHub manual as open (open=$OP of $TO)"; }
# FB-1 B3: in GitHub auto no publish, amend or withdraw move line asks for the owner's words
sh "$CHECKS/next.sh" triggers > "$T/L" 2> "$T/out" || fail 'next.sh triggers failed in GitHub auto'
grep -q "^move${TB}publish${TB}" "$T/L" || { cp "$T/L" "$T/mo"; fail 'in GitHub auto the triggers list no publish move'; }
! grep -E "^move${TB}(publish|amend|withdraw)${TB}" "$T/L" | grep -q 'needs your words$' || { cp "$T/L" "$T/mo"; fail 'in GitHub auto a publish, amend or withdraw move line still ends: needs your words'; }
sh "$CHECKS/github.sh" lock-free > /dev/null 2>&1 || true; unset CLAUDE_CODE_SESSION_ID

sh "$CHECKS/queue.sh" list > "$T/ql" 2> "$T/out" || fail 'queue.sh list failed in GitHub auto'
! grep -q "${TB}\(move\|trigger\):" "$T/ql" || { cp "$T/ql" "$T/out"; fail 'a move or trigger the last /vid next raised is still open in GitHub auto'; }
grep -qx 'mode: GitHub auto, recorded' "$T/mo" || fail 'the switch did not say GitHub auto is recorded'
[ "$(mode_)" = auto ] || fail 'the mode is not auto'
grep -q '^mode name=auto from=manual words="yes, back to auto"' .vid/metrics-events || fail 'the mode event is not recorded'
tail -n 1 .vid/plan/ratified | grep -q 'words=yes, back to auto' || fail 'the plan is not ratified in the owner'"'"'s words'
[ ! -f .vid/tw/applied ] || fail 'GitHub auto keeps a record of the applied version'
grep -q '^owner-questions:' .vid/tw/settings && fail 'the switch to auto left owner-questions in the settings'
# back to manual
mn_switch --applied "$(git rev-parse HEAD)" --devagent 'DevAgent is stopped' --words 'yes, manual again'
[ "$MN_RC" = 0 ] && [ "$(mode_)" = manual ] || fail "the switch back to manual exited $MN_RC"
grep -qx 'owner-questions: all' .vid/tw/settings || fail 'the switch back to manual did not write owner-questions: all'
# FB-1 B3: in GitHub manual each publish, amend or withdraw move line asks for the owner's words
sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed in GitHub manual'
sh "$CHECKS/next.sh" triggers > "$T/L" 2> "$T/out" || fail 'next.sh triggers failed in GitHub manual'
grep -q "^move${TB}publish${TB}" "$T/L" || { cp "$T/L" "$T/mo"; fail 'in GitHub manual the triggers list no publish move'; }
! grep -E "^move${TB}(publish|amend|withdraw)${TB}" "$T/L" | grep -qv 'needs your words$' || { cp "$T/L" "$T/mo"; fail 'in GitHub manual a publish, amend or withdraw move line does not end: needs your words'; }
echo 'mode-both-ways: ok'
