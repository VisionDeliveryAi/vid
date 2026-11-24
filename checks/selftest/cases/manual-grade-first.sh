#!/bin/sh
# Purpose: selftest case — a ticket has one grade, ViD's own review (GM-4 E1's rule as FB-3 A1.4 changes it), on GitHub manual's toy and
# the fake gh (fixtures/accept.sh). Ticket one: an ask off main, answered `not on main`, then an ask at A with the review recorded at A:
# the decision at A reads it. Ticket two: the team asks at A, then at B, and sends a grade and a sort of its own at B: neither is read,
# and the review is due at B; with the review recorded at A, the decision at B reads that one and accepts, and no second review is
# asked at a later commit. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/accept.sh"
fail() { echo "manual-grade-first: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
ac_project "$T/p" || fail 'the toy could not be made'
# ticket one: an ask off main first, then at A with its review
ac_ask "$AC_OFF"; ac_round accept "$AC_N" "$AC_OFF"; ac_last | grep -qx "not on main — $AC_OFF" || { ac_last > "$T/out"; fail 'the ask off main was not answered not on main'; }
ac_red; ac_head "$AC_C"; ac_grade "$AC_C"; ac_ask "$AC_C"; ac_round accept "$AC_N"; [ "$RC" = 0 ] || fail "accept at A exited $RC"
grep -q "^report grade grade-step-$AC_N-$(printf %s "$AC_C" | cut -c1-12)-1 read" ".vid/results/step-$AC_N-$(printf %s "$AC_C" | cut -c1-12).txt" || { cp ".vid/results/step-$AC_N-$(printf %s "$AC_C" | cut -c1-12).txt" "$T/out"; fail 'after an ask off main, the first ask on main did not have its review read'; }
# ticket two: asks at A and B before any decision, a grade and a sort of the team's at B alone
N2=$(gh_issue 'Step S03'); { mn_ticket "$N2" S03 step ROW-001 ROW-012; printf '\n## Engines\n\n- primary: alpha\n'; } > ".vid/tw/out/issue-$N2.md"
printf 'published %s kind=step step=S03 rows=ROW-001,ROW-012 at=2026-11-18T09:00:00Z\n' "$N2" >> .vid/tw/log; AC_N=$N2
ac_red; ac_head "$AC_C"; ac_ask "$AC_C"
tk_dev 'B'; B=$(git -C "$T/dev" rev-parse HEAD); b12=$(printf %s "$B" | cut -c1-12); ac_head "$B"; ac_ask "$B"
rr_put "grade-step-$N2-$b12-1" grade.txt "$(printf 'by: GR\ncommit: %s\nROW-001 kept — seen\nROW-012 kept — seen' "$B")"; ac_send "grade-step-$N2-$b12-1"
rr_put "sort-step-$N2-$b12-1" sorted.txt "$(printf 'by: SR\ncommit: %s\nROW-001 note it — theirs' "$B")"; ac_send "sort-step-$N2-$b12-1"; c0=$(ac_comments)
ac_round accept "$AC_N"; [ "$RC" = 0 ] || fail "accept exited $RC"; grep -qx "review #$AC_N $b12" "$T/out" && [ "$(ac_comments)" = "$c0" ] || fail "a grade of the team's was taken for ViD's review"
E=.vid/results/step-$AC_N-$b12.txt; grep -q '^report grade none' "$E" && grep -q '^report sort none' "$E" || { cp "$E" "$T/out"; fail "a grade or a sort of the team's was read"; }
# the review made at A, read at B
ac_grade "$AC_C"; ac_round accept "$AC_N"; grep -qx "accepted #$AC_N $b12" "$T/out" && grep -q "^report grade grade-step-$AC_N-$(printf %s "$AC_C" | cut -c1-12)-1 read" "$E" || fail "the ticket's one review, made at A, was not read at B"
exit 0
