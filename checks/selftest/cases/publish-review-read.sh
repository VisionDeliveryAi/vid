#!/bin/sh
# Purpose: selftest case — a review on the owner's own pull request is in the read (FB-5 C2). On GitHub manual's toy and the fake gh:
# round-read's `open` line ends with its author; a pull request of the owner's own (manual) or logged as a publish (both modes) gets
# one `pr view` and its `publish <n>` lines, a team's, or a replaced publish, none, and a read with no such pull request makes no call
# more. Each person's newest approval or request for changes stands as GitHub holds it: after the newest commit and the author's or the
# viewer's newest answer it is `after`, else `before`; a dismissed one is none; the comments of others after both are `said`, newest
# first. The words (lib.sh pubwords) follow GitHub's state alone: a standing request first, then an approval, then a comment, else
# "waits for an approval". A failed view is a `publish <n> unread` line, never an `unread` line, and the rest is read. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
HOME=$T/home; export HOME; mkdir -p "$HOME"
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "publish-review-read: $*" >&2; cat "$T/L" >&2 2>/dev/null; cat "$T/err" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t')
mn_project "$T/p"; printf 'mode: tickets\nplan: required\nrun: waiting\n' > .vid/RUN-STATE.md; : > .vid/tw/log
mode() { printf 'setup-answered key=github-mode value="%s" words="the toy" at=2026-11-19T09:00:00Z\n' "$1" >> .vid/plan/setup; }
mode manual
H=0123456789abcdef0123456789abcdef01234567
# pr <n> <author>: an open pull request, its one commit of 20 November; own <n>: the owner's own, in place of the one before ($O)
# push <n> <when>; rev <n> <who> <state> <when> <first line>; com <n> <who> <when> <body>
pr() { d=$FAKEGH/prs/$1; mkdir -p "$d/comments" "$d/cby" "$d/cat"; echo 'a change' > "$d/title"; echo 'ticket: none' > "$d/body"; echo "br-$1" > "$d/head"; echo main > "$d/base"; echo OPEN > "$d/state"; echo false > "$d/draft"; echo "$H" > "$d/headoid"; echo "$2" > "$d/author"; echo 2026-11-20T08:00:00Z > "$d/commits"; }
shut() { echo CLOSED > "$FAKEGH/prs/$1/state"; }
O=''; own() { [ -z "$O" ] || shut "$O"; O=$1; pr "$1" toy; }
push() { echo "$2" >> "$FAKEGH/prs/$1/commits"; }
rev() { printf '%s\t%s\t%s\t%s\n' "$2" "$3" "$4" "$5" >> "$FAKEGH/prs/$1/reviews"; }
com() { d=$FAKEGH/prs/$1; k=$(($(ls "$d/comments" | grep -c . || true) + 1)); printf '%s\n' "$4" > "$d/comments/$k"; echo "$2" > "$d/cby/$k"; echo "$3" > "$d/cat/$k"; }
rd() { : > "$FAKEGH/log"; sh "$CHECKS/github.sh" round-read > "$T/L" 2> "$T/err" || fail "round-read exited $? ($1)"; mkdir -p .vid/round; cp "$T/L" .vid/round/read; }
has() { grep -qxF "$(printf "$1")" "$T/L" || fail "no line: $(printf "$1" | tr '\t' ' ')"; }
views() { grep -c '^gh pr view ' "$FAKEGH/log" || true; }
calls() { wc -l < "$FAKEGH/log" | tr -d ' '; }
words() { w=$(. "$CHECKS/lib.sh"; pubwords .vid/round/read | awk -F'\t' -v n="$1" '$1 == n { print $2 }'); [ "$w" = "$2" ] || fail "the words of #$1 are '$w', not '$2'"; }
# a team's pull request alone: its author on the open line, no view, no call more
pr 30 bo; rd 'first'; rd 'a team pull request'; n0=$(calls)
[ "$(awk -F'\t' '$1 == "open" && $2 == 30 { print $11 }' "$T/L")" = bo ] || fail "the open line does not end with the pull request's author"
[ "$(views)" = 0 ] && ! grep -q "^publish$TB" "$T/L" || fail 'a pull request of the team is read'
# the owner's own, asked to change after its push
own 31; rev 31 ana CHANGES_REQUESTED 2026-11-21T09:00:00Z 'Please drop the second file'; rd 'a request'
has 'publish\t31\tpush\ttoy\t2026-11-20T08:00:00Z'; has 'publish\t31\tstate\tana\tCHANGES_REQUESTED\t2026-11-21T09:00:00Z\tafter'
[ "$(views)" = 1 ] && [ "$(calls)" = $((n0 + 1)) ] || fail 'the owner'"'"'s own pull request is not one call'
! grep -q "^publish${TB}30$TB" "$T/L" || fail 'a pull request of the team is read beside the owner'"'"'s'
words 31 'ana asks for changes'
# pushed after, then answered after, then asked again
push 31 2026-11-22T08:00:00Z; rd 'a push after'; has 'publish\t31\tpush\ttoy\t2026-11-22T08:00:00Z'; has 'publish\t31\tstate\tana\tCHANGES_REQUESTED\t2026-11-21T09:00:00Z\tbefore'
words 31 'changed since ana asked; waits for them to look again'
own 34; rev 34 ana CHANGES_REQUESTED 2026-11-21T09:00:00Z 'Please drop the second file'; com 34 toy 2026-11-22T09:00:00Z 'It is needed, for the second page.'; rd 'an answer after'
words 34 'changed since ana asked; waits for them to look again'; ! grep -q "^publish${TB}34${TB}said" "$T/L" || fail 'the owner'"'"'s own answer is said'
rev 34 ana CHANGES_REQUESTED 2026-11-23T09:00:00Z 'Still'; rd 'asked again'; words 34 'ana asks for changes'
[ "$(grep -c "^publish${TB}34${TB}state${TB}ana" "$T/L")" = 1 ] || fail 'a person has more than the newest state'
# a request stands first, whoever approves; an approval outlives a push and an answer
rev 34 bo APPROVED 2026-11-23T10:00:00Z ''; rd 'another approves'; words 34 'ana asks for changes'
own 35; rev 35 bo APPROVED 2026-11-21T09:00:00Z 'Good'; push 35 2026-11-22T08:00:00Z; com 35 toy 2026-11-22T09:00:00Z 'Thanks'; rd 'approved, then pushed'
has 'publish\t35\tstate\tbo\tAPPROVED\t2026-11-21T09:00:00Z\tbefore'; words 35 'bo approved'
# the same person approves after asking; a comment review takes no state away; a dismissed request is none
own 36; rev 36 ana CHANGES_REQUESTED 2026-11-21T09:00:00Z 'No'; rev 36 ana APPROVED 2026-11-21T10:00:00Z ''; rd 'asked, then approved'; words 36 'ana approved'
rev 36 ana COMMENTED 2026-11-21T11:00:00Z 'One thought for later'; rd 'approved, then commented'; words 36 'ana approved · ana, 2026-11-21T11:00:00Z: One thought for later'
own 37; rev 37 ana APPROVED 2026-11-21T08:00:00Z ''; rev 37 ana DISMISSED 2026-11-21T09:00:00Z 'No'; rd 'dismissed'; ! grep -q "^publish${TB}37${TB}state" "$T/L" || fail 'a dismissed review has a state'; words 37 'waits for an approval'
# comments alone: newest first, those after the newest commit and answer only; a first line decides no word; one with no words says so
own 38; com 38 cy 2026-11-19T09:00:00Z 'Before the push'; com 38 cy 2026-11-21T09:00:00Z 'approved, as far as I can tell'; rev 38 ana COMMENTED 2026-11-21T10:00:00Z ''; rd 'comments'
has 'publish\t38\tsaid\tcy\t2026-11-21T09:00:00Z\tapproved, as far as I can tell'; has 'publish\t38\tsaid\tana\t2026-11-21T10:00:00Z\t'
[ "$(grep "^publish${TB}38${TB}said" "$T/L" | cut -f4 | paste -sd ' ' -)" = 'ana cy' ] || fail 'the comments are not those after the push, newest first'
words 38 'ana commented; cy commented · ana, 2026-11-21T10:00:00Z: (no words of its own) · cy, 2026-11-21T09:00:00Z: approved, as far as I can tell'
# none
own 39; rd 'nothing yet'; words 39 'waits for an approval'
# a publish logged, the team's own by hand: read too, the owner's comments and reviews there being answers; one replaced is not
printf 'spec-published pr=30 export=0123456789ab path=upstream/vid stamp=- at=2026-11-20T09:00:00Z by=hand words="yes, pr=33 too"\nspec-published pr=32 export=0123456789ac path=upstream/vid stamp=- at=2026-11-20T10:00:00Z\nspec-replaced pr=32 by=30 issue=- at=2026-11-20T11:00:00Z\n' > .vid/tw/log
pr 32 dee; pr 33 dee; rev 30 ana CHANGES_REQUESTED 2026-11-21T09:00:00Z 'No'; com 30 toy 2026-11-21T12:00:00Z 'See the second page'; rev 30 toy COMMENTED 2026-11-21T13:00:00Z 'And the third'; rd 'a logged publish'
has 'publish\t30\tpush\tbo\t2026-11-20T08:00:00Z'; has 'publish\t30\tstate\tana\tCHANGES_REQUESTED\t2026-11-21T09:00:00Z\tbefore'; ! grep -q "^publish${TB}30${TB}said" "$T/L" || fail "the owner's words on the team's publish are said as another's"
! grep -qE "^publish$TB(32|33)$TB" "$T/L" || fail 'a replaced publish, or a number in the owner'"'"'s words, is read'; [ "$(views)" = 2 ] || fail 'two pull requests are not two views'
# a view that fails: its own line, no `unread` line, the rest read
echo 'HTTP 502: the read the case makes fail' > "$FAKEGH/prs/30/view-fail"; rd 'a failed view'
grep -q "^publish${TB}30${TB}unread${TB}.*HTTP 502" "$T/L" || fail 'a failed view is not said'; ! grep -q "^unread$TB" "$T/L" || fail 'a failed view made the read a partial one'
grep -q "^publish${TB}39${TB}push" "$T/L" && grep -q "^main$TB" "$T/L" || fail 'a failed view stopped the rest of the read'; words 30 'its reviews could not be read'; words 39 'waits for an approval'
# GitHub auto: the logged one alone, since the dev side may share the account
rm -f "$FAKEGH/prs/30/view-fail"; mode auto; rd 'GitHub auto'; [ "$(views)" = 1 ] && grep -q "^publish${TB}30${TB}push" "$T/L" && ! grep -q "^publish${TB}39$TB" "$T/L" || fail 'GitHub auto does not read the logged publish alone'
# no pull request of either: no call more
shut 39; : > .vid/tw/log; mode manual; rd 'none'; [ "$(views)" = 0 ] && [ "$(calls)" = "$n0" ] || fail 'a read with no such pull request makes a call more'
echo 'publish-review-read: ok'
