#!/bin/sh
# Purpose: selftest case — results count at their own commit's very files alone (FB-3 A1.1, A1.3), on GitHub manual's toy and the fake gh
# (fixtures/accept.sh). A ticket with no result report: `refused #<n> no results on main`, nothing posted. Its rows passed at a commit
# of main: once main has moved on with other files, an ask at the later commit is answered `not yet`, `no results at this commit`, once, and nothing
# counted (FB-6 A2.2); a call that names no commit decides the newest commit that has results of the ticket's rows, whatever
# later commit holds other results. At a later commit with the very same files the earlier results count. A report at the later commit
# without one of the rows: that row `evidence missing`, the commit it passed at named, `not at this commit`, nothing counted toward a
# hold, however often it is asked. Two ids of one base whose second names another commit are two reports, not two attempts. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/accept.sh"
fail() { echo "manual-team-results-stale: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
ac_project "$T/p" || fail 'the toy could not be made'; c12=$(printf %s "$AC_C" | cut -c1-12); ac_grade "$AC_C"; c0=$(ac_comments)
ac_round accept "$AC_N"; grep -qxF "refused #$AC_N no results on main; accepted outside ViD: /vid:vid-accept-step $AC_N <commit> accepted \"<your words>\"" "$T/out" && [ "$(ac_comments)" = "$c0" ] || fail 'a ticket with no results was not refused so'
ac_report unit-run-7 'A. Person' "$AC_C" 'unit.xml=ROW-001=pass ROW-012=pass'
tk_dev 'main moved on'; L=$(git -C "$T/dev" rev-parse HEAD); l12=$(printf %s "$L" | cut -c1-12); ac_ask "$L"; c0=$(ac_comments)
ac_round accept "$AC_N" "$L"; grep -qx "decided #$AC_N $l12 ticket: not yet — no results" "$T/out" && [ "$(ac_comments)" = $((c0 + 1)) ] && [ ! -s .vid/decide/state ] || fail 'results of an earlier commit were counted at a later one with other files, or the ask was not answered once'
ac_last > "$T/out"; grep -q '^no results at this commit — ' "$T/out" || fail 'the answer does not say there are no results'; ac_round step; ! grep -q "^decide #$AC_N $L" "$T/out" || fail 'the answered ask is still owed'; ac_ask "$L"
# a report there of other things: not the ticket's newest commit
ac_report other-9 'A. Person' "$L" 'e2e.xml=something-else=pass'; sh "$CHECKS/github.sh" results-fetch > /dev/null 2>&1 || fail 'results-fetch failed'
[ "$(sh "$CHECKS/results.sh" at "$AC_N")" = "$AC_C" ] || { sh "$CHECKS/results.sh" at "$AC_N" > "$T/out" 2>&1; fail 'with no commit named, the newest commit with results of its rows is not the one'; }
# one row missing at the later commit: where it passed is named, nothing is counted, twice
ac_report unit-run-8 'A. Person' "$L" 'unit.xml=ROW-001=pass'; for x in 1 2 3; do [ $x = 1 ] || ac_ask "$L"; ac_round accept "$AC_N" "$L"
  ac_last > "$T/out"; grep -qx "ROW-012 evidence missing — no case of it in the results at this commit; passed at $c12, not at this commit (a test is found by the row's id in its name)" "$T/out" && grep -qx 'ticket: not yet' "$T/out" && grep -qx 'ROW-001 accepted' "$T/out" || fail "the row passed at an earlier commit alone ($x)"; done
! grep -q '^ROW-012 ' .vid/decide/counts && ! grep -rq 'held ROW-012' .vid/RUN-STATE.md || { cp .vid/decide/counts "$T/out"; fail 'a row with no case was counted toward a hold'; }
# a later commit with the very same files as the first: its results count there, and the ticket is accepted there
( cd "$T/dev" && git checkout -q "$AC_C" -- . && git add -A && g commit -q -m 'back to the same files' && git push -q origin main 2>/dev/null ); S=$(git -C "$T/dev" rev-parse HEAD)
[ "$(git -C "$T/dev" rev-parse "$S^{tree}")" = "$(git -C "$T/dev" rev-parse "$AC_C^{tree}")" ] || fail 'the fixture: the two commits do not hold the same files'
ac_round accept "$AC_N" "$S"; grep -qx "accepted #$AC_N $(printf %s "$S" | cut -c1-12)" "$T/out" || fail 'a commit with the very same files was not accepted on its results'
# an id that ends in a commit's characters is an attempt at it only when that is the commit it reports
tk_dev 'X'; X=$(git -C "$T/dev" rev-parse HEAD); x7=$(printf %s "$X" | cut -c1-7); tk_dev 'Y'; Y=$(git -C "$T/dev" rev-parse HEAD); ac_report "ci-$x7-1" 'A. Person' "$X" 'u.xml=ROW-001=pass'; ac_report "ci-$x7-2" 'A. Person' "$Y" 'u.xml=ROW-001=pass'
sh "$CHECKS/github.sh" results-fetch > /dev/null 2>&1 || fail 'results-fetch failed'
[ "$(sh "$CHECKS/results.sh" at "$AC_N" "$X")" = "ci-$x7-1" ] && [ "$(sh "$CHECKS/results.sh" at "$AC_N" "$Y")" = "ci-$x7-2" ] || { sh "$CHECKS/results.sh" at "$AC_N" "$X" > "$T/out" 2>&1; fail 'a report of another commit hides the one whose id it shares'; }
ac_report "ci-$x7-3" 'A. Person' "$X" 'u.xml=ROW-001=pass'; sh "$CHECKS/github.sh" results-fetch > /dev/null 2>&1 || fail 'results-fetch failed'; [ "$(sh "$CHECKS/results.sh" at "$AC_N" "$X")" = "ci-$x7-3" ] || fail 'the newest attempt alone is not read'
! git --git-dir=.vid/code cat-file -e "$S^{tree}" 2>/dev/null || fail "a tree of the team's code is in .vid/code"
exit 0
