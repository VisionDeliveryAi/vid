#!/bin/sh
# Purpose: selftest case — one form of the ticket on GitHub (GM-4 F6): the form of a post comes from the setup alone, never the
# mode. GitHub auto with issue-form: set (TW's toy after the skeleton's round, the toy form committed): `tw-hand publish S02` posts
# the issue in the form, its title and body the filled form, every part a comment, its log line naming the form's hash; amended
# after a plan change takes a row out of S02, the body is refilled from the form (the row gone from its tests line), never replaced
# by part 1. GitHub manual with no issue-form: (the form fixture's toy, the key taken out): the owner's publish goes out with part 1
# as the body, as GitHub auto posts it, the words on its line and no form hash. tw-team-no works in GitHub auto too: its comment
# is posted and logged. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T0=$(mktemp -d); trap 'rm -rf "$T0"' EXIT; T=$T0/auto; mkdir -p "$T"
. "$CHECKS/selftest/fixtures/form.sh"
fail() { echo "ticket-form-setup: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
GS=$CHECKS/github.sh
pub() { sed -n 's/^ViD github: [a-z]* ticket #\([0-9]*\).*/\1/p' "$T/out"; }
# GitHub auto, the form in the setup
tw_toy "$T/toy"; tw_skel || fail 'the skeleton round failed'
mkdir -p forms; fm_form forms/issue.md; g add forms/issue.md; g commit -qm 'the issue form'; printf 'issue-form: forms/issue.md\n' >> .vid/tw/settings
RC=0; CLAUDE_CODE_SESSION_ID=owner-a sh "$GS" tw-hand publish S02 > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "GitHub auto: the publish in the form exited $RC"
N=$(pub); [ -n "$N" ] || fail 'GitHub auto: no ticket posted'; B=$T/gh/issues/$N/body
grep -q '^Ticket #' "$B" && fail "GitHub auto: with issue-form: set, the body is ViD's part 1, not the form: $(head -n 1 "$B")"
grep -qx "The toy team's own words: one line of what the step gives the user." "$B" && grep -qx 'S02' "$B" || fail 'GitHub auto: the body is not the filled form'
[ "$(cat "$T/gh/issues/$N/title")" != "$(sed -n '1s/^# //p' .vid/tw/out/issue-$N.md)" ] && grep -q '^S02: ' "$T/gh/issues/$N/title" || fail "GitHub auto: the title is not the form's: $(cat "$T/gh/issues/$N/title")"
head -n 1 "$T/gh/issues/$N/comments/1" | grep -q "^Ticket #$N, part 1 of " || fail 'GitHub auto: part 1 is not the first comment'
grep -q "^published $N kind=step step=S02 .* form=$(git rev-parse HEAD:forms/issue.md)" .vid/tw/log || fail 'GitHub auto: the log line does not name the form'
grep -q 'ROW-013' "$B" || fail 'GitHub auto: the toy S02 no longer holds ROW-013 in its tests (the case needs it)'
# amended: the body refilled from the form, ROW-013 gone from it
pt_rs 's/^\(step S02 .*\)ROW-013 /\1/'; pt_rs 's/^\(step S04 .*rows: \)/\1ROW-013 /'
sh "$CHECKS/plan.sh" change rows 'ROW-013 waits for S04' --trigger scope-change --evidence "ticket:$N" --expect 'S02 ships without it' > "$T/out" 2>&1 || fail 'the plan change was refused'
RC=0; CLAUDE_CODE_SESSION_ID=owner-a sh "$GS" tw-hand amend "$N" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "GitHub auto: the amendment of the form's ticket exited $RC"
grep -q '^Ticket #' "$B" && fail "GitHub auto: the amendment replaced the form's body with part 1: $(head -n 1 "$B")"
grep -qx "The toy team's own words: one line of what the step gives the user." "$B" && ! grep -q 'ROW-013' "$B" || fail 'GitHub auto: the body is not the form refilled without ROW-013'
grep -q "^amended $N .* form=" .vid/tw/log || fail "GitHub auto: the amendment's line names no form"
# tw-team-no, in GitHub auto
RC=0; sh "$GS" tw-team-no "$N" ROW-006 added > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "GitHub auto: tw-team-no exited $RC"
grep -q "^team-no $N ROW-006 added at=" .vid/tw/log || fail 'GitHub auto: the team-no is not logged'

# GitHub manual, no issue-form: in the setup
T=$T0/man; mkdir -p "$T"; fm_toy "$T/toy" || fail 'the manual toy could not be made'
grep -v '^issue-form:' .vid/tw/settings > "$T/s" && cat "$T/s" > .vid/tw/settings
RC=0; CLAUDE_CODE_SESSION_ID=owner-m sh "$GS" tw-hand publish S01 --words 'Yes, publish the skeleton' > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "GitHub manual: a publish with no issue form exited $RC"
M=$(pub); [ -n "$M" ] || fail 'GitHub manual: no ticket posted'
head -n 1 "$FAKEGH/issues/$M/body" | grep -q "^Ticket #$M, part 1 of " || fail "GitHub manual: with no issue-form:, the body is not part 1: $(head -n 1 "$FAKEGH/issues/$M/body")"
L=$(grep "^published $M " .vid/tw/log); case $L in *' form='*) fail "GitHub manual: a post with no form names one: $L" ;; esac
case $L in *' words="Yes, publish the skeleton"') ;; *) fail "GitHub manual: the words are not on the line: $L" ;; esac
exit 0
