#!/bin/sh
# Purpose: selftest case — a ticket of a team of people is accepted on the team's own results (FB-3 A1.1 to A1.3), on GitHub manual's toy
# and the fake gh (fixtures/accept.sh). The ticket's work is one pull request naming a sub-issue of it, merged as a squash, so its head
# is no ancestor of main and the two hold the very same files. The results were made at that head by a person, under
# `pr-<p>-<11 characters of it>-<k>`: two files of any name, suites that share the rows out, one row skipped in one of them; their first
# attempt fails and their second, the newest, alone is read. No red run, no break, no engine's file, no grade of the team's. With ViD's
# own review recorded the ticket is accepted at the commit of main, asked or with no commit named; the evidence prints no split and asks
# for no red. A report of any id git allows, reporting nothing of the ticket, does not matter. The owner's own git settings (colours,
# line numbers, columns, signatures shown) change nothing. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/accept.sh"
fail() { echo "manual-team-results: $*" >&2; cat "$T/out" .vid/results/step-*.txt >&2 2>/dev/null; exit 1; }
ac_project "$T/p" || fail 'the toy could not be made'; K=$(gh_issue 'a part of S02'); gh_sub "$AC_N" "$K"
( cd "$T/dev" && git checkout -q -B work main && echo work > work.txt && git add work.txt && g commit -q -m 'one' && echo more >> work.txt && g commit -q -am 'two' && git push -q -f origin work 2>/dev/null ); W=$(git -C "$T/dev" rev-parse work)
P=$(gh pr create -R owner/code --head work --base main --title work --body "$(printf 'ticket: #%s\n\nDecisions: none' "$K")" | sed 's#.*/##')
( cd "$T/dev" && git checkout -q main && git merge -q --squash work > /dev/null && g commit -q -m 'the work' && git push -q origin main 2>/dev/null ); M=$(git -C "$T/dev" rev-parse main); m12=$(printf %s "$M" | cut -c1-12)
printf '%s\n' "$M" > "$FAKEGH/prs/$P/merge"; echo "$W" > "$FAKEGH/prs/$P/headoid"; echo MERGED > "$FAKEGH/prs/$P/state"
! git -C "$T/dev" merge-base --is-ancestor "$W" "$M" || fail 'the fixture: the head is an ancestor of main'
w11=$(printf %s "$W" | cut -c1-11)
ac_report "pr-$P-$w11-1" 'A. Person' "$W" 'unittest.xml=ROW-001=pass ROW-012=skip' 'jsdom.xml=ROW-012=fail:no_page'
ac_report "pr-$P-$w11-2" 'A. Person' "$W" 'unittest.xml=ROW-001=pass ROW-012=skip ROW-001-again=pass' 'jsdom.xml=ROW-012=pass other=pass'
ac_report nightly 'Another Person' "$M" 'all.xml=a-case-of-nothing=fail:no'; ac_report "ci+web&it's" 'Another Person' "$M" 'all.xml=ROW-001-other=pass'
ac_grade "$M"; ac_ask "$M"; c0=$(ac_comments)
GIT_CONFIG_COUNT=6; k=0; for x in grep.lineNumber=true grep.column=true grep.heading=true color.ui=always log.showSignature=true submodule.recurse=true; do eval "GIT_CONFIG_KEY_$k=\${x%%=*}; GIT_CONFIG_VALUE_$k=\${x#*=}; export GIT_CONFIG_KEY_$k GIT_CONFIG_VALUE_$k"; k=$((k + 1)); done; export GIT_CONFIG_COUNT
ac_round step; grep -qx "decide #$AC_N $M" "$T/out" || fail 'the ask is no decide line'
ac_round accept "$AC_N"; [ "$RC" = 0 ] && grep -qx "decided #$AC_N $m12 ticket: accepted" "$T/out" && grep -qx "accepted #$AC_N $m12" "$T/out" || fail "the ticket was not accepted: exit $RC"
[ "$(ac_comments)" = $((c0 + 1)) ] && [ "$(ac_last | head -n 1)" = "vid: decision $M" ] && ac_last | grep -qx 'ROW-001 accepted' && ac_last | grep -qx 'ROW-012 accepted' || { ac_last > "$T/out"; fail 'the decision is not posted once, each row accepted'; }
grep -q "^step-$AC_N-$m12	$AC_N	$M	$M\$" .vid/decide/merges || fail 'the acceptance is not in merges'
E=.vid/results/step-$AC_N-$m12.txt; grep -qF "report head ci+web&it's read: " "$E" || fail 'a report whose id git allows is not read'
grep -q "^report head pr-$P-$w11-2 read: " "$E" && ! grep -q "pr-$P-$w11-1" "$E" || fail 'the newest attempt alone is not read'
! grep -qE '^(split|report T2|engine )|fault folder' "$E" || fail 'the evidence prints a split, an engine, or asks for a red or a break'
exit 0
