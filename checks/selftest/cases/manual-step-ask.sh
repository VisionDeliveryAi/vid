#!/bin/sh
# Purpose: selftest case — the ask at a ticket's end (GM-4 E1, GM M8: only a ticket is decided, at a commit of main). On GitHub manual's
# toy and the fake gh (fixtures/accept.sh): an ask on the step ticket at a commit off main's first-parent line is answered `ticket: not
# yet` with `not on main — <commit>`, on the ticket, and no row moves; an ask at a commit of main is a `decide` line of round.sh step,
# which decides nothing and posts nothing; round.sh accept then reads it with its red run, head report, grade and sort under the
# ticket's ids, into .vid/results/step-<n>-<commit12>.txt, and posts the decision once, on the ticket. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/accept.sh"
fail() { echo "manual-step-ask: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
ac_project "$T/p" || fail 'the toy could not be made'
# an ask off main: not yet, not on main, no row moved
ac_ask "$AC_OFF"; ac_round step; [ "$RC" = 0 ] || fail "round.sh step exited $RC"
grep -qx "decide #$AC_N $AC_OFF" "$T/out" || fail 'the ask off main is no decide line'
n0=$(ac_comments); ac_round accept "$AC_N" "$AC_OFF"; [ "$RC" = 0 ] || fail "accept exited $RC"
[ "$(ac_comments)" = $((n0 + 1)) ] || fail 'the ask off main was not answered once on the ticket'
ac_last | grep -qx 'ticket: not yet' && ac_last | grep -qx "not on main — $AC_OFF" || { ac_last > "$T/out"; fail 'the answer off main is not `not yet` with `not on main`'; }
[ ! -s .vid/decide/state ] || fail 'an ask off main moved a row'
# an ask at a commit of main: step decides nothing; accept reads every report under the ticket's ids and posts once
ac_good "$AC_C"; S=sort-step-$AC_N-$(printf %s "$AC_C" | cut -c1-12)-1; rr_put "$S" sorted.txt "$(printf 'by: SR\ncommit: %s\nROW-001 note it — a note — ROW-001 kept' "$AC_C")"; ac_send "$S"
ac_ask "$AC_C"; n0=$(ac_comments); ac_round step; [ "$RC" = 0 ] || fail "round.sh step exited $RC"
grep -qx "decide #$AC_N $AC_C" "$T/out" || fail 'the ask at main is no decide line'
! grep -q '^decided' "$T/out" && [ "$(ac_comments)" = "$n0" ] || fail 'round.sh step decided or posted in GitHub manual'
ac_round accept "$AC_N"; [ "$RC" = 0 ] || fail "accept exited $RC"; h=$(printf %s "$AC_C" | cut -c1-12); E=.vid/results/step-$AC_N-$h.txt
[ -f "$E" ] || fail "no evidence file $E"
for l in "report T2 red-$AC_N-1 read" "report head step-$AC_N-$h-1 read" "report grade grade-step-$AC_N-$h-1 read" "report sort $S read"; do grep -q "^$l" "$E" || { cp "$E" "$T/out"; fail "the read lacks: $l"; }; done
[ "$(ac_comments)" = $((n0 + 1)) ] || fail 'the decision was not posted once on the ticket'
[ "$(ac_last | head -n 1)" = "vid: decision $AC_C" ] && ac_last | grep -qx 'ticket: accepted' || { ac_last > "$T/out"; fail 'the posted decision is not the ticket accepted at the commit'; }
ac_round accept "$AC_N"; [ "$(ac_comments)" = $((n0 + 1)) ] || fail 'an accepted ticket called again posted again'
exit 0
