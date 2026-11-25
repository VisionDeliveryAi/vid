#!/bin/sh
# Purpose: selftest case — in GitHub auto a row with no test is missing, not failing (FB-7 C6), results.sh read and decide.sh on the
# made-up reports. A later head whose report has no case of a row, a faulted protection row, a transition and a regression row: each reads
# `missing`, `evidence missing — no case of it in the results at this commit (a test is found by the row's id in its name)`, says nothing of
# a product failure or the whole harm, counts nothing, waits for its fault instead of lacking its folder, flips no row on record and stays
# unaccepted. The next head that has its cases back keeps the breaks proven before, and one that failed before owes its own. Two engines: a row
# with no case in one is missing; a failure in the other, before or after, fails it by the failure's own words, and a setup: error
# reads `its test could not run`. A journey's regression line by its transitions; a known limit of the one with no case passes it. As
# before: a rule row with no covers: line, no head report, a skipped case, and a tests-first run with no case of it. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; HOME=$T/home; export HOME; mkdir -p "$HOME"
. "$CHECKS/selftest/fixtures/tickets.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
fail() { echo "auto-no-case: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
RS=$CHECKS/results.sh; DS=$CHECKS/decide.sh; rr_project; : > .vid/RUN-STATE.md; printf 'repo: owner/code\nlabels-prefix:\n' > .vid/tw/settings
git init -q --bare "$T/code.git"; gh_fake; mv "$T/bin/gh" "$T/bin/gh-fake"
cat > "$T/bin/gh" <<'G'
#!/bin/sh
case "$1 $2 ${7:-}" in 'pr view labels') cat "$FAKEGH/prs/$3/labels" 2>/dev/null | paste -sd , -; exit 0 ;; 'pr view body') printf 'ticket: #x\n\nDecisions: none\n'; exit 0 ;; esac
exec "$(dirname "$0")/gh-fake" "$@"
G
chmod +x "$T/bin/gh"; for n in 1 2 3 5 7 11; do mkdir -p "$T/gh/issues/$n/comments"; echo OPEN > "$T/gh/issues/$n/state"; done; mkdir -p "$T/gh/prs/4/comments" "$T/gh/prs/9/comments" "$T/gh/prs/12/comments"
NC='evidence missing — no case of it in the results at this commit (a test is found by the row'"'"'s id in its name)'
rd() { sh "$RS" read --ticket "$1" --pr "$2" --head "$3" > "$T/out" 2>&1 || fail 'read exited 1'; cp "$T/out" "$T/ev"; }
dc() { rd "${2:-3}" "${3:-4}" "$1"; RC=0; sh "$DS" decide --ticket "${2:-3}" --pr "${3:-4}" --head "$1" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "decide exited $RC"; }
# has <row> <red> <t3> <fault> [<the whole reason>]: the evidence line; is <row> <the whole line>: the decision's; isnt <words>: nowhere in it
has() { awk -F'\t' -v r="$1" -v a="$2" -v b="$3" -v c="$4" -v w="${5:-}" '$1 == r && $3 == a && $4 == b && $5 == c && (w == "" || index($6, w)) { f = 1 } END { exit !f }' "$T/ev" || { cp "$T/ev" "$T/out"; fail "no evidence line: $*"; }; }
is() { grep -qxF "$1 $2" "$T/out" || fail "no line: $1 $2"; }
isnt() { ! grep -q -- "$1" "$T/out" || fail "a line: $1"; }
head_() { rr_git -C "$T/w" commit -q --allow-empty -m "$1"; X=$(git -C "$T/w" rev-parse HEAD); git -C "$T/w" push -q "$T/p/.vid/code" main; x=$(printf %s "$X" | cut -c1-12); }
# the first head: every row passes, its breaks proven, the ticket accepted; its regression row's state on record
rr_good; A=pr-4-$RR_H12-1; fa() { rr_put "$A" "faults/$1/control.txt" "$2"; rr_put "$A" "faults/$1/cases-alpha.xml" "$(rr_cases "$1=${3:-fail:no}" "$2=pass")"; }
fa ROW-002-T1 ROW-001; fa HOS-001 ROW-001 'fail:two&#10;vid-forbidden-effect: HOS-001'; rr_send "$A"; printf 'row ROW-009 accepted | stand-in: decision\n' > .vid/tw/handed; dc "$RR_H"; is ticket: accepted
# a head with no case of four rows
head_ two; X2=$X; Q=pr-4-$x-1; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s\ncovers: RULE-001 2' "$X")"; rr_put "$Q" cases-alpha.xml "$(rr_cases ROW-002-T2=pass RULE-001=pass)"; rr_send "$Q"; dc "$X"
is ticket: 'not yet'; for r in ROW-001 ROW-002-T1 HOS-001 ROW-009; do is "$r" "$NC"; done; is ROW-002-T2 'accepted'; is RULE-001 accepted
isnt 'product failure'; isnt 'Fix the whole harm'; isnt 'failing'; isnt 'no fault folder'
has ROW-001 red missing n/a 'no case'; has ROW-002-T1 red missing waits 'no case'; has HOS-001 red missing waits 'no case'; has ROW-009 n/a missing n/a 'no case'
! grep -qE '^(ROW-001|ROW-002-T1|HOS-001|ROW-009) ' .vid/decide/counts || fail "a row with no case is counted: $(cat .vid/decide/counts)"
grep -qx 'row ROW-009 accepted | stand-in: decision' .vid/tw/handed || fail "a regression row with no case lost its state: $(grep ROW-009 .vid/tw/handed)"
# the next head has its cases back, with no break run: what was proven before stands, and no break is owed
head_ three; Q=pr-4-$x-1; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s\ncovers: RULE-001 2' "$X")"; rr_put "$Q" cases-alpha.xml "$(rr_cases $RR_ALL)"; rr_send "$Q"; dc "$X"
is HOS-001 accepted; is ROW-002-T1 accepted; is ROW-009 passing; is ticket: accepted
# a row that failed at a head before owes its own break, whatever head with no case came between
head_ four; Q=pr-4-$x-1; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s\ncovers: RULE-001 2' "$X")"; rr_put "$Q" cases-alpha.xml "$(rr_cases ROW-001=pass ROW-002-T1=pass ROW-002-T2=pass HOS-001=fail:two RULE-001=pass ROW-009=pass)"; rr_send "$Q"; dc "$X"; grep -q '^HOS-001 failing, a product failure' "$T/out" || fail 'a failure is not called one'
head_ five; Q=pr-4-$x-1; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s\ncovers: RULE-001 2' "$X")"; rr_put "$Q" cases-alpha.xml "$(rr_cases ROW-001=pass ROW-002-T1=pass ROW-002-T2=pass RULE-001=pass ROW-009=pass)"; rr_send "$Q"; dc "$X"; is HOS-001 "$NC"
head_ six; Q=pr-4-$x-1; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s\ncovers: RULE-001 2' "$X")"; rr_put "$Q" cases-alpha.xml "$(rr_cases $RR_ALL)"; rr_send "$Q"; dc "$X"; is HOS-001 "evidence missing — no fault folder, $Q"
# as before: no covers: line, a skipped case, no head report
head_ seven; Q=pr-4-$x-1; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s' "$X")"; rr_put "$Q" cases-alpha.xml "$(rr_cases ROW-001=skip ROW-002-T1=pass ROW-002-T2=pass HOS-001=pass RULE-001=pass ROW-009=pass)"; rr_send "$Q"; dc "$X"
is RULE-001 "evidence missing — no covers: line, $Q"; grep -q '^RULE-001 '"$Q"'$' .vid/decide/counts || fail 'no covers: line counts nothing'; grep -q '^ROW-001 failing, a product failure' "$T/out" || fail 'a skipped case is not a failure as before'
head_ eight; dc "$X"; is ROW-009 "evidence missing — no head report, pr-4-$x"; isnt 'no case of it'
# two engines, with no earlier decision on record
rm -rf .vid/decide
awk '{ print } /^- primary: alpha$/ { print "- also: beta" }' .vid/tw/out/issue-3.md > .vid/tw/out/issue-11.md; Q=pr-12-$RR_H12-1; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s\ncovers: RULE-001 1' "$RR_H")"
rr_put "$Q" cases-alpha.xml "$(rr_cases ROW-001=fail:not\ saved ROW-002-T1=err:setup:\ no\ door HOS-001=pass RULE-001=pass ROW-009=pass)"; rr_put "$Q" cases-beta.xml "$(rr_cases ROW-002-T2=fail:no\ page HOS-001=pass RULE-001=pass)"; rr_send "$Q"; rd 11 12 "$RR_H"
awk -F'\t' '$1 == "ROW-001" && $4 == "failed" && index($6, "not saved") && !index($6, "no case") { a = 1 } $1 == "ROW-002-T2" && $4 == "failed" && index($6, "no page") && !index($6, "no case") { b = 1 } $1 == "ROW-002-T1" && $4 == "setup" && index($6, "setup: no door") { c = 1 } $1 == "ROW-009" && $4 == "missing" && $6 == "no case in beta" { d = 1 } END { exit !(a && b && c && d) }' "$T/ev" || { cp "$T/ev" "$T/out"; fail 'two engines are not read by the worst'; }
sh "$DS" decide --ticket 11 --pr 12 --head "$RR_H" > "$T/out" 2>&1 || fail 'decide exited 1'; is ROW-009 "$NC"; grep -q '^ROW-001 failing, a product failure — its test failed' "$T/out" && grep -q '^ROW-002-T2 failing, a product failure' "$T/out" && grep -q '^ROW-002-T1 evidence missing — its test could not run' "$T/out" || fail 'a failure in an engine is hidden by no case in another'
rm -rf .vid/decide
# a journey's regression line: the transition with no case; ruled a known limit, it passes. A tests-first run with no case of the rule row changes no other missing's words
sed -e 's/^- ROW-009$/- ROW-002/' -e '/^## Rows$/,/^## Engines$/{/ROW-002/d;}' -e 's/^- ROW-002-T1 (of.*$/- HOS-001: x/' .vid/tw/out/issue-3.md > .vid/tw/out/issue-7.md
rr_put red-7-1 results.txt "$(printf 'by: TM\ncommit: %s\nrows: ROW-001 HOS-001 RULE-001' "$RR_RED")"; rr_put red-7-1 cases-alpha.xml "$(rr_cases ROW-001=fail:no HOS-001=fail:no)"; rr_send red-7-1
Q=pr-9-$RR_H12-1; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s' "$RR_H")"; rr_put "$Q" cases-alpha.xml "$(rr_cases ROW-001=pass ROW-002-T1=pass HOS-001=pass RULE-001=pass)"; rr_send "$Q"; dc "$RR_H" 7 9
has ROW-002 n/a missing n/a 'T2: no case'; is ROW-002 "$NC"; has RULE-001 no-red missing missing 'T2: no case; no covers: line'; grep -q "^RULE-001 evidence missing — no covers: line, $Q" "$T/out" || fail "a rule row's no covers: line reads as no case"
printf '2026-11-09T10:00:00Z\tROW-002-T2\tlimit\t\towner\n' >> .vid/decide/rulings; dc "$RR_H" 7 9; is ROW-002 passing
# the dev side's text, where devagent/ is beside checks/, and the results format's, where docs/ is
[ ! -f "$CHECKS/../devagent/agents/dev-manager.md" ] || { grep -q '^\*\*The reached rows,\*\*.*a line saying `no case of it`, which owes no break' "$CHECKS/../devagent/agents/dev-manager.md" && grep -q '^- `evidence missing`:.*`no case of it`' "$CHECKS/../devagent/agents/dev-manager.md" || fail 'the dev manager is not told what a row with no case owes'; }
[ ! -f "$CHECKS/../docs/RESULTS-FORMAT.md" ] || { ! grep -q 'or when none matches' "$CHECKS/../docs/RESULTS-FORMAT.md" || fail 'the results format calls a row with no case a failure'; }
exit 0
