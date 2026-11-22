#!/bin/sh
# Purpose: selftest case — FB-2 A3: the round tells the owner when DevAgent has left a ticket, checks/round.sh on the ticket writer's
# toy and the fake gh, in GitHub auto. An open ticket whose comments end `DM: left: two stops`: the step flags `ticket-left 1: two
# stops`, once; a `vid: reopened at the owner's word` comment after it clears the flag (a flag-cleared event); a later `DM: left:`
# raises it again. The old leave comment (`DM: <why>`, before this release) raises nothing. vid-run's table tells the owner in one
# line, naming /vid:vid-tickets reopen, where skills/ sits beside checks/. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "round-left: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; R=owner/code
rd() { RC=0; sh "$CHECKS/round.sh" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q "$1" "$T/out" || fail "a line: $1"; }
cm() { printf '%s\nby: DM\n' "$1" > "$T/c"; gh issue comment 1 -R $R --body-file "$T/c" > /dev/null; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; sh "$CHECKS/event.sh" 'stage name=run state=start session=t records=33'; sh "$GS" lock-take t > "$T/out" 2>&1 || fail 'no lock'
rd next; [ "$RC" = 0 ] || fail "next failed: $RC"; ok '^published 1$'
cm 'vid: claimed'; cm 'DM: an agent stopped twice'; rd step; [ "$RC" = 0 ] || fail "the step failed: $RC"; no '^flag ticket-left'
# left: raised, once
cm 'DM: left: two stops'; rd step; [ "$RC" = 0 ] || fail "the step failed: $RC"; ok '^flag ticket-left 1: two stops$'
grep -q 'word=ticket-left on=1' .vid/metrics-events || fail 'no flag event'; rd step; no '^flag ticket-left'
# the owner's reopen clears it; a later leave raises it again
printf "vid: reopened at the owner's word\n" > "$T/c"; gh issue comment 1 -R $R --body-file "$T/c" > /dev/null; rd step; no '^flag ticket-left'
grep -q 'flag-cleared word=ticket-left on=1' .vid/metrics-events || fail 'the reopen did not clear the flag'
cm 'DM: left: no report'; rd step; ok '^flag ticket-left 1: no report$'
S=$CHECKS/../skills/vid-run/SKILL.md
[ ! -d "$CHECKS/../skills" ] || grep -qF '| `flag ticket-left <n>: <why>` (FB-2 A3) | Tell the owner once, in one line: `DevAgent left ticket #<n>: <why>. When what it needs is in place, /vid:vid-tickets reopen #<n> "<your words>" has it taken up again.` It stops nothing |' "$S" || fail "vid-run's table has no ticket-left line"
exit 0
