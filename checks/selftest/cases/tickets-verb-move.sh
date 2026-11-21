#!/bin/sh
# Purpose: selftest case — K1's one path, its move part (GM-4 K1, J1; K11's step 6, queue lane): /vid next's publish, amend,
# withdraw and reopen moves run the vid-tickets skill's entries, `github.sh tw-hand`, and next-move.sh holds no copy of the publish
# order (no export, sync, read, handovers, admission, write or post of its own, no preparation) and no `post` entry. On two copies
# of the form fixture's toy in GitHub manual: in one, /vid next's call names `publish S01 "<words>"`; in the other the owner calls
# `github.sh tw-hand publish S01 --words "<words>"` directly, between vid-connect's start and end, as the vid-tickets skill has a
# direct call do (the call's stage and the lock its start's, no stage put in by hand), and the skill says so. Both post the same ticket: the same title, labels and body, and the
# same log line, once each toy's own commits, hashes and times are set aside. A reopen move the call's lines do not list is not
# done, and nothing is posted. A move the call does not know is refused naming each move's skill. Env: CHECKS.
set -eu
unset VID_CALLER CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T0=$(mktemp -d); trap 'rm -rf "$T0"' EXIT; T=$T0/x; mkdir -p "$T"
. "$CHECKS/selftest/fixtures/form.sh"
fail() { echo "tickets-verb-move: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
NM=$CHECKS/next-move.sh; WD='Yes, publish the skeleton'
# no copy of the order in next-move.sh, and no post entry: every ticket goes out through tw-hand
for w in 'github.sh" spec-export' 'github.sh" tw-sync' 'github.sh" tw-handovers' 'plan.sh" start' 'writer.sh" write' 'github.sh" tw-post' 'github.sh" tw-close' 'prep()'; do
  ! grep -q "$w" "$NM" || fail "next-move.sh still runs a step of the ticket path itself: $w"; done
grep -q 'github.sh" tw-hand' "$NM" || fail 'next-move.sh does not post through github.sh tw-hand'
cd "$T"
RC=0; sh "$NM" post publish S02 'Yes' > "$T/out" 2>&1 || RC=$?; [ "$RC" = 2 ] || fail "next-move.sh post is still an entry (exit $RC, not a usage error)"
RC=0; sh "$NM" call nosuch S01 'Yes' > "$T/out" 2>&1 || RC=$?
[ "$RC" = 2 ] && grep -q 'publish, amend, withdraw and reopen (vid-tickets)' "$T/out" || fail "a move it does not know is not refused naming each move's skill (exit $RC)"
# norm <file>: each toy's own commits, hashes and times set aside
norm() { sed -E 's/[0-9a-f]{7,40}/H/g; s/[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]{8}Z/D/g' "$1"; }
# the issue a toy posted: its title, labels and body, set aside as norm does
issue() { { cat "$FAKEGH/issues/$1/title"; cat "$FAKEGH/issues/$1/labels" 2>/dev/null; cat "$FAKEGH/issues/$1/body"; } > "$T/is"; norm "$T/is"; }
logl() { awk '$1 == "published" { print }' .vid/tw/log > "$T/ll"; norm "$T/ll"; }
stg() { printf 'stage name=replan state=%s session=%s%s at=%s\n' "$1" "${CLAUDE_CODE_SESSION_ID:-hand}" "$2" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> .vid/metrics-events; }
# the move: /vid next's call, inside the call's stage and lock, after its read
T=$T0/move; mkdir -p "$T"; fm_toy "$T/toy" || fail 'the first toy could not be made'
printf 'stage name=plan state=end session=S1 at=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> .vid/metrics-events
CLAUDE_CODE_SESSION_ID=tickets-verb-move; export CLAUDE_CODE_SESSION_ID
sh "$CHECKS/github.sh" lock-take > "$T/out" 2>&1 || fail 'the lock could not be taken'
HOME=$T/home; export HOME; mkdir -p "$HOME"; FAKEGH_CREATED_NOW=1; export FAKEGH_CREATED_NOW
call() { stg start ' records=29'; sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'; RC=0; sh "$NM" call "$@" > "$T/out" 2>&1 || RC=$?; stg end ''; }
call; [ "$RC" = 0 ] || fail "the call with no move exited $RC"
call publish S01 "$WD"; [ "$RC" = 0 ] && grep -q '^done publish S01' "$T/out" || fail "the publish move did not publish S01 (exit $RC)"
N1=$(awk '$1 == "published" { print $2 }' .vid/tw/log | tail -n 1); [ -n "$N1" ] || fail 'no ticket is logged'
grep -q "^published $N1 kind=skeleton step=S01 .* words=\"$WD\"\$" .vid/tw/log || fail "the move's ticket is not logged with the owner's words"
issue "$N1" > "$T0/move.issue"; logl > "$T0/move.log"
# a reopen the lines do not list: not done, nothing posted
gh_wclear; call reopen "#$N1" 'Open it again'; [ "$RC" = 0 ] || fail "the call with an unlisted reopen exited $RC"
grep -q "^not done reopen #$N1: " "$T/out" || fail 'a reopen move the lines do not list was done, or not answered'
! grep -qE '^owner/code (issue|comment)' "$FAKEGH/writes" || { cp "$FAKEGH/writes" "$T/out"; fail 'an unlisted reopen posted'; }
unset CLAUDE_CODE_SESSION_ID
# the owner's direct call: tw-hand publish, on a second toy, between vid-connect's start and end (GM-4 K1, S0: every skill also the
# owner's command), as the vid-tickets skill has it; in /vid run's conversation the entry alone, the run's lock left held
SK=$CHECKS/../skills/vid-tickets/SKILL.md
if [ -f "$SK" ]; then awk '/^## The owner'"'"'s command/ { s = 1; next } /^## / { s = 0 } s' "$SK" > "$T/sk"
  # the start through the plugin's own copy (it refreshes ./checks/ first), the end the project's copy
  grep -qF 'sh "${CLAUDE_PLUGIN_ROOT}/checks/connect.sh" start' "$T/sk" && grep -qF 'sh checks/connect.sh end' "$T/sk" || fail "vid-tickets' command does not run a direct call between vid-connect's start and end"
  # in /vid run's conversation (the session holds the run's lock) the entry alone, tw-hand borrowing the lock (tw-hand's case proves it stays held)
  grep "/vid run's conversation" "$T/sk" | grep -q 'the entry alone' && grep "/vid run's conversation" "$T/sk" | grep -q 'leaves it held' || fail "vid-tickets' command does not run the entry alone in /vid run's conversation, the run's lock left held"; fi
T=$T0/hand; mkdir -p "$T"; fm_toy "$T/toy" || fail 'the second toy could not be made'
printf 'stage name=plan state=end session=S1 at=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> .vid/metrics-events
HOME=$T/home; export HOME; mkdir -p "$HOME"
sh "$CHECKS/connect.sh" start > "$T/out" 2>&1 || fail "vid-connect's start failed before the direct call"
RC=0; sh "$CHECKS/github.sh" tw-hand publish S01 --words "$WD" > "$T/out" 2>&1 || RC=$?
cp "$T/out" "$T/hand.out"; sh "$CHECKS/connect.sh" end > "$T/out" 2>&1 || fail "vid-connect's end failed after the direct call"; cp "$T/hand.out" "$T/out"
[ "$RC" = 0 ] || fail "tw-hand publish S01 exited $RC"
N2=$(awk '$1 == "published" { print $2 }' .vid/tw/log | tail -n 1); [ -n "$N2" ] || fail 'tw-hand logged no ticket'
issue "$N2" > "$T0/hand.issue"; logl > "$T0/hand.log"
cmp -s "$T0/move.issue" "$T0/hand.issue" || { diff "$T0/hand.issue" "$T0/move.issue" > "$T/out" || :; fail 'the move and tw-hand publish posted different tickets'; }
cmp -s "$T0/move.log" "$T0/hand.log" || { diff "$T0/hand.log" "$T0/move.log" > "$T/out" || :; fail 'the move and tw-hand publish logged different lines'; }
exit 0
