#!/bin/sh
# Purpose: selftest case — a unit's pull request asking `vid: decide` in GitHub manual (GM-4 E1): never answered and no error; round.sh
# step goes on and lists it once a head, `context unit-ask #<p> <the ticket its ticket line names> <head12>`, and again for a new head.
# On GitHub manual's toy and the fake gh (fixtures/accept.sh). Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/accept.sh"
fail() { echo "manual-unit-ask: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
ac_project "$T/p" || fail 'the toy could not be made'
br() { ( cd "$T/dev" && git checkout -q -B unit-1 main && g commit -q --allow-empty -m "$1" && git push -q -f origin unit-1 2>/dev/null && git checkout -q main ); git -C "$T/dev" rev-parse unit-1; }
H=$(br 'a unit'); P=$(gh pr create -R owner/code --head unit-1 --base main --title 'a unit' --body "$(printf 'ticket: #%s\n\nDecisions: none' "$AC_N")" | sed 's#.*/##')
printf 'vid: decide %s\nby: MR\n' "$H" > "$T/c"; gh pr comment "$P" -R owner/code --body-file "$T/c" > /dev/null; h=$(printf %s "$H" | cut -c1-12)
ac_round step; [ "$RC" = 0 ] || fail "round.sh step exited $RC on a unit's ask"
[ "$(grep -c "^context unit-ask #$P $AC_N $h\$" "$T/out")" = 1 ] || fail "the unit's ask is not listed once as context unit-ask #$P $AC_N $h"
! grep -q '^decide\|^decided' "$T/out" || fail "a unit's ask was decided"
[ "$(ls "$FAKEGH/prs/$P/comments" | grep -c .)" = 1 ] || fail "the unit's pull request was answered"
ac_round step; [ "$RC" = 0 ] || fail "the second step exited $RC"; ! grep -q '^context unit-ask' "$T/out" || fail 'the same head was listed twice'
H2=$(br 'the unit again'); echo "$H2" > "$FAKEGH/prs/$P/headoid"; printf 'vid: decide %s\nby: MR\n' "$H2" > "$T/c"; gh pr comment "$P" -R owner/code --body-file "$T/c" > /dev/null
ac_round step; grep -q "^context unit-ask #$P $AC_N $(printf %s "$H2" | cut -c1-12)\$" "$T/out" || fail 'a new head of the unit was not listed'
[ "$(ls "$FAKEGH/prs/$P/comments" | grep -c .)" = 2 ] || fail "the unit's pull request was answered at its new head"
exit 0
