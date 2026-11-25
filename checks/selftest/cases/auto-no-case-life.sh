#!/bin/sh
# Purpose: selftest case — what a row with no test keeps and owes from head to head, in GitHub auto (FB-7 C6), results.sh read and
# decide.sh on the made-up reports. A row accepted by the owner's ruling whose test is gone reads not yet for want of a case, counts
# nothing, keeps the ruling and is accepted by it at the next head that passes. A row that failed, was fixed and proven, had no case and
# passes again owes no second break; one that could not run, or failed, after its break was proven, then had no case, owes its break at
# its next head that passes. A rule row with neither a case nor its covers: line keeps the words and the count of its covers: line. Each
# scene is told; the case fails if any does. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; HOME=$T/home; export HOME; mkdir -p "$HOME"; BAD=''
. "$CHECKS/selftest/fixtures/tickets.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
fail() { echo "auto-no-case-life: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bad() { echo "auto-no-case-life: $* — $(grep '^HOS-001 \|^RULE-001 ' "$T/out" | paste -sd ';' -)" >&2; BAD=1; }
RS=$CHECKS/results.sh; DS=$CHECKS/decide.sh; rr_project; : > .vid/RUN-STATE.md; printf 'repo: owner/code\nlabels-prefix:\n' > .vid/tw/settings
git init -q --bare "$T/code.git"; gh_fake; mv "$T/bin/gh" "$T/bin/gh-fake"
cat > "$T/bin/gh" <<'G'
#!/bin/sh
case "$1 $2 ${7:-}" in 'pr view labels') cat "$FAKEGH/prs/$3/labels" 2>/dev/null | paste -sd , -; exit 0 ;; 'pr view body') printf 'ticket: #x\n\nDecisions: none\n'; exit 0 ;; esac
exec "$(dirname "$0")/gh-fake" "$@"
G
chmod +x "$T/bin/gh"; mkdir -p "$T/gh/issues/3/comments" "$T/gh/prs/4/comments"; echo OPEN > "$T/gh/issues/3/state"; rr_good
NC='evidence missing — no case of it in the results at this commit (a test is found by the row'"'"'s id in its name)'; FB='no fault folder'
OK='ROW-001=pass ROW-002-T1=pass ROW-002-T2=pass RULE-001=pass ROW-009=pass'; VF='fail:two&#10;vid-forbidden-effect: HOS-001'; CV='covers: RULE-001 2'
# at <case>…: a new head whose report holds them; brk: with HOS-001's break proven; dc: read and decided, HOS-001's line after its id in L
at() { rr_git -C "$T/w" commit -q --allow-empty -m "$*"; X=$(git -C "$T/w" rev-parse HEAD); git -C "$T/w" push -q "$T/p/.vid/code" main; Q=pr-4-$(printf %s "$X" | cut -c1-12)-1; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s\n%s' "$X" "$CV")"; rr_put "$Q" cases-alpha.xml "$(rr_cases "$@")"; }
brk() { rr_put "$Q" faults/HOS-001/control.txt ROW-001; rr_put "$Q" faults/HOS-001/cases-alpha.xml "$(rr_cases "HOS-001=$VF" ROW-001=pass)"; }
dc() { rr_send "$Q"; sh "$RS" read --ticket 3 --pr 4 --head "$X" > "$T/out" 2>&1 || fail 'read exited 1'; sh "$DS" decide --ticket 3 --pr 4 --head "$X" > "$T/out" 2>&1 || fail 'decide exited 1'; L=$(sed -n 's/^HOS-001 //p' "$T/out"); }
pass() { at $OK HOS-001=pass; }; none() { at $OK; }; afresh() { rm -rf .vid/decide; }
hos() { grep -c '^HOS-001 ' .vid/decide/counts || true; }
# a row accepted by ruling, then its test is gone
pass; dc; pass; dc; sh "$DS" rule HOS-001 accept --by owner > "$T/out" 2>&1 || fail 'the ruling was refused'; pass; dc; [ "$L" = 'accepted by ruling' ] || fail 'the ruling does not stand'
none; dc; [ "$L" = "$NC" ] && [ "$(sed -n 2p "$T/out")" = 'ticket: not yet' ] || bad 'a ruling accepts a row with no case'
[ "$(hos)" = 0 ] && [ "$(awk -F'\t' '$2 == "HOS-001" { v = $3 } END { print v }' .vid/decide/rulings)" = accept ] || bad 'a row with no case is counted, or its ruling undone'
pass; dc; [ "$L" = 'accepted by ruling' ] || bad 'the ruling is gone at the next head that passes'
# failed, fixed and proven, no case, back
afresh; at $OK HOS-001=fail:x; brk; dc; pass; brk; dc; [ "$L" = accepted ] || fail 'a proven break does not accept the row'
none; dc; [ "$L" = "$NC" ] || bad 'a row with no case does not say so'; pass; dc; [ "$L" = accepted ] || bad 'a break proven before a head with no case is asked again'
# proven, could not run, no case (twice), back: its break is owed
afresh; pass; brk; dc; at $OK HOS-001=err:setup:\ no; dc; none; dc; none; dc; [ "$L" = "$NC" ] || bad 'a row with no case twice does not say so'
pass; dc; [ "${L#held — }" = "evidence missing — $FB, $Q" ] || bad 'a break owed after a test that could not run is lost over a head with no case'
# proven, failed, no case, back: owed
afresh; pass; brk; dc; at $OK HOS-001=fail:x; dc; none; dc; pass; dc; [ "$L" = "evidence missing — $FB, $Q" ] || bad 'a break owed after a failure is lost over a head with no case'
# a rule row with neither a case nor its covers: line
afresh; CV=''; at ROW-001=pass ROW-002-T1=pass ROW-002-T2=pass HOS-001=pass ROW-009=pass; brk; dc; grep -qxF "RULE-001 evidence missing — no covers: line, $Q" "$T/out" || bad 'a missing covers: line is not told beside no case'
grep -qx "RULE-001 $Q" .vid/decide/counts || bad 'a missing covers: line beside no case counts nothing'
[ ! -f "$CHECKS/../devagent/agents/dev-manager.md" ] || grep -q '^\*\*The reached rows,\*\*.*a row that failed, or could not run, before its heads with no case owes its break at its next head that passes' "$CHECKS/../devagent/agents/dev-manager.md" || bad 'the dev manager is not told what a row owes after its heads with no case'
[ -z "$BAD" ]
