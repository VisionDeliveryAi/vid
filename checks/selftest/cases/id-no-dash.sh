#!/bin/sh
# Purpose: selftest case — a row's id without its dash in a test's name (FB-6 A2.1), on GitHub manual's toy and the fake gh (fixtures/accept.sh).
# In GitHub manual `test_ROW001_x` is of ROW-001, passing or failing, a transition `ROW004-T1` of ROW-004-T1, a regression row too; `ROW0011`, `xROW001` and
# `ROW001x` are not; the review's list of cases and a close chunk's rest read it; the form ids are found by stays as it was. In GitHub auto it is not read,
# and the same reports read byte for byte as before. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/accept.sh"
fail() { echo "id-no-dash: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TAB=$(printf '\t')
ac_project "$T/p" || fail 'the toy could not be made'
{ mn_ticket "$AC_N" S02 step ROW-001 ROW-002 ROW-004 ROW-006 ROW-010 ROW-012; printf '\n## Engines\n\n- primary: alpha\n\n## Regression rows\n\n- ROW-005\n'; } > ".vid/tw/out/issue-$AC_N.md"; printf 'published %s kind=step step=S02 rows=ROW-001,ROW-002,ROW-004,ROW-006,ROW-010,ROW-012 at=2026-11-18T09:00:00Z\n' "$AC_N" >> .vid/tw/log
ac_report unit-1 'A. Person' "$AC_C" 'u.xml=test_ROW001_saves=pass ROW002=fail:no_digest test_ROW004_T1=pass ROW004-T2=pass test.ROW004.T3=pass test_ROW0061_x=pass xROW010_y=pass ROW012x=pass suite.ROW005_list=pass'
sh "$CHECKS/github.sh" results-fetch > /dev/null 2>&1 || fail 'results-fetch failed'; sh "$CHECKS/round.sh" read > "$T/out" 2>&1 || fail 'the read failed'
sh "$CHECKS/results.sh" read --ticket "$AC_N" --at "$AC_C" > "$T/out" 2>&1 || fail 'the reports could not be read'
st() { awk -F'\t' -v r="$1" 'NF == 6 && $1 == r { print $4; exit }' "$T/out"; }
for x in ROW-001=passed ROW-002=failed ROW-004-T1=passed ROW-004-T2=passed ROW-004-T3=passed ROW-006=missing ROW-010=missing ROW-012=missing ROW-005=passed; do [ "$(st "${x%=*}")" = "${x#*=}" ] || fail "${x%=*} reads $(st "${x%=*}"), not ${x#*=}"; done
[ "$(sh "$CHECKS/results.sh" at "$AC_N")" = "$AC_C" ] || fail 'the newest commit with a result of its rows is not found by such a name'
ac_grade "$AC_C"; ac_round accept "$AC_N" "$AC_C"; ac_last > "$T/out"; grep -q '^ROW-002 failing, a product failure' "$T/out" && grep -qx 'ROW-001 accepted' "$T/out" || fail 'the decision does not read such names'
grep -qx "ROW-006 evidence missing — no case of it in the results at this commit (a test is found by the row's id in its name)" "$T/out" || fail 'a row with no case is not said so'
# the review's list
CLAUDE_PLUGIN_ROOT=$(cd "$CHECKS/.." && pwd); export CLAUDE_PLUGIN_ROOT
if [ -f "$CLAUDE_PLUGIN_ROOT/skills/vid-accept-step/passes/review.md" ]; then ac_unit unit "$(printf 'ticket: #%s\n\nDecisions: none' "$AC_N")"; rm -rf .vid/decide/review; ac_report unit-2 'A. Person' "$AC_M" 'u.xml=test_ROW001_saves=pass test_ROW0012_x=pass'
  ac_round step; sh "$CHECKS/review.sh" prepare "step-$AC_N" "$(printf %.12s "$AC_M")" > "$T/out" 2>&1 && cp ".vid/round/review/step-$AC_N-$(printf %.12s "$AC_M")/brief.md" "$T/out" && grep -qx -- '- unit-2 u.xml: test_ROW001_saves: passed' "$T/out" && ! grep -q 'ROW0012' "$T/out" || fail "the review's list does not hold such a name alone"; fi
# a close chunk
mkdir -p .vid/decide/close/S02/1; printf 'issue\t900\ncommit\t%s\nasked\t2026-11-19T09:00:00Z\nchunk\tp1c1\talpha\tROW-001\nchunk\tp1cx\talpha\trest\n' "$AC_C" > .vid/decide/close/S02/1/ask
for c in p1c1 p1cx; do rr_put "req-900-$c-1" results.txt "$(printf 'by: A. Person\ncommit: %s' "$AC_C")"; done; rr_put req-900-p1c1-1 all.xml "$(rr_cases test_ROW001_saves=pass)"; rr_put req-900-p1cx-1 all.xml "$(rr_cases test_ROW006_y=pass no_id_here=pass)"; for c in p1c1 p1cx; do ac_send "req-900-$c-1"; done
sh "$CHECKS/github.sh" results-fetch > /dev/null 2>&1 || fail 'results-fetch failed'; sh "$CHECKS/results.sh" close --step S02 > "$T/out" 2>&1 || fail 'the close could not be read'
grep -q "^row${TAB}p1c1${TAB}alpha${TAB}ROW-001${TAB}passed" "$T/out" && ! grep -q 'unmatched.*ROW006' "$T/out" || fail 'a close chunk does not read such a name'
# GitHub auto: as before
hm() { sh -c 'HERE=$CHECKS; . "$CHECKS/lib.sh"; awk "$(hitf)"'"' BEGIN { print hit(norm(\"$1\"), \"$2\") }'" 2>/dev/null; }
[ "$(hm test_ROW001_x ROW-001)" = 1 ] && [ "$(hm test_ROW_001_x ROW-001)" = 1 ] && [ "$(hm testROW001 ROW-001)" = 0 ] || fail 'in GitHub manual the matching is not the one'
printf 'setup-answered key=github-mode value="auto" words="back to auto" at=2026-11-20T09:00:00Z\n' >> .vid/plan/setup
( cd "$T/dev" && git checkout -q -B au main && g commit -q --allow-empty -m au && git push -q -f origin au 2>/dev/null && git checkout -q main ); H=$(git -C "$T/dev" rev-parse au); P=$(gh pr create -R owner/code --head au --base main --title t --body "ticket: #$AC_N" | sed 's#.*/##')
_i=pr-$P-$(printf %.12s "$H")-1; rr_put "$_i" results.txt "$(printf 'by: TM\ncommit: %s\nengines: alpha' "$H")"; rr_put "$_i" cases-alpha.xml "$(rr_cases ROW001=pass ROW-002=pass)"; ac_send "$_i"; sh "$CHECKS/github.sh" results-fetch > /dev/null 2>&1 || fail 'results-fetch failed in auto'
sh "$CHECKS/results.sh" read --ticket "$AC_N" --pr "$P" --head "$H" > "$T/out" 2>&1 || fail 'the read in auto failed'; [ "$(st ROW-001)" = failed ] && grep -q '^ROW-001	.*no case' "$T/out" && [ "$(st ROW-002)" = passed ] || fail "in GitHub auto the evidence reads a name without its dash"
[ "$(hm test_ROW001_x ROW-001)" = 0 ] && [ "$(hm test_ROW_001_x ROW-001)" = 1 ] && [ "$(hm ROW-001-T1 ROW-001)" = 1 ] && [ "$(hm ROW-0012 ROW-001)" = 0 ] || fail 'in GitHub auto a name without its dash is read'
exit 0
