#!/bin/sh
# Purpose: selftest case — what holds and frees a ticket closed as completed and not accepted (FB-6 A1.2), in GitHub manual on the toy and the
# fake gh (fixtures/ask-pull.sh). A: a `…:blocked` label on it: its critical trigger is raised, a question on it is listed, and every test
# passing it reads `not yet`, `question open`; a question changed since its listing is refused its answer, nothing posted; answered as it
# stands, the label goes and the same ask, made again, is accepted. B: a step's own pull request merged, closing the ticket, the label on that pull
# request alone: still held. C: accepted at its own pull request's head and merged, not on record yet: told with vid-accept-step alone. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
B=$(mktemp -d); trap 'rm -rf "$B"' EXIT; TAB=$(printf '\t')
HOME=$B/home; export HOME; mkdir -p "$HOME"
fail() { echo "closed-held: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
toy() { T=$B/$1; mkdir -p "$T"; . "$CHECKS/selftest/fixtures/ask-pull.sh"; ac_project "$T/p" || fail "the toy $1 could not be made"; c0=$(ac_comments); }
trig() { sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'; sh "$CHECKS/next.sh" triggers > "$T/L" 2> "$T/out" || fail 'next.sh triggers failed'; cp "$T/L" "$T/out"; }

# A
toy a; c12=$(printf %.12s "$AC_C"); gh issue close "$AC_N" -R owner/code; printf 'team:blocked\n' > "$FAKEGH/issues/$AC_N/labels"
printf 'Question: ROW-001, is the empty list shown?\n' > "$T/q"; gh issue comment "$AC_N" -R owner/code --body-file "$T/q" > /dev/null; ac_good "$AC_C"; ac_ask "$AC_C"
trig; grep -qx "trigger${TAB}critical${TAB}blocked${TAB}#$AC_N${TAB}label team:blocked" "$T/L" || fail 'the label on the closed ticket raises no trigger'
sh "$CHECKS/queue.sh" list > "$T/ql" 2> "$T/out" || fail 'queue.sh list failed'; k=$(awk -F'\t' -v n="$AC_N" 'index($2, "question:" n ":") == 1 { print $1; exit }' "$T/ql"); [ -n "$k" ] || { cp "$T/ql" "$T/out"; fail 'the question on the closed ticket is not listed'; }
ac_round accept "$AC_N" "$AC_C"; ac_last > "$T/out"; grep -qx 'ticket: not yet' "$T/out" && grep -qx 'ROW-001 question open' "$T/out" || fail 'a closed ticket was accepted under an open question'
printf 'Question: ROW-001, is the empty list shown, or a message?\n' > "$FAKEGH/issues/$AC_N/comments/1"; sh "$CHECKS/next.sh" read > "$T/out" 2>&1; c1=$(ac_comments); rc=0; sh "$CHECKS/queue.sh" answer "$k" 'The list' > "$T/out" 2>&1 || rc=$?
[ "$rc" != 0 ] && [ "$(ac_comments)" = "$c1" ] || fail 'an answer to a question changed since its listing was posted on the closed ticket'
sh "$CHECKS/queue.sh" list > "$T/ql" 2> "$T/out" || fail 'queue.sh list failed'; sh "$CHECKS/queue.sh" answer "$k" 'A message' > "$T/out" 2>&1 || fail 'the question as it stands could not be answered'
! grep -q blocked "$FAKEGH/issues/$AC_N/labels" || fail 'the answer left the label on the closed ticket'
ac_ask "$AC_C"; ac_round accept "$AC_N" "$AC_C"; grep -q "^accepted #$AC_N $c12" "$T/out" || fail 'freed, the closed ticket was not accepted'

# B
toy b; ap_pull own "$(printf 'ticket: #%s\n\nCloses #%s\n\nDecisions: none' "$AC_N" "$AC_N")"; P=$AP_P; H=$AP_H; ap_rep "$P" "$H"; ap_ask "$P" "$H"; ac_grade "$H"; printf 'team:blocked\n' > "$FAKEGH/prs/$P/labels"
ap_squash "$P"; [ "$(cat "$FAKEGH/issues/$AC_N/state")" = CLOSED ] || fail 'the fixture: the merge did not close the ticket'
ac_round step; ac_round accept "$AC_N" "$H"; ap_lastp "$P" > "$T/out"; grep -qx 'ticket: not yet' "$T/out" && grep -qx 'ROW-001 question open' "$T/out" || fail 'the label on the own pull request no longer holds a closed ticket'

# the ticket's own ask at that head too: its copy of the not yet says the ticket is closed
ac_ask "$H"; printf 'team:blocked\n' > "$FAKEGH/prs/$P/labels"; ac_round accept "$AC_N" "$H"; [ "$(ac_last | tail -n 1)" = 'this ticket is closed on GitHub and not accepted: ask again here' ] && ac_last | grep -qx 'ticket: not yet' || { ac_last > "$T/out"; fail 'the copy on the ticket does not say it is closed'; }
# closed as not planned with the pull request's ask answered: the commands that do something
echo NOT_PLANNED > "$FAKEGH/issues/$AC_N/reason"; trig; grep -q "^context${TAB}closed${TAB}#$AC_N${TAB}closed on GitHub as not planned, not accepted — /vid:vid-tickets reopen " "$T/L" || fail 'a ticket closed as not planned is told a command that is refused'

# C
toy c; ap_pull own "$(printf 'ticket: #%s\n\nCloses #%s\n\nDecisions: none' "$AC_N" "$AC_N")"; P=$AP_P; H=$AP_H; ap_rep "$P" "$H"; ap_ask "$P" "$H"; ac_grade "$H"; ac_round step; ac_round accept "$AC_N" "$H"
grep -q "^decided #$AC_N $AP_h ticket: accepted" "$T/out" || fail 'it was not accepted at its head'; ap_squash "$P"; trig
[ "$(grep -c "^context${TAB}closed${TAB}#$AC_N${TAB}closed on GitHub, not accepted — /vid:vid-accept-step $AC_N decides it, or records its acceptance\$" "$T/L")" = 1 ] || fail 'a ticket accepted at its pull request is told to be reopened or recorded outside'
ac_round accept "$AC_N"; grep -q "^accepted #$AC_N $(printf %.12s "$AP_M")" "$T/out" || fail 'the command the line names does not record the acceptance'
exit 0
