#!/bin/sh
# Purpose: selftest case — the owner's list as text, where there is no panel (FB-5 A1, S5). `queue.sh backlog` prints My to do, Waiting,
# Changed and The rest, numbered 1 to 4 with their counts, each to-do with its number, its ids, what to do, what it is, its question,
# its choices, the one ViD would choose and why, its message and what follows; each waiting line with who and since when; the rest's
# lines by kind; the call's counts, each with what it means; then everything ViD holds, each open item in ViD's words with its id and where it is; then `next:`; then, in GitHub
# manual, what next-page.sh prints as text, and nothing of it when that fails. With no sort every item is `not sorted yet` and nothing
# is said to be the owner's, or not; an empty list says nothing is yours now. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"; . "$CHECKS/selftest/fixtures/sort.sh"
fail() { echo "backlog-text: $*" >&2; cat "$T/out" >&2 2>/dev/null; cat .vid/decide/queue/sorted >&2 2>/dev/null; exit 1; }
so_toy "$T/p"
mkdir "$T/c"; cp "$CHECKS"/*.sh "$T/c/"; printf '#!/bin/sh\n[ "$1" = text ] || exit 0\necho "5 The plan"\n' > "$T/c/next-page.sh"; QS=$T/c/queue.sh
bl() { so_ok backlog; cp "$T/out" "$T/bl"; }
at() { grep -nF -- "$1" "$T/bl" | head -n 1 | cut -d: -f1; }
has() { for x; do grep -qF -- "$x" "$T/bl" || fail "the text lacks: $x"; done; }
bl; [ "$(grep '^[1-5] ' "$T/bl" | paste -sd '|' -)" = '1 My to do: nothing is yours now|2 Waiting: none|3 Changed: none|4 The rest|5 The plan' ] || fail 'an empty list is not the four sections and the plan'
for i in 1 2 3 4 5 6 7 8; do so_ok backlog add "item $i"; done; so_ok backlog set B8 --state aside
bl; grep -qx '1 My to do: not sorted yet' "$T/bl" && ! grep -q 'nothing is yours' "$T/bl" || fail 'with no sort the text says what is the owner'"'"'s'
[ "$(grep -c "^B[0-9]$TB.*${TB}not sorted yet\$" "$T/bl")" = 8 ] || fail 'with no sort an item is not held as not sorted yet'
{ so_todo B1,B2 'Pick the day' | sed 's/^what/new Ann, Monday\nwhat/'; so_todo B3 'Send it' | grep -v '^choice\|^choose' | sed 's/^ask .*/ask Send this?\nmessage Hello, the page is ready./'; printf 'line waiting B4\nwho Ann\nwhat the logo\nsince Monday\n\nline changed -\nwhat the bank wrote\n\nline vid B5\nwhat ViD reads the report\n\nline later B6\nwhat the fair\nthen in spring\n\nline team -\n\nline suggested B7\nwhat a shorter list\n\nline left-out B8\nwhat a second logo, no one asked\n'; } | sed '/^line team -$/d' > "$T/s"; so_ok sort "$T/s"
so_ok backlog add 'item 9'; bl
has '1 My to do (2)' '1.1 Pick the day' 'Say which' 'The team waits for this.' 'Which one?' 'The first' 'The second' 'ViD would choose' 'it is the smaller change' 'The team is told.' 'Ann, Monday' '1.2 Send it' 'Hello, the page is ready.' '2 Waiting (1)' 'the logo' 'since Monday' '3 Changed (1)' 'the bank wrote' '4 The rest' 'ViD reads the report' 'in spring: the fair' 'a shorter list' 'a second logo, no one asked' 'not sorted yet: 1' 'Everything ViD holds (9)'
grep '^1\.1 ' "$T/bl" | grep -q 'B1, B2' && grep '^1\.2 ' "$T/bl" | grep -q 'B3' || fail 'a to-do does not say the ids it covers'
o=''; for x in '1 My to do' '1.1 Pick' '1.2 Send' '2 Waiting' '3 Changed' '4 The rest' 'Everything ViD holds' 'next: 1.1 · Pick the day' '5 The plan'; do n=$(at "$x"); [ -n "$n" ] || fail "the text lacks: $x"; o="$o $n"; done
[ "$(printf '%s\n' $o | sort -n | paste -sd ' ' -)" = "${o# }" ] || fail "the sections are out of order: $o"
w() { awk -F'\t' -v i="$1" '$1 == i { print $NF; exit }' "$T/bl"; }
[ "$(w B1)|$(w B2)|$(w B3)|$(w B4)|$(w B5)|$(w B6)|$(w B7)|$(w B8)|$(w B9)" = '1.1|1.1|1.2|Waiting|The rest|The rest|The rest|The rest|not sorted yet' ] || fail "an item's section is not said: $(w B1)|$(w B2)|$(w B3)|$(w B4)|$(w B5)|$(w B6)|$(w B7)|$(w B8)|$(w B9)"
awk -F'\t' '$1 == "B8" && $2 == "aside" && $4 == "item 8" { f = 1 } END { exit !f }' "$T/bl" || fail 'what ViD holds is not in its own words, with its state'
# the call's counts, as it kept them
mkdir -p .vid/next; printf 'count\ttotal\t5\ncount\tto-place\t0\ncount\tadded\t3\ncount\tunpublished\t2\n' > .vid/next/lines; bl; has 'tests not yet with the team: 5 (3 new in the spec, 2 in no ticket yet)'
# the plan's text fails: the list is said all the same
printf '#!/bin/sh\necho "half a pl"; exit 1\n' > "$T/c/next-page.sh"; bl; ! grep -q 'half a pl' "$T/bl" && tail -n 1 "$T/bl" | grep -q '^next: 1\.1' || fail 'a plan that could not be said is said in part, or takes the list with it'
echo 'backlog-text: ok'
