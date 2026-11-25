#!/bin/sh
# Purpose: selftest case — the label that says a question stops a ticket (FB-5 B1.1), on GitHub manual's toy and the fake gh
# (fixtures/accept.sh): the prefix's `blocked`, or any label that ends `:blocked`, its one reading lib.sh's. With a label of the team's own
# the round prints `question <n>`, the call's lines raise the critical `blocked` trigger naming the issue and that label, and a ticket
# whose every test passes reads `ticket: not yet`, its rows `question open`; with the label gone the same ask is accepted. The unblock takes off the label the read
# shows, the prefix's too where it is there, and the prefix's alone where the read shows none. A label that only holds the word, or the bare
# word under another prefix, is none. GitHub auto reads the label the same way on the issue and the pull request, the
# round's question and the unblock too. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
HOME=$T/home; export HOME; mkdir -p "$HOME"
. "$CHECKS/selftest/fixtures/accept.sh"
fail() { echo "blocked-label: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t'); lab() { printf '%s\n' "$@" > "$FAKEGH/issues/$AC_N/labels"; }
# the one reading: the labels, the prefix, what it says
[ -n "$(sh -c 'HERE=$CHECKS; . "$CHECKS/lib.sh"; type blkl' 2>/dev/null)" ] || fail 'lib.sh holds no one reading of the label (blkl)'
bl() { sh -c 'HERE=$CHECKS; . "$CHECKS/lib.sh"; blkl "$1" "$2"' x "$1" "$2"; }
[ "$(bl 'a,team:blocked,vid:blocked' vid:)" = team:blocked,vid:blocked ] && [ "$(bl blocked '')" = blocked ] && [ -z "$(bl 'unblocked,blocked,team:blocked-by,x:unblocked' vid:)" ] || fail 'the labels are not read as they should be'
ac_project "$T/p" || fail 'the toy could not be made'; c12=$(printf %.12s "$AC_C")
ac_good "$AC_C"; lab bug team:blocked; ac_ask "$AC_C"
ac_round step; [ "$RC" = 0 ] && grep -qx "question $AC_N" "$T/out" || fail 'the round does not print the question of a label of the team'"'"'s own'
sh "$CHECKS/next.sh" triggers > "$T/L" 2> "$T/out" || fail 'next.sh triggers failed'; cp "$T/L" "$T/out"
grep -qx "trigger${TB}critical${TB}blocked${TB}#$AC_N${TB}label team:blocked" "$T/L" || fail 'the label raises no critical blocked trigger naming it'
ac_round accept "$AC_N" "$AC_C"; [ "$RC" = 0 ] || fail "accept exited $RC"; ac_last > "$T/out"
grep -qx 'ticket: not yet' "$T/out" && grep -qx 'ROW-001 question open' "$T/out" || fail 'a ticket was accepted under an open question'
! grep -q '^step-' .vid/decide/merges 2>/dev/null || fail 'an acceptance is on record under an open question'
# the unblock: the label the read shows, then the prefix's beside it, then the prefix's alone with none in the read
sh "$CHECKS/github.sh" label "$AC_N" --remove blocked > "$T/out" 2>&1 || fail 'the label could not be taken off'
[ "$(paste -sd ' ' - < "$FAKEGH/issues/$AC_N/labels")" = bug ] || { cp "$FAKEGH/issues/$AC_N/labels" "$T/out"; fail 'the label seen was not taken off, alone'; }
lab bug team:blocked vid:blocked; ac_round read; sh "$CHECKS/github.sh" label "$AC_N" --remove blocked > "$T/out" 2>&1 || fail 'the two labels could not be taken off'
[ "$(paste -sd ' ' - < "$FAKEGH/issues/$AC_N/labels")" = bug ] || fail 'one of the two labels stayed'
ac_round read; lab bug vid:blocked; sh "$CHECKS/github.sh" label "$AC_N" --remove blocked > "$T/out" 2>&1; [ "$(paste -sd ' ' - < "$FAKEGH/issues/$AC_N/labels")" = bug ] || fail 'the prefix'"'"'s label, in no read, was not taken off'
# a label that only holds the word is none
lab unblocked blocked team:blocked-by; ac_ask "$AC_C"; ac_round step; ! grep -qx "question $AC_N" "$T/out" || fail 'another label was read as it'
ac_round accept "$AC_N" "$AC_C"; grep -q "^accepted #$AC_N $c12" "$T/out" || fail 'with no such label the ticket was not accepted'
# a label on a pull request, as both modes read it: the round's question, and the one seen taken off (the fake edits no pull request's labels: its log says it)
( cd "$T/dev" && git checkout -q -B unit main && echo u > u.txt && git add -A && g commit -q -m u && git push -q -f origin unit 2>/dev/null && git checkout -q main ); P=$(gh pr create -R owner/code --head unit --base main --title u --body "ticket: #$AC_N" | sed 's#.*/##')
printf '%s\n' bug x:blocked > "$FAKEGH/prs/$P/labels"; ac_round step; [ "$RC" = 0 ] && grep -qx "question $P" "$T/out" || fail 'the round does not print the question of a label on a pull request'
sh "$CHECKS/github.sh" label "$P" --remove blocked > "$T/out" 2>&1 || :; tail -n 1 "$FAKEGH/log" > "$T/out"; grep -q "^gh issue edit $P .*--remove-label x:blocked\$" "$T/out" || fail 'the label seen on a pull request is not the one taken off'
rm "$FAKEGH/prs/$P/labels"
# GitHub auto
printf 'setup-answered key=github-mode value="auto" words="back to auto" at=2026-11-20T09:00:00Z\n' >> .vid/plan/setup
[ -z "$(sh "$CHECKS/github.sh" decide-blocked "$AC_N" "$P")" ] || fail 'in GitHub auto another label was read as it'
echo team:blocked > "$FAKEGH/prs/$P/labels"; [ "$(sh "$CHECKS/github.sh" decide-blocked "$AC_N" "$P")" = blocked ] || fail 'in GitHub auto the label on the pull request is not read'
rm "$FAKEGH/prs/$P/labels"; lab x:blocked; [ "$(sh "$CHECKS/github.sh" decide-blocked "$AC_N" "$P")" = blocked ] || fail 'in GitHub auto the label on the issue is not read'
echo 'blocked-label: ok'
