#!/bin/sh
# Purpose: selftest case — a ticket's grade is read at its first asked commit alone (GM-4 E1, as a pull request's at its first asked
# head), on GitHub manual's toy and the fake gh (fixtures/accept.sh). The first asked commit is the oldest `vid: decide` on the ticket
# whose commit is on main's first-parent line: an ask off main, answered `not on main`, decides nothing and is skipped. Ticket one: an
# ask off main, then an ask at A, its grade at A: the decision at A reads that grade. Ticket two: the team asks at A, then at B, before
# any decision, and sends a grade at B alone: the decision at B reads no grade report, and so does the next. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/accept.sh"
fail() { echo "manual-grade-first: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
ac_project "$T/p" || fail 'the toy could not be made'
# ticket one: an ask off main first, then at A with its grade
ac_ask "$AC_OFF"; ac_round accept "$AC_N" "$AC_OFF"; ac_last | grep -qx "not on main — $AC_OFF" || { ac_last > "$T/out"; fail 'the ask off main was not answered not on main'; }
ac_red; ac_head "$AC_C"; ac_grade "$AC_C"; ac_ask "$AC_C"; ac_round accept "$AC_N"; [ "$RC" = 0 ] || fail "accept at A exited $RC"
grep -q "^report grade grade-step-$AC_N-$(printf %s "$AC_C" | cut -c1-12)-1 read" ".vid/results/step-$AC_N-$(printf %s "$AC_C" | cut -c1-12).txt" || { cp ".vid/results/step-$AC_N-$(printf %s "$AC_C" | cut -c1-12).txt" "$T/out"; fail 'after an ask off main, the first ask on main did not have its grade read'; }
# ticket two: asks at A and B before any decision, a grade at B alone
N2=$(gh_issue 'Step S03'); { mn_ticket "$N2" S03 step ROW-001 ROW-012; printf '\n## Engines\n\n- primary: alpha\n'; } > ".vid/tw/out/issue-$N2.md"
printf 'published %s kind=step step=S03 rows=ROW-001,ROW-012 at=2026-11-18T09:00:00Z\n' "$N2" >> .vid/tw/log; AC_N=$N2
ac_red; ac_head "$AC_C"; ac_ask "$AC_C"
tk_dev 'B'; B=$(git -C "$T/dev" rev-parse HEAD); ac_head "$B"; ac_grade "$B"; ac_ask "$B"
ac_round accept "$AC_N"; [ "$RC" = 0 ] || fail "accept exited $RC"; grep -q "^decided #$AC_N $(printf %s "$B" | cut -c1-12) " "$T/out" || fail 'the newest ask, at B, was not decided'
E=.vid/results/step-$AC_N-$(printf %s "$B" | cut -c1-12).txt; grep -q '^report grade none' "$E" && ! grep -q '^report grade grade-step-' "$E" || { cp "$E" "$T/out"; fail 'the grade at B, a later commit than the first asked, was read'; }
ac_last | grep -qx 'ticket: not yet' || { ac_last > "$T/out"; fail "the ticket was accepted on a later commit's grade"; }
ac_ask "$B"; ac_round accept "$AC_N"; grep -q '^report grade none' "$E" || { cp "$E" "$T/out"; fail 'asked again at B, its grade was read'; }
exit 0
