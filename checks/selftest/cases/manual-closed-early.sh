#!/bin/sh
# Purpose: selftest case — a ticket the team closes before its acceptance (GM-4 E6, GM M8), in GitHub manual on the toy and the fake gh
# (fixtures/accept.sh). Closed on GitHub as not planned, not accepted: next.sh triggers tells it at every call with its commands (FB-6 A1.3), round.sh step withdraws nothing
# and reopens no step; round.sh accept refuses it, naming them, posting nothing. The owner's withdraw with words (github.sh tw-hand
# withdraw) writes `withdrawn <n> decision=closed-outside` with the words, posts nothing on the ticket, and makes writer.sh due owe its
# step a new ticket; told no more. A ticket closed after its acceptance is not told. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/accept.sh"
fail() { echo "manual-closed-early: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
ac_project "$T/p" || fail 'the toy could not be made'; ac_plan || fail "the plan could not be recorded"
M=$(gh_issue 'Step S03'); { mn_ticket "$M" S03 step ROW-006; printf '\n## Engines\n\n- primary: alpha\n'; } > ".vid/tw/out/issue-$M.md"
printf 'published %s kind=step step=S03 rows=ROW-006 at=2026-11-18T09:00:00Z\n' "$M" >> .vid/tw/log
mkdir -p .vid/decide; printf 'step-%s-%s\t%s\t%s\t%s\n' "$M" "$(printf %s "$AC_C" | cut -c1-12)" "$M" "$AC_C" "$AC_C" > .vid/decide/merges   # accepted at AC_C
gh issue close "$AC_N" -R owner/code --reason 'not planned'; gh issue close "$M" -R owner/code; c0=$(ac_comments)
TAB=$(printf '\t'); trig() { sh "$CHECKS/next.sh" triggers > "$T/L" 2> "$T/out" || fail 'next.sh triggers failed'; cp "$T/L" "$T/out"; }
for k in 1 2; do ac_round step; [ "$RC" = 0 ] || fail "round.sh step exited $RC"; ! grep -q '^closed ' "$T/out" || fail 'the round says it beside the call'"'"'s lines'; trig
  [ "$(grep -c "^context${TAB}closed${TAB}#$AC_N${TAB}closed on GitHub as not planned, not accepted — /vid:vid-tickets reopen #$AC_N \".*/vid:vid-tickets withdraw #$AC_N \".*/vid:vid-accept-step $AC_N <commit> accepted \"" "$T/L")" = 1 ] || fail "call $k: the ticket closed early is not told once with its commands"
  ! grep -q "^context${TAB}closed${TAB}#$M$TAB" "$T/L" || fail 'a ticket closed after its acceptance was told'; done; ac_round step
! grep -q "^withdrawn $AC_N " .vid/tw/log || fail 'the round withdrew the ticket closed early'; ! grep -q '^step-reopened\|^closed-outside' "$T/out" || fail 'the round reopened a step or withdrew in GitHub manual'
ac_round accept "$AC_N"; grep -q "^refused #$AC_N closed on GitHub before its acceptance: /vid:vid-tickets reopen #$AC_N .*/vid:vid-tickets withdraw #$AC_N " "$T/out" || fail 'accept did not refuse the closed ticket naming both commands'
[ "$(ac_comments)" = "$c0" ] || fail 'something was posted on the closed ticket'
# the owner's withdrawal, with words
gh_wclear; sh "$CHECKS/github.sh" tw-hand withdraw "$AC_N" --words 'It was closed by mistake; write it again' > "$T/out" 2>&1 || fail 'the withdrawal was refused'
grep -q "^withdrawn $AC_N decision=closed-outside .*words=\"It was closed by mistake; write it again\"" .vid/tw/log || fail 'the withdrawal is not the closed-outside line with the words'
! grep -q "owner/code issue \(comment\|close\|edit\|reopen\) $AC_N" "$FAKEGH/writes" && [ "$(ac_comments)" = "$c0" ] || fail 'the withdrawal posted on the ticket'
sh "$CHECKS/writer.sh" due > "$T/out" 2>&1 || fail 'writer.sh due failed'; grep -qx 'new step S02' "$T/out" || fail 'the writer owes its step no new ticket'
sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'; trig; ! grep -q "^context${TAB}closed${TAB}#$AC_N$TAB" "$T/L" || fail 'a withdrawn ticket is still told'
exit 0
